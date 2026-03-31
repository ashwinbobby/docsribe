import 'package:flutter/material.dart';

import '../../speech_service.dart';
import '../../services/llm_service.dart';
import '../../text_normalizer.dart';
import 'prescription_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _speech = SpeechService();
  final _llm = LlmService();

  bool _listening = false;
  bool _sending = false;

  String _liveTranscription = '';
  String _fullText = '';
  String _capturedText = '';

  @override
  void initState() {
    super.initState();
    // Trigger STT initialization early for first-use responsiveness.
    _speech.getAvailableLanguages();
  }

  Future<void> _toggleRecording() async {
    if (_listening) {
      final text = await _speech.stopListening();

      setState(() {
        _listening = false;
        _capturedText = (text ?? _fullText).trim();
      });

      _fullText = '';
    } else {
      setState(() {
        _listening = true;
        _liveTranscription = '';
        _fullText = '';
        _capturedText = '';
      });

      await _speech.startListening(
        onPartialResult: (t) {
          if (mounted) {
            setState(() {
              _liveTranscription = '$_fullText $t'.trim();
            });
          }
        },
        onFinalResult: (t) {
          _fullText = '$_fullText $t'.trim();
        },
      );
    }
  }

  Future<void> _sendTranscription() async {
    final trimmed = _capturedText.trim();
    if (trimmed.isEmpty || _sending) return;

    setState(() => _sending = true);

    final normalized = TextNormalizer.normalize(trimmed);
    final meds = await _llm.extractMedicines(normalized);

    if (!mounted) {
      return;
    }

    setState(() => _sending = false);

    if (meds == null || meds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medicines found from transcription.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrescriptionEditorScreen(initialMedicines: meds),
      ),
    );
  }

  Widget _buildListeningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Listening',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              _liveTranscription.isEmpty
                  ? 'Start speaking. Your transcript will appear here.'
                  : _liveTranscription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoppedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Text(
          _capturedText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            height: 1.25,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
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
              const Row(
                children: [
                  Text(
                    'DocScribe',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _listening
                      ? _buildListeningView()
                      : _capturedText.isNotEmpty
                      ? _buildStoppedView()
                      : _buildIdleView(),
                ),
              ),
              if (_sending) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                      SizedBox(width: 10),
                      Text('Sending to backend...'),
                    ],
                  ),
                ),
              ],
              if (!_listening && _capturedText.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _sendTranscription,
                    icon: const Icon(Icons.send_rounded),
                    label: Text(_sending ? 'Sending...' : 'Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
                        color:
                            (_listening ? Colors.red : const Color(0xFF2563EB))
                                .withValues(alpha: 0.4),
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
                _listening
                    ? 'Tap to stop recording'
                    : _capturedText.isNotEmpty
                    ? 'Tap mic to record again'
                    : 'Tap to start recording',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
