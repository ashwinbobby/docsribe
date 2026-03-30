import 'package:flutter/material.dart';

class EditorScreen extends StatefulWidget {
  final String text;

  const EditorScreen({
    super.key,
    required this.text,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final updatedText = _controller.text.trim();
    Navigator.pop(context, updatedText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transcription'),
        actions: [
          TextButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: null,
          decoration: InputDecoration(
            labelText: 'Transcribed Text',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _confirm,
        label: const Text('Confirm'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}