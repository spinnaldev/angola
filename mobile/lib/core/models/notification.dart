class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String notificationType;
  final int? relatedObjectId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    this.relatedObjectId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      notificationType: json['notification_type'],
      relatedObjectId: json['related_object_id'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'notification_type': notificationType,
      'related_object_id': relatedObjectId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer une copie avec des modifications
  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? notificationType,
    int? relatedObjectId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      relatedObjectId: relatedObjectId ?? this.relatedObjectId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Méthode pour obtenir l'icône en fonction du type
  String getIcon() {
    switch (notificationType) {
      case 'message':
        return 'message';
      case 'quote_request':
      case 'quote_accepted':
      case 'quote_rejected':
      case 'quote_completed':
        return 'receipt';
      case 'new_offer':
      case 'offer_accepted':
      case 'offer_rejected':
        return 'work';
      case 'dispute':
        return 'warning';
      case 'review':
        return 'star';
      case 'favorite':
        return 'favorite';
      case 'system':
        return 'info';
      default:
        return 'notifications';
    }
  }

  // Méthode pour obtenir la couleur en fonction du type
  String getColor() {
    switch (notificationType) {
      case 'quote_accepted':
      case 'offer_accepted':
        return 'green';
      case 'quote_rejected':
      case 'offer_rejected':
        return 'red';
      case 'quote_completed':
        return 'blue';
      case 'dispute':
        return 'orange';
      case 'new_offer':
      case 'quote_request':
        return 'purple';
      case 'message':
        return 'blue';
      case 'review':
        return 'amber';
      case 'favorite':
        return 'pink';
      case 'system':
        return 'gray';
      default:
        return 'gray';
    }
  }

  // Méthode pour obtenir une description du type de notification
  String getTypeDescription() {
    switch (notificationType) {
      case 'message':
        return 'Message';
      case 'quote_request':
        return 'Demande de devis';
      case 'quote_accepted':
        return 'Devis accepté';
      case 'quote_rejected':
        return 'Devis rejeté';
      case 'quote_completed':
        return 'Prestation terminée';
      case 'new_offer':
        return 'Nouvelle offre';
      case 'offer_accepted':
        return 'Offre acceptée';
      case 'offer_rejected':
        return 'Offre rejetée';
      case 'dispute':
        return 'Litige';
      case 'review':
        return 'Avis';
      case 'favorite':
        return 'Favori';
      case 'system':
        return 'Système';
      default:
        return 'Notification';
    }
  }

  @override
  String toString() {
    return 'NotificationModel{id: $id, title: $title, type: $notificationType, isRead: $isRead}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}