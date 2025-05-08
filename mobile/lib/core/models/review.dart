// lib/core/models/review.dart - Mise à jour pour inclure les champs manquants

class Review {
  final int? id;
  final int clientId;
  final int providerId;
  final int? serviceId;
  final double rating;
  final String comment;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String clientName;
  final String? clientImageUrl;
  
  // Ajout des propriétés qui étaient manquantes
  String get userName => clientName;
  String get userImageUrl => clientImageUrl ?? '';
  DateTime get date => createdAt;

  Review({
    this.id,
    required this.clientId,
    required this.providerId,
    this.serviceId,
    required this.rating,
    required this.comment,
    this.imageUrls = const [],
    DateTime? createdAt,
    required this.clientName,
    this.clientImageUrl,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory Review.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['images'] != null) {
      images = (json['images'] as List).map((img) => img['image'] as String).toList();
    }
    
    return Review(
      id: json['id'],
      clientId: json['client'],
      providerId: json['provider'],
      serviceId: json['service'],
      rating: json['overall_rating'].toDouble(),
      comment: json['comment'],
      imageUrls: images,
      createdAt: DateTime.parse(json['created_at']),
      clientName: json['client_name'] ?? 'Anonymous',
      clientImageUrl: json['client_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': providerId,
      'service': serviceId,
      'quality_rating': rating,
      'punctuality_rating': rating,
      'value_rating': rating,
      'comment': comment,
    };
  }
}