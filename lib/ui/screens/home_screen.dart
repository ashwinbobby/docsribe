import 'package:flutter/material.dart';
import '../../speech_service.dart';
import '../../text_normalizer.dart';
import '../../services/llm_service.dart';
import 'prescription_screen.dart';

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
        _liveTranscription = '';
        _fullText = '';
      });

      await _speech.startListening(
        onPartialResult: (t) {
          if (mounted) {
            setState(() {
              _liveTranscription = (_fullText + ' ' + t).trim();
            });
          }
        },
        onFinalResult: (t) {
          _fullText = (_fullText + ' ' + t).trim();
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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PrescriptionScreen(medicines: meds)),
    );
  }

  Widget _buildListeningView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🎤 Listening...',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 12),
          Text(
            _liveTranscription.isEmpty ? 'Start speaking...' : _liveTranscription,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIdleView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Tap the microphone to start recording',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DocScribe',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _language,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _listening
                          ? _buildListeningView()
                          : _buildIdleView(),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _listening ? 90 : 80,
                  height: _listening ? 90 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _listening ? Colors.red : const Color(0xFF2563EB),
                    boxShadow: [
                      BoxShadow(
                        color: (_listening ? Colors.red : const Color(0xFF2563EB))
                            .withOpacity(0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    _listening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _listening ? 'Tap to stop recording' : 'Tap to start recording',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
