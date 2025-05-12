class ProviderModel {
  final int id;
  final String name;
  final String businessType;
  final String profileImageUrl;
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


  ProviderModel({
    required this.id,
    required this.name,
    required this.businessType,
    required this.profileImageUrl,
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
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    List<ServiceItem> servicesList = [];
    
    if (json['services'] != null) {
      servicesList = List<ServiceItem>.from(
        json['services'].map((service) => ServiceItem.fromJson(service))
      );
    }
    
    return ProviderModel(
      id: json['id'],
      name: json['name'],
      businessType: json['business_type'] ?? 'Entreprise',
      profileImageUrl: json['profile_image_url'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      description: json['description'] ?? '',
      services: servicesList,
      address: json['address'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      isFeatured: json['is_featured'] ?? false,
      isVerified: json['is_verified'] ?? false,
      trustScore: json['trust_score'] != null ? (json['trust_score'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
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