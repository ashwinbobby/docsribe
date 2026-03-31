import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/medicine.dart';
import '../widgets/medicine_card.dart';
import 'prescription_screen.dart';

class PrescriptionEditorScreen extends StatefulWidget {
  final List<Medicine> initialMedicines;

  const PrescriptionEditorScreen({super.key, required this.initialMedicines});

  @override
  State<PrescriptionEditorScreen> createState() =>
      _PrescriptionEditorScreenState();
}

class _PrescriptionEditorScreenState extends State<PrescriptionEditorScreen> {
  late List<Medicine> _medicines;
  late final TextEditingController _patientController;
  late final TextEditingController _doctorController;
  late final String _prescriptionId;
  late final DateTime _issuedAt;

  @override
  void initState() {
    super.initState();
    _medicines = List<Medicine>.from(widget.initialMedicines);
    _patientController = TextEditingController(text: 'Rohan Verma');
    _doctorController = TextEditingController(text: 'Dr. A.K. Sharma');
    _issuedAt = DateTime.now();
    final random =
        Random(_issuedAt.millisecondsSinceEpoch).nextInt(9000) + 1000;
    _prescriptionId = 'RX-${DateFormat('yyyyMMdd').format(_issuedAt)}-$random';
  }

  @override
  void dispose() {
    _patientController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  void _updateMedicine(Medicine oldMed, Medicine updatedMed) {
    setState(() {
      final index = _medicines.indexOf(oldMed);
      if (index != -1) {
        _medicines[index] = updatedMed;
      }
    });
  }

  Future<void> _proceedToPrescription() async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medicines available to proceed.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrescriptionScreen(
          medicines: _medicines,
          patientName: _patientController.text.trim(),
          doctorName: _doctorController.text.trim(),
          prescriptionId: _prescriptionId,
          issuedAt: _issuedAt,
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Review Medicines')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tap any medicine to edit before finalizing.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _textField('Patient Name', _patientController),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _textField('Doctor Name', _doctorController)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prescription ID: $_prescriptionId',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _medicines.isEmpty
                    ? const Center(child: Text('No medicines extracted yet.'))
                    : ListView(
                        children: _medicines
                            .map(
                              (m) => MedicineCard(
                                med: m,
                                onUpdated: (updated) =>
                                    _updateMedicine(m, updated),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _proceedToPrescription,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Proceed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
