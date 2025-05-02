class Conversation {
  final int id;
  final Person otherPerson;
  final int currentUserId;
  final LastMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final bool isOnline;

  Conversation({
    required this.id,
    required this.otherPerson,
    required this.currentUserId,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    this.isOnline = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, int currentUserId) {
    // Déterminer qui est l'autre personne
    final Map<String, dynamic> otherPersonData;
    
    if (json['client']['id'] == currentUserId) {
      // L'utilisateur actuel est le client, donc l'autre personne est le prestataire
      otherPersonData = {
        'id': json['provider']['user_id'],
        'username': json['provider']['username'] ?? '',
        'firstName': json['provider']['first_name'] ?? '',
        'lastName': json['provider']['last_name'] ?? '',
        'profilePicture': json['provider']['profile_picture'],
        'companyName': json['provider']['company_name'] ?? '',
      };
    } else {
      // L'utilisateur actuel est le prestataire, donc l'autre personne est le client
      otherPersonData = {
        'id': json['client']['id'],
        'username': json['client']['username'] ?? '',
        'firstName': json['client']['first_name'] ?? '',
        'lastName': json['client']['last_name'] ?? '',
        'profilePicture': json['client']['profile_picture'],
      };
    }
    
    return Conversation(
      id: json['id'],
      otherPerson: Person.fromJson(otherPersonData),
      currentUserId: currentUserId,
      lastMessage: json['last_message'] != null 
          ? LastMessage.fromJson(json['last_message']) 
          : null,
      unreadCount: json['unread_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      isOnline: json['is_online'] ?? false,
    );
  }
}

class Person {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final String? companyName;

  Person({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    this.companyName,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      username: json['username'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePicture: json['profilePicture'],
      companyName: json['companyName'],
    );
  }
  
  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : username;
  }
  
  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    } else if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }
    return '';
  }
}

class LastMessage {
  final String content;
  final int senderId;
  final DateTime createdAt;
  final bool isRead;

  LastMessage({
    required this.content,
    required this.senderId,
    required this.createdAt,
    required this.isRead,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'] ?? '',
      senderId: json['sender_id'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }
}