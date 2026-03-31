import 'package:flutter/material.dart';
import '../../speech_service.dart';
import '../../text_normalizer.dart';
import '../../services/llm_service.dart';
import '../../models/medicine.dart';
import '../widgets/medicine_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _speech = SpeechService();
  final _llm = LlmService();

  bool _listening = false;
  bool _loading = false;

  String _liveTranscription = '';
  String _fullText = '';
  String _language = 'Detecting...';

  List<Medicine> _medicines = [];

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

      await _process(text ?? _fullText);
      _fullText = '';
    } else {
      setState(() {
        _listening = true;
        _medicines = [];
        _liveTranscription = '';
        _fullText = '';
      });

      await _speech.startListening(
        onPartialResult: (t) {
          if (mounted) {
            setState(() {
              _liveTranscription = (_fullText + " " + t).trim();
            });
          }
        },
        onFinalResult: (t) {
          _fullText = (_fullText + " " + t).trim();
        },
      );
    }
  }

  Future<void> _process(String text) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final normalized = TextNormalizer.normalize(trimmed);

    final meds = await _llm.extractMedicines(normalized);

    setState(() => _loading = false);

    if (meds == null || meds.isEmpty) return;

    setState(() {
      _medicines = meds;
    });
  }

  Widget _buildListeningView() {
    return Center(
      child: Text(
        _liveTranscription.isEmpty
            ? "Listening... speak now"
            : _liveTranscription,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMedicineList() {
    return ListView(
      children: _medicines
          .map((m) => MedicineCard(
                med: m,
                onUpdated: (_) {},
              ))
          .toList(),
    );
  }

  Widget _buildIdleView() {
    return const Center(
      child: Text("Tap mic to start"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Text(_language),

            const SizedBox(height: 20),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _listening
                      ? _buildListeningView()
                      : _medicines.isNotEmpty
                          ? _buildMedicineList()
                          : _buildIdleView(),
            ),

            GestureDetector(
              onTap: _toggleRecording,
              child: CircleAvatar(
                radius: 40,
                backgroundColor:
                    _listening ? Colors.red : Colors.blue,
                child: Icon(
                  _listening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}