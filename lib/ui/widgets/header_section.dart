import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final String language;

  const HeaderSection({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "DocScribe",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          language,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Voice Prescription Assistant",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}