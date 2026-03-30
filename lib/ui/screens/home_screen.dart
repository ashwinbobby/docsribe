import 'package:flutter/material.dart';
import '../../speech_service.dart';
import '../../editor_screen.dart';
import '../widgets/status_card.dart';
import '../widgets/mic_button.dart';
import '../widgets/header_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _speech = SpeechService();

  bool _listening = false;
  bool _loading = false;

  String _text = 'Tap mic to start';
  String _liveTranscription = '';
  String _language = 'Detecting...';

  @override
  void initState() {
    super.initState();
    _detectLanguage();
  }

  Future<void> _detectLanguage() async {
    final languages = await _speech.getAvailableLanguages();
    if (mounted) {
      setState(() {
        _language = languages.contains('en_IN')
            ? '🇮🇳 English (en_IN)'
            : '🇺🇸 English';
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_listening) {
      final text = await _speech.stopListening();

      setState(() {
        _listening = false;
        _loading = true;
        _liveTranscription = '';
      });

      await _process(text ?? '');
    } else {
      setState(() {
        _listening = true;
        _text = "Listening...";
      });

      await _speech.startListening(
        onPartialResult: (t) => setState(() => _liveTranscription = t),
        onFinalResult: (t) async {
          setState(() {
            _listening = false;
            _loading = true;
          });

          await _process(t);
        },
      );
    }
  }

  Future<void> _process(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _loading = false;
        _text = "No speech detected";
      });
      return;
    }

    setState(() {
      _loading = false;
      _text = 'You said:\n$text';
    });

    final edited = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(text: text),
      ),
    );

    if (edited != null) {
      setState(() => _text = edited);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HeaderSection(language: _language),

            StatusCard(
              listening: _listening,
              loading: _loading,
              text: _text,
              liveText: _liveTranscription,
            ),

            Column(
              children: [
                MicButton(
                  listening: _listening,
                  onTap: _toggleRecording,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Speak clearly. Auto stops after silence.",
                  style: TextStyle(color: Colors.grey),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}