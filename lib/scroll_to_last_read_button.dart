import 'package:flutter/material.dart';

class ScrollToLastReadButton extends StatelessWidget {
  final VoidCallback onTap;

  const ScrollToLastReadButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.12),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_arrow_up_rounded,
                size: 20, color: Color(0xFF2196F3)),
            SizedBox(width: 4),
            Text(
              '上次阅读位置',
              style: TextStyle(fontSize: 13, color: Color(0xFF2196F3)),
            ),
          ],
        ),
      ),
    );
  }
}
