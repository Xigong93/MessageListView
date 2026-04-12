enum MessageType { text, image, video, voice }

class Message {
  final int id;
  final String content;
  final MessageType type;

  const Message({
    required this.id,
    required this.content,
    this.type = MessageType.text,
  });
}
