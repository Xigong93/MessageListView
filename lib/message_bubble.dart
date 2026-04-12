import 'package:flutter/material.dart';
import 'message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue[400],
            child: const Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.07),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (message.type) {
      case MessageType.text:
        return _buildText();
      case MessageType.image:
        return _buildImage();
      case MessageType.video:
        return _buildVideo();
      case MessageType.voice:
        return _buildVoice();
    }
  }

  Widget _buildText() {
    return Text(
      message.content,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '[图片] ${message.content}',
          style: const TextStyle(color: Colors.black87, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 40, color: Colors.green[300]),
              const SizedBox(height: 4),
              Text('图片占位', style: TextStyle(color: Colors.green[400], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '[视频] ${message.content}',
          style: const TextStyle(color: Colors.black87, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          width: 200,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill, size: 44, color: Colors.purple[300]),
              const SizedBox(height: 4),
              Text('视频占位', style: TextStyle(color: Colors.purple[400], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '[语音] ${message.content}',
          style: const TextStyle(color: Colors.black87, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          width: 160,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, size: 20, color: Colors.orange[400]),
              const SizedBox(width: 6),
              Text("0:12", style: TextStyle(color: Colors.orange[600], fontSize: 14)),
              const SizedBox(width: 8),
              Icon(Icons.graphic_eq, size: 20, color: Colors.orange[300]),
            ],
          ),
        ),
      ],
    );
  }
}
