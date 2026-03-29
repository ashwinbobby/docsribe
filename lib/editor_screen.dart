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

/// Holds the four controllers for one prescription card.
class _PrescriptionControllers {
  final TextEditingController medicine;
  final TextEditingController dose;
  final TextEditingController timing;
  final TextEditingController duration;

  _PrescriptionControllers({
    required String medicine,
    required String dose,
    required String timing,
    required String duration,
  })  : medicine = TextEditingController(text: medicine),
        dose = TextEditingController(text: dose),
        timing = TextEditingController(text: timing),
        duration = TextEditingController(text: duration);

  Prescription toPrescription() => Prescription(
        medicine: medicine.text.trim(),
        dose: dose.text.trim(),
        timing: timing.text.trim(),
        duration: duration.text.trim(),
      );

  void dispose() {
    medicine.dispose();
    dose.dispose();
    timing.dispose();
    duration.dispose();
  }
}

class _EditorScreenState extends State<EditorScreen> {
  late final List<_PrescriptionControllers> _controllers;

  @override
  void initState() {
    super.initState();
    // Create controllers ONCE in initState — not inside build/itemBuilder
    _controllers = widget.prescriptions
        .map((p) => _PrescriptionControllers(
              medicine: p.medicine,
              dose: p.dose,
              timing: p.timing,
              duration: p.duration,
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(String label, TextEditingController c, {IconData? icon}) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  void _confirmAll() {
    // Collect updated prescriptions and return to caller
    final updated = _controllers.map((c) => c.toPrescription()).toList();
    Navigator.pop(context, updated);
  }

  void _removeCard(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Prescription'),
        actions: [
          TextButton.icon(
            onPressed: _controllers.isEmpty ? null : _confirmAll,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _controllers.isEmpty
          ? const Center(
              child: Text(
                'No prescriptions to confirm.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _controllers.length,
              itemBuilder: (context, index) {
                final c = _controllers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Prescription ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              tooltip: 'Remove',
                              onPressed: () => _removeCard(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _field('Medicine', c.medicine, icon: Icons.medication),
                        const SizedBox(height: 8),
                        _field('Dose', c.dose, icon: Icons.scale),
                        const SizedBox(height: 8),
                        _field('Timing', c.timing, icon: Icons.access_time),
                        const SizedBox(height: 8),
                        _field('Duration', c.duration, icon: Icons.calendar_today),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _controllers.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _confirmAll,
              label: const Text('Confirm All'),
              icon: const Icon(Icons.check),
            ),
    );
  }
}
