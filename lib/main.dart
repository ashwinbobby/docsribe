import 'package:flutter/material.dart';
import 'speech_service.dart';
import 'llm_service.dart';
import 'editor_screen.dart';

final _llm = LlmService();
bool _loading = false;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _speech = SpeechService();
  String _text = 'Press mic to start';
  bool _listening = false;

  Future<void> _toggleRecording() async {
    if (_listening) {
      // STOP
      // STOP
      final text = await _speech.stopListening();

      setState(() {
        _listening = false;
      });

      if (text == null || text.isEmpty) {
        setState(() => _text = 'No speech detected');
        return;
      }

      setState(() {
        _loading = true;
        _text = 'Processing...';
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
        _text = 'Listening...';
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
            : Text(
                _text,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _listening ? Colors.red : Colors.blue,
        onPressed: _toggleRecording,
        child: Icon(_listening ? Icons.stop : Icons.mic),
      ),
    );
  }
}
