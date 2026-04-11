import 'package:flutter/material.dart';

import 'message_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: const Text('IM 消息列表'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(context, '消息页面', null),
            const SizedBox(height: 16),
            _buildButton(context, '历史消息页面', 60),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, int? startMsgId) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MessageListPage(startMsgId: startMsgId),
            ),
          );
        },
        child: Text(title, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
