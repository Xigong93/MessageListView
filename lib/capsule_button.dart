import 'package:flutter/material.dart';

class CapsuleButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onTap;

  const CapsuleButton({
    super.key,
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF2196F3) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: enabled ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}
