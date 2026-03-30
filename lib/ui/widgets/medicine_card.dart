import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../screens/medicine_editor_screen.dart';

class MedicineCard extends StatelessWidget {
  final Medicine med;
  final Function(Medicine) onUpdated;

  const MedicineCard({
    super.key,
    required this.med,
    required this.onUpdated,
  });

  Widget row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineEditorScreen(medicine: med),
          ),
        );

        if (updated != null && updated is Medicine) {
          onUpdated(updated);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.05),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine name
            Text(
              med.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 8),

            row("Duration", med.duration),
            row("Frequency", med.frequency),
            row("Timing", med.timing),
            row("Food", med.foodRelation),
          ],
        ),
      ),
    );
  }
}