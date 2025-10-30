// lib/core/models/review.dart - Version corrigée avec toutes les propriétés

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
  
  // ✅ AJOUT des propriétés manquantes pour ReviewCard
  final String? reviewTitle;           // Titre de l'avis (appelé aussi title)
  final String? clientCompanyName;
  final String providerName;           // ✅ AJOUT - Nom du prestataire
  final String? providerImageUrl;      // ✅ AJOUT - Image du prestataire
  
  // ✅ AJOUT des notes détaillées utilisées dans ReviewCard
  final int? qualityRating;            // Note qualité (1-5)
  final int? punctualityRating;        // Note ponctualité (1-5)  
  final int? valueRating;              // Note rapport qualité/prix (1-5)

  // Getters pour compatibilité avec l'interface existante
  String get userName => clientName;
  String get userImageUrl => clientImageUrl ?? '';
  DateTime get date => createdAt;
  String? get title => reviewTitle;     // ✅ Alias pour reviewTitle

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
    this.reviewTitle,         
    this.clientCompanyName,
    required this.providerName,        // ✅ REQUIS maintenant
    this.providerImageUrl,
    this.qualityRating,                // ✅ AJOUT
    this.punctualityRating,            // ✅ AJOUT
    this.valueRating,                  // ✅ AJOUT
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
    
    // ✅ AJOUT - Gérer le nom du prestataire
    String getProviderName(Map<String, dynamic> json) {
      if (json['provider_name'] != null && json['provider_name'].toString().trim().isNotEmpty) {
        return json['provider_name'].toString();
      }
      if (json['provider'] != null && json['provider'] is Map) {
        final providerData = json['provider'] as Map<String, dynamic>;
        if (providerData['name'] != null) return providerData['name'].toString();
        if (providerData['user'] != null && providerData['user'] is Map) {
          final userData = providerData['user'] as Map<String, dynamic>;
          if (userData['first_name'] != null && userData['last_name'] != null) {
            return '${userData['first_name']} ${userData['last_name']}';
          }
          if (userData['username'] != null) return userData['username'].toString();
        }
      }
      return 'Prestataire'; // Nom par défaut
    }
    
    // Gérer l'image du client
    String? getClientImageUrl(Map<String, dynamic> json) {
      if (json['client_image_url'] != null) return json['client_image_url'].toString();
      if (json['client_avatar'] != null) return json['client_avatar'].toString();
      if (json['client'] != null && json['client'] is Map) {
        final clientData = json['client'] as Map<String, dynamic>;
        if (clientData['avatar'] != null) return clientData['avatar'].toString();
        if (clientData['profile_picture'] != null) return clientData['profile_picture'].toString();
      }
      return null;
    }
    
    // ✅ AJOUT - Gérer l'image du prestataire
    String? getProviderImageUrl(Map<String, dynamic> json) {
      if (json['provider_image_url'] != null) return json['provider_image_url'].toString();
      if (json['provider_avatar'] != null) return json['provider_avatar'].toString();
      if (json['provider'] != null && json['provider'] is Map) {
        final providerData = json['provider'] as Map<String, dynamic>;
        if (providerData['avatar'] != null) return providerData['avatar'].toString();
        if (providerData['profile_picture'] != null) return providerData['profile_picture'].toString();
      }
      return null;
    }
    
    // ✅ AJOUT - Parser les notes détaillées (avec valeurs par défaut)
    int? parseOptionalRating(dynamic rating) {
      if (rating == null) return null;
      if (rating is int) return rating;
      if (rating is double) return rating.round();
      if (rating is String) return double.tryParse(rating)?.round();
      return null;
    }
    
    return Review(
      id: json['id'] as int?,
      clientId: json['client_id'] as int? ?? json['client'] as int? ?? 0,
      providerId: json['provider_id'] as int? ?? json['provider'] as int? ?? 0,
      serviceId: json['service'] as int? ?? 0,
      rating: parseRating(json['overall_rating'] ?? json['rating'] ?? 0),
      comment: json['comment']?.toString() ?? '',
      imageUrls: images,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      clientName: getClientName(json),
      clientImageUrl: getClientImageUrl(json),
      isVerified: json['is_verified'] as bool? ?? false,
      reviewTitle: json['review_title']?.toString(),
      clientCompanyName: json['client_company_name']?.toString(),
      providerName: getProviderName(json),              // ✅ AJOUT
      providerImageUrl: getProviderImageUrl(json),      // ✅ AJOUT
      qualityRating: parseOptionalRating(json['quality_rating']),       // ✅ AJOUT
      punctualityRating: parseOptionalRating(json['punctuality_rating']), // ✅ AJOUT
      valueRating: parseOptionalRating(json['value_rating']),             // ✅ AJOUT
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'provider_id': providerId,
      'service_id': serviceId,
      'overall_rating': rating,
      'comment': comment,
      'images': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'client_name': clientName,
      'client_image_url': clientImageUrl,
      'is_verified': isVerified,
      'review_title': reviewTitle,
      'client_company_name': clientCompanyName,
      'provider_name': providerName,           // ✅ AJOUT
      'provider_image_url': providerImageUrl,  // ✅ AJOUT
      'quality_rating': qualityRating,         // ✅ AJOUT
      'punctuality_rating': punctualityRating, // ✅ AJOUT
      'value_rating': valueRating,             // ✅ AJOUT
    };
  }

  @override
  String toString() {
    return 'Review(id: $id, clientName: $clientName, providerName: $providerName, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode {
    return id?.hashCode ?? 0;
  }
}