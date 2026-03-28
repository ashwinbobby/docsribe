import 'package:flutter/material.dart';
import 'prescription_model.dart';

class EditorScreen extends StatefulWidget {
  final List<Prescription> prescriptions;

  const EditorScreen({
    super.key,
    required this.prescriptions,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  Widget field(String label, TextEditingController c) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Prescription')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: widget.prescriptions.length,
          itemBuilder: (context, index) {
            final p = widget.prescriptions[index];

            final medicine = TextEditingController(text: p.medicine);
            final dose = TextEditingController(text: p.dose);
            final timing = TextEditingController(text: p.timing);
            final duration = TextEditingController(text: p.duration);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    field('Medicine', medicine),
                    const SizedBox(height: 8),
                    field('Dose', dose),
                    const SizedBox(height: 8),
                    field('Timing', timing),
                    const SizedBox(height: 8),
                    field('Duration', duration),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        label: const Text('Confirm All'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}