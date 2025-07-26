class Message {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderPicture;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final bool isMine;  // Pour faciliter l'UI
  String? conversationId;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPicture,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.isMine,
    this.conversationId,  
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


// class MessageModel {
//   final int id;
//   final String content;
//   final int senderId;
//   final String senderName;
//   final DateTime createdAt;
//   final bool isRead;
//   String? conversationId; // Ajouté pour les WebSockets

//   MessageModel({
//     required this.id,
//     required this.content,
//     required this.senderId,
//     required this.senderName,
//     required this.createdAt,
//     required this.isRead,
//     this.conversationId,
//   });

//   factory MessageModel.fromJson(Map<String, dynamic> json) {
//     return MessageModel(
//       id: json['id'],
//       content: json['content'],
//       senderId: json['sender_id'],
//       senderName: json['sender_name'],
//       createdAt: DateTime.parse(json['created_at']),
//       isRead: json['is_read'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'content': content,
//       'sender_id': senderId,
//       'sender_name': senderName,
//       'created_at': createdAt.toIso8601String(),
//       'is_read': isRead,
//     };
//   }
// }