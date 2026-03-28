import 'package:flutter/material.dart';
import 'speech_service.dart';
import 'llm_service.dart';
import 'editor_screen.dart';
import 'awaken_service.dart';
import 'ui/app_theme.dart';
import 'ui/widgets/status_card.dart';

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

  bool _modelReady = false;
  bool _wakingUp = false;

  String _text = 'Waking up AI model…';

  @override
  void initState() {
    super.initState();
    _wakeModel();
  }

  Future<void> _wakeModel() async {
    setState(() {
      _wakingUp = true;
      _text = 'Waking up AI model…';
    });

    final ok = await AwakenService.wakeModel();

    if (!mounted) return;

    setState(() {
      _wakingUp = false;
      _modelReady = ok;
      _text = ok
          ? 'AI model ready. Tap mic to start.'
          : 'AI model unavailable. Retry.';
    });

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI model is ready'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleRecording() async {
    // 🔒 HARD GATE
    if (!_modelReady) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please wait for AI model')));
      return;
    }

    if (_listening) {
      // STOP
      final text = await _speech.stopListening();

      setState(() => _listening = false);

      if (text == null || text.isEmpty) {
        setState(() => _text = 'No speech detected');
        return;
      }

      setState(() {
        _loading = true;
        _text = 'Processing…';
      });

      final prescriptions = await _llm.extract(text);

      setState(() => _loading = false);

      if (prescriptions == null || prescriptions.isEmpty) {
        setState(() => _text = 'No prescription found');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditorScreen(prescriptions: prescriptions),
        ),
      );
    } else {
      // START
      await _speech.startListening();
      setState(() {
        _listening = true;
        _text = 'Listening…';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DocScribe')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // 🔥 important
            children: [
              const Text(
                "DocScribe",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "AI-powered prescription capture",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              if (_loading)
                const CircularProgressIndicator()
              else
                StatusCard(
                  ready: _modelReady,
                  text: _text,
                  waking: _wakingUp,
                  onRetry: _wakeModel,
                ),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: _modelReady ? _toggleRecording : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !_modelReady
                        ? Colors.grey
                        : _listening
                        ? Colors.red
                        : Colors.blue,
                  ),
                  child: Icon(
                    _listening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
