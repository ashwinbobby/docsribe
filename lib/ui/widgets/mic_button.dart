import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  final bool listening;
  final VoidCallback onTap;

  const MicButton({
    super.key,
    required this.listening,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: listening ? 110 : 90,
        height: listening ? 110 : 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: listening ? Colors.red : Colors.blue,
          boxShadow: [
            BoxShadow(
              color: (listening ? Colors.red : Colors.blue).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Icon(
          listening ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}