import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/medicine.dart';

class PrescriptionScreen extends StatelessWidget {
  final List<Medicine> medicines;

  const PrescriptionScreen({super.key, required this.medicines});

  String get currentDate => DateFormat('dd MMM yyyy').format(DateTime.now());

  String get currentTime => DateFormat('hh:mm a').format(DateTime.now());

  Future<void> _downloadPdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PRESCRIPTION',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Patient: Rohan Verma'),
              pw.Text('Doctor: Dr. A.K. Sharma'),
              pw.Text('Date: $currentDate'),
              pw.Text('Time: $currentTime'),
              pw.SizedBox(height: 20),
              ...medicines.map(
                (m) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    '${m.name} | ${m.frequency} | ${m.timing} | ${m.foodRelation} | ${m.duration}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _infoRow(String title, String value) {
    return Row(
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _medicineTile(Medicine m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          _infoRow('Dosage', m.frequency),
          _infoRow('Timing', m.timing),
          _infoRow('Food', m.foodRelation),
          _infoRow('Duration', m.duration),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Prescription'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit coming soon')),
                );
              } else if (value == 'download') {
                _downloadPdf(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Modify Details')),
              const PopupMenuItem(value: 'download', child: Text('Download PDF')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow('Patient', 'Rohan Verma'),
                  _infoRow('Doctor', 'Dr. A.K. Sharma'),
                  _infoRow('Prescription ID', 'PX-001'),
                  _infoRow('Date', currentDate),
                  _infoRow('Time', currentTime),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(children: medicines.map(_medicineTile).toList()),
            ),
          ],
        ),
      ),
    );
  }
}
