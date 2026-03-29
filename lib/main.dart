import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'speech_service.dart';
import 'llm_service.dart';
import 'editor_screen.dart';
import 'text_normalizer.dart';
import 'ui/app_theme.dart';

final _llm = LlmService();

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
  bool _processingSpeech = false;
  bool _testingBackend = false;
  bool _backendReachable = false;

  String _text = 'Tap mic to start';
  String _liveTranscription = '';
  String _language = 'Detecting...';
  String _backendStatus = 'Checking backend...';
  String _lastBackendUsed = 'N/A';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _detectLanguage();
    _checkBackend(showSnackBar: false);
  }

  Future<void> _checkBackend({required bool showSnackBar}) async {
    if (_testingBackend) return;

    if (mounted) {
      setState(() => _testingBackend = true);
    }

    final result = await _llm.pingPreferredBackend();
    if (!mounted) return;

    setState(() {
      _testingBackend = false;
      _backendReachable = result.reachable;
      _backendStatus = result.message;
    });

    if (!showSnackBar) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.reachable ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _processTranscription(String text) async {
    if (_processingSpeech) return;
    _processingSpeech = true;

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _text = '⚠️ No speech detected. Try again.';
        });
      }
      _processingSpeech = false;
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _text = 'Processing: "$trimmed"...';
      });
    }

    final normalized = TextNormalizer.normalize(trimmed);
    final prescriptions = await _llm.extract(normalized);

    if (!mounted) {
      _processingSpeech = false;
      return;
    }

    setState(() {
      _loading = false;
      _lastBackendUsed = _llm.lastBackendLabel;
    });

    if (prescriptions == null || prescriptions.isEmpty) {
      setState(() => _text = '❌ No prescription found. Try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not extract. Try again.')),
      );
      _processingSpeech = false;
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(prescriptions: prescriptions),
      ),
    );
    _processingSpeech = false;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_listening) {
      // STOP
      final text = await _speech.stopListening();

      setState(() {
        _listening = false;
        _liveTranscription = '';
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
          if (!mounted || !_listening || _loading) return;
          setState(() {
            _listening = false;
            _liveTranscription = '';
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
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
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
                  "AI-powered prescription capture",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _backendReachable
                        ? Colors.green.withAlpha(24)
                        : Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _backendReachable ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    'LLM: $_backendStatus',
                    style: TextStyle(
                      color: _backendReachable
                          ? Colors.green.shade800
                          : Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last extraction backend: $_lastBackendUsed',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _testingBackend
                      ? null
                      : () => _checkBackend(showSnackBar: true),
                  icon: _testingBackend
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: Text(
                    _testingBackend
                        ? 'Testing LLM connection...'
                        : 'Test LLM Connection',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live transcription OR status
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
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
                style: const TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 24),

            // Mic Button
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening ? Colors.red : Colors.blue,
                  boxShadow: _listening
                      ? [
                          BoxShadow(
                            color: Colors.red.withAlpha(100),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _listening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _listening ? 'Stop' : 'Start',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '💡 Tip: Speak clearly. Recording auto-stops after 2 seconds of silence.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}