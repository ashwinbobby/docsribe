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
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Prescription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                field('Medicine', medicine),
                const SizedBox(height: 12),
                field('Dose', dose),
                const SizedBox(height: 12),
                field('Timing', timing),
                const SizedBox(height: 12),
                field('Duration', duration),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Confirm Prescription'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
