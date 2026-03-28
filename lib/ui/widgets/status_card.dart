import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final bool ready;
  final String text;
  final bool waking;
  final VoidCallback? onRetry;

  const StatusCard({
    super.key,
    required this.ready,
    required this.text,
    required this.waking,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              ready ? Icons.check_circle : Icons.cloud_sync,
              size: 48,
              color: ready ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (!ready && !waking)
              TextButton(
                onPressed: onRetry,
                child: const Text("Retry"),
              ),
          ],
        ),
      ),
    );
  }
}