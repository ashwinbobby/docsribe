import 'package:flutter/material.dart';
import 'speech_service.dart';
import 'llm_service.dart';
import 'editor_screen.dart';
import 'awaken_service.dart';

final _llm = LlmService();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for AI model'),
        ),
      );
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

      final prescription = await _llm.extract(text);

      setState(() => _loading = false);

      if (prescription == null) {
        setState(() => _text = 'Failed to extract prescription');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditorScreen(prescription: prescription),
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
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _modelReady
                        ? Icons.check_circle
                        : Icons.cloud_sync,
                    color:
                        _modelReady ? Colors.green : Colors.orange,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _text,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  if (!_modelReady && !_wakingUp)
                    TextButton(
                      onPressed: _wakeModel,
                      child: const Text('Retry AI wake-up'),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: !_modelReady
            ? Colors.grey
            : _listening
                ? Colors.red
                : Colors.blue,
        onPressed: _modelReady ? _toggleRecording : null,
        child: Icon(_listening ? Icons.stop : Icons.mic),
      ),
    );
  }
}
