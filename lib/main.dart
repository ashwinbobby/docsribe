import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'speech_service.dart';
import 'editor_screen.dart';
import 'ui/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _speech = SpeechService();

  bool _listening = false;
  bool _loading = false;

  String _text = 'Tap mic to start';
  String _liveTranscription = '';
  String _language = 'Detecting...';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _detectLanguage();
  }

  Future<void> _processTranscription(String text) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _loading = false;
        _text = '⚠️ No speech detected. Try again.';
      });
      return;
    }

    setState(() {
      _loading = false;
      _text = 'You said: "$trimmed"';
    });

    // Open editor screen
    final editedText = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(text: trimmed),
      ),
    );

    if (editedText != null && editedText is String) {
      setState(() {
        _text = 'Final Text:\n$editedText';
      });
    }
  }

  Future<void> _detectLanguage() async {
    final languages = await _speech.getAvailableLanguages();
    if (mounted) {
      setState(() {
        if (languages.contains('en_IN')) {
          _language = '🇮🇳 Indian English (en_IN)';
        } else if (languages.contains('en_US')) {
          _language = '🇺🇸 US English (en_US)';
        } else {
          _language =
              'English (${languages.isNotEmpty ? languages.first : 'default'})';
        }
      });
    }
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_listening) {
      // STOP
      final text = await _speech.stopListening();

      setState(() {
        _listening = false;
        _liveTranscription = '';
        _loading = true;
      });

      await _processTranscription(text ?? '');
    } else {
      // START
      setState(() {
        _listening = true;
        _text = '🎤 Listening...';
        _liveTranscription = '';
      });

      await _speech.startListening(
        onPartialResult: (text) {
          if (mounted) {
            setState(() => _liveTranscription = text);
          }
        },
        onFinalResult: (text) async {
          if (!mounted || !_listening) return;

          setState(() {
            _listening = false;
            _liveTranscription = '';
            _loading = true;
          });

          await _processTranscription(text);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DocScribe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const Text(
                  "DocScribe",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _language,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Speech to Text Demo",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_listening)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.blue.withAlpha(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎤 Live Transcription:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _liveTranscription.isEmpty
                          ? 'Listening... speak now'
                          : _liveTranscription,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (_loading)
              const CircularProgressIndicator()
            else
              Text(
                _text,
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 24),

            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening ? Colors.red : Colors.blue,
                ),
                child: Icon(
                  _listening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '💡 Tip: Speak clearly. Recording auto-stops after silence.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}