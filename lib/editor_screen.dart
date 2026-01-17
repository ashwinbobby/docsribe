import 'package:flutter/material.dart';
import 'prescription_model.dart';

class EditorScreen extends StatefulWidget {
  final Prescription prescription;
  const EditorScreen({super.key, required this.prescription});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController medicine;
  late TextEditingController dose;
  late TextEditingController timing;
  late TextEditingController duration;

  @override
  void initState() {
    super.initState();
    medicine = TextEditingController(text: widget.prescription.medicine);
    dose = TextEditingController(text: widget.prescription.dose);
    timing = TextEditingController(text: widget.prescription.timing);
    duration = TextEditingController(text: widget.prescription.duration);
  }

  Widget field(String label, TextEditingController c) {
    return TextField(
      controller: c,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Prescription')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            field('Medicine', medicine),
            field('Dose', dose),
            field('Timing', timing),
            field('Duration', duration),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
