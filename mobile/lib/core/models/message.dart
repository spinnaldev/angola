class Message {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderPicture;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final bool isMine;  // Pour faciliter l'UI

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPicture,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.isMine,
  });

  factory Message.fromJson(Map<String, dynamic> json, int currentUserId) {
    final senderId = json['sender_id'] ?? 0;
    return Message(
      id: json['id'],
      senderId: senderId,
      senderName: json['sender_name'] ?? '',
      senderPicture: json['sender_picture'],
      content: json['content'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      isMine: senderId == currentUserId,
    );
  }
}