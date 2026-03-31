import 'package:flutter/material.dart';
import '../../models/medicine.dart';

class MedicineEditorScreen extends StatefulWidget {
  final Medicine medicine;

  const MedicineEditorScreen({super.key, required this.medicine});

  @override
  State<MedicineEditorScreen> createState() => _MedicineEditorScreenState();
}

class _MedicineEditorScreenState extends State<MedicineEditorScreen> {
  late TextEditingController name;
  late TextEditingController duration;
  late TextEditingController frequency;
  late TextEditingController timing;
  late TextEditingController food;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.medicine.name);
    duration = TextEditingController(text: widget.medicine.duration);
    frequency = TextEditingController(text: widget.medicine.frequency);
    timing = TextEditingController(text: widget.medicine.timing);
    food = TextEditingController(text: widget.medicine.foodRelation);
  }

  Widget field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _save() {
    final updated = Medicine(
      name: name.text.trim(),
      duration: duration.text.trim(),
      frequency: frequency.text.trim(),
      timing: timing.text.trim(),
      foodRelation: food.text.trim(),
    );

    Navigator.pop(context, updated);
  }

  @override
  void dispose() {
    name.dispose();
    duration.dispose();
    frequency.dispose();
    timing.dispose();
    food.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Medicine")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            field("Medicine Name", name),
            field("Duration", duration),
            field("Frequency", frequency),
            field("Timing", timing),
            field("Food Relation", food),
            const Spacer(),
            ElevatedButton(onPressed: _save, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}
