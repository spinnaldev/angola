// lib/core/models/review.dart - Version corrigée

class Review {
  final int? id;
  final int clientId;
  final int providerId;
  final int? serviceId;
  final int rating;
  final String comment;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String clientName;
  final String? clientImageUrl;
  final bool isVerified;
  
  // Getters pour compatibilité avec l'interface existante
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
    this.isVerified = false,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory Review.fromJson(Map<String, dynamic> json) {
    print('Debug Review.fromJson: $json'); // Debug log
    
    List<String> images = [];
    if (json['images'] != null) {
      images = (json['images'] as List)
          .map((img) => img is String ? img : img['image'] as String)
          .toList();
    }
    
    // Convertir overall_rating en entier, en gérant différents types possibles
    int parseRating(dynamic rating) {
      if (rating is int) return rating;
      if (rating is double) return rating.round();
      if (rating is String) return double.parse(rating).round();
      return 0; // Valeur par défaut si null ou type inconnu
    }
    
    // Gérer le nom du client - plusieurs sources possibles
    String getClientName(Map<String, dynamic> json) {
      if (json['client_name'] != null && json['client_name'].toString().trim().isNotEmpty) {
        return json['client_name'].toString();
      }
      if (json['client'] != null && json['client'] is Map) {
        final clientData = json['client'] as Map<String, dynamic>;
        if (clientData['name'] != null) return clientData['name'].toString();
        if (clientData['first_name'] != null && clientData['last_name'] != null) {
          return '${clientData['first_name']} ${clientData['last_name']}';
        }
        if (clientData['username'] != null) return clientData['username'].toString();
      }
      return 'Utilisateur'; // Nom par défaut
    }
    
    // Gérer l'image du client
    String? getClientImage(Map<String, dynamic> json) {
      if (json['client_picture'] != null) return json['client_picture'].toString();
      if (json['client'] != null && json['client'] is Map) {
        final clientData = json['client'] as Map<String, dynamic>;
        if (clientData['profile_picture'] != null) return clientData['profile_picture'].toString();
        if (clientData['avatar'] != null) return clientData['avatar'].toString();
      }
      return null;
    }
    
    return Review(
      id: json['id'],
      clientId: json['client_id'] ?? json['client'],
      providerId: json['provider_id'] ?? json['provider'],
      serviceId: json['service_id'] ?? json['service'],
      rating: parseRating(json['overall_rating'] ?? json['rating']),
      comment: json['comment'] ?? '',
      imageUrls: images,
      createdAt: DateTime.parse(json['created_at']),
      clientName: getClientName(json),
      clientImageUrl: getClientImage(json),
      isVerified: json['is_verified'] ?? false,
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