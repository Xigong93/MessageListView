class Message {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final bool isMe;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.isMe,
    required this.timestamp,
  });
}
