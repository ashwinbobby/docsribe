import 'package:flutter/material.dart';
import 'live_transcription.dart';

class StatusCard extends StatelessWidget {
  final bool listening;
  final bool loading;
  final String text;
  final String liveText;

  const StatusCard({
    super.key,
    required this.listening,
    required this.loading,
    required this.text,
    required this.liveText,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (listening) {
      content = Column(
        children: [
          const Text(
            "🎤 Listening...",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          LiveTranscription(text: liveText),
        ],
      );
    } else if (loading) {
      content = Column(
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text("Processing on local AI..."),
        ],
      );
    } else {
      content = Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(0.05)),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: content,
      ),
    );
  }
}
