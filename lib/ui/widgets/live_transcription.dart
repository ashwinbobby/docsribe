import 'package:flutter/material.dart';

class LiveTranscription extends StatelessWidget {
  final String text;

  const LiveTranscription({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        text.isEmpty ? "Listening... speak now" : text,
        key: ValueKey(text),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          height: 1.4,
        ),
      ),
    );
  }
}