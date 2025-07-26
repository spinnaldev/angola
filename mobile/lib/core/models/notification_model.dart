class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String notificationType;
  final int? relatedObjectId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? extraData;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    this.relatedObjectId,
    required this.isRead,
    required this.createdAt,
    this.extraData,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? 'general',
      relatedObjectId: json['related_object_id'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      extraData: json['extra_data'] as Map<String, dynamic>?,
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
      'extra_data': extraData,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? notificationType,
    int? relatedObjectId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      relatedObjectId: relatedObjectId ?? this.relatedObjectId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      extraData: extraData ?? this.extraData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NotificationModel &&
        other.id == id &&
        other.title == title &&
        other.message == message &&
        other.notificationType == notificationType &&
        other.relatedObjectId == relatedObjectId &&
        other.isRead == isRead &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      message,
      notificationType,
      relatedObjectId,
      isRead,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, message: $message, notificationType: $notificationType, relatedObjectId: $relatedObjectId, isRead: $isRead, createdAt: $createdAt)';
  }

  /// Obtenir l'icône appropriée pour le type de notification
  String get iconName {
    switch (notificationType) {
      case 'new_message':
        return 'chat_bubble';
      case 'new_offer':
        return 'work';
      case 'offer_accepted':
        return 'check_circle';
      case 'offer_rejected':
        return 'cancel';
      case 'quote_request':
        return 'request_quote';
      case 'quote_accepted':
        return 'thumb_up';
      case 'quote_rejected':
        return 'thumb_down';
      case 'payment_received':
        return 'payment';
      case 'dispute_created':
        return 'warning';
      case 'dispute_resolved':
        return 'check';
      case 'review_received':
        return 'star';
      case 'project_created':
        return 'assignment';
      case 'project_completed':
        return 'assignment_turned_in';
      default:
        return 'notifications';
    }
  }

  /// Obtenir la couleur appropriée pour le type de notification
  String get colorHex {
    switch (notificationType) {
      case 'new_message':
        return '#2196F3'; // Bleu
      case 'new_offer':
        return '#4CAF50'; // Vert
      case 'offer_accepted':
        return '#4CAF50'; // Vert
      case 'offer_rejected':
        return '#F44336'; // Rouge
      case 'quote_request':
        return '#FF9800'; // Orange
      case 'quote_accepted':
        return '#4CAF50'; // Vert
      case 'quote_rejected':
        return '#F44336'; // Rouge
      case 'payment_received':
        return '#4CAF50'; // Vert
      case 'dispute_created':
        return '#FF5722'; // Rouge-orange
      case 'dispute_resolved':
        return '#4CAF50'; // Vert
      case 'review_received':
        return '#FFD700'; // Or
      case 'project_created':
        return '#9C27B0'; // Violet
      case 'project_completed':
        return '#4CAF50'; // Vert
      default:
        return '#757575'; // Gris
    }
  }

  /// Vérifier si la notification est récente (moins de 24h)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  /// Obtenir le temps écoulé sous forme de chaîne
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  /// Vérifier si la notification nécessite une action
  bool get requiresAction {
    return [
      'new_offer',
      'quote_request',
      'dispute_created',
    ].contains(notificationType);
  }

  /// Obtenir l'URL ou la route de destination
  String? get destinationRoute {
    switch (notificationType) {
      case 'new_message':
        return '/conversation/$relatedObjectId';
      case 'new_offer':
      case 'offer_accepted':
      case 'offer_rejected':
        return '/offers/$relatedObjectId';
      case 'quote_request':
      case 'quote_accepted':
      case 'quote_rejected':
        return '/quotes/$relatedObjectId';
      case 'dispute_created':
      case 'dispute_resolved':
        return '/disputes/$relatedObjectId';
      case 'review_received':
        return '/reviews';
      case 'project_created':
      case 'project_completed':
        return '/projects/$relatedObjectId';
      case 'payment_received':
        return '/payments';
      default:
        return null;
    }
  }
}