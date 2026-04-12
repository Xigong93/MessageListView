import 'package:flutter/material.dart';

class AnnouncementBanner extends StatelessWidget {
  final String text;

  const AnnouncementBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined,
                size: 16, color: Color(0xFFE65100)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
