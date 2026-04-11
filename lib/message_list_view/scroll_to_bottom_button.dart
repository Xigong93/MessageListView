import 'package:flutter/material.dart';

class ScrollToBottomButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const ScrollToBottomButton({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unreadCount > 0) ...[
              Text(
                '$unreadCount 条新消息',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF2196F3)),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: Color(0xFF2196F3)),
          ],
        ),
      ),
    );
  }
}
