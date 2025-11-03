class ProviderModel {
  final int id;
  final String name;
  final String? companyName; 
  final String businessType;
  final String profileImageUrl;
  final String coverImageUrl; 
  final double rating;
  final int reviewCount;
  final String description;
  final List<ServiceItem> services;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isFeatured;
  final bool isVerified;
  final double trustScore;
  double? distance;

  ProviderModel({
    required this.id,
    required this.name,
    this.companyName,
    required this.businessType,
    required this.profileImageUrl,
    this.coverImageUrl = '',
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.services,
    this.address,
    this.latitude,
    this.longitude,
    this.isFeatured = false,
    this.isVerified = false,
    this.trustScore = 0.0,
    this.distance,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    List<ServiceItem> servicesList = [];
    
    if (json['services'] != null) {
      try {
        servicesList = List<ServiceItem>.from(
          json['services'].map((service) => ServiceItem.fromJson(service))
        );
      } catch (e) {
        print('⚠️ Erreur parsing services: $e');
        servicesList = [];
      }
    }

    String parseStringSafely(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    int parseIntSafely(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String && value.isNotEmpty) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    double parseDoubleSafely(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String && value.isNotEmpty) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    bool parseBoolSafely(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return defaultValue;
    }
    // Parse rating avec validation
    double parseRating(dynamic ratingValue) {
      if (ratingValue == null) return 0.0;
      if (ratingValue is double) return ratingValue;
      if (ratingValue is int) return ratingValue.toDouble();
      if (ratingValue is String) {
        final parsed = double.tryParse(ratingValue);
        return parsed ?? 0.0;
      }
      return 0.0;
    }
    
    // Parse review count avec validation
    int parseReviewCount(dynamic countValue) {
      if (countValue == null) return 0;
      if (countValue is int) return countValue;
      if (countValue is double) return countValue.round();
      if (countValue is String) {
        final parsed = int.tryParse(countValue);
        return parsed ?? 0;
      }
      return 0;
    }
    
    return ProviderModel(
      id: parseIntSafely(json['id']),
      // ✅ Parsing sécurisé pour tous les champs String requis
      name: parseStringSafely(json['name'] ?? json['username'] ?? json['company_name'], 'Prestataire sans nom'),
      companyName: json['company_name'] != null ? parseStringSafely(json['company_name'], '') : null,
      businessType: parseStringSafely(json['business_type'], 'Entreprise'),
      profileImageUrl: parseStringSafely(json['profile_image_url'] ?? json['avatar'] ?? json['profile_picture'], ''),
      description: parseStringSafely(json['description'] ?? json['bio'], ''),
      // ✅ Parsing sécurisé pour les numbers
      rating: parseDoubleSafely(json['rating'] ?? json['average_rating'] ?? json['avg_rating']),
      reviewCount: parseIntSafely(json['review_count'] ?? json['reviews_count'] ?? json['total_reviews']),
      trustScore: parseDoubleSafely(json['trust_score']),
      // ✅ Parsing sécurisé pour les booleans
      isFeatured: parseBoolSafely(json['is_featured']),
      isVerified: parseBoolSafely(json['is_verified']),
      // ✅ Champs optionnels avec parsing sécurisé
      address: json['address']?.toString(),
      latitude: json['latitude'] != null ? parseDoubleSafely(json['latitude']) : null,
      longitude: json['longitude'] != null ? parseDoubleSafely(json['longitude']) : null,
      services: servicesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company_name': companyName,
      'business_type': businessType,
      'profile_image_url': profileImageUrl,
      'rating': rating,
      'review_count': reviewCount,
      'description': description,
      'services': services.map((service) => service.toJson()).toList(),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_featured': isFeatured,
      'is_verified': isVerified,
      'trust_score': trustScore,
    };
  }

   @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProviderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProviderModel(id: $id, name: $name, businessType: $businessType)';
  }
}

// Modèle simplifié pour les services du prestataire
class ServiceItem {
  final int id;
  final String title;
  final String priceType;

  ServiceItem({
    required this.id,
    required this.title,
    required this.priceType,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'],
      title: json['title'],
      priceType: json['price_type'] ?? 'Sur devis',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price_type': priceType,
    };
  }
}