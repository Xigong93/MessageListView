enum MessageType { text, image, video, voice }

class Message {
  final int id;
  final String content;
  final MessageType type;
  final DateTime sendTime;

  const Message({
    required this.id,
    required this.content,
    required this.sendTime,
    this.type = MessageType.text,
  });
}
