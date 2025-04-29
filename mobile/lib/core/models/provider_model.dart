class ProviderModel {
  final int id;
  final String name;
  final String businessType;
  final String profileImageUrl;
  final double rating;
  final int reviewCount;
  final String description;
  final List<ServiceItem> services;

  ProviderModel({
    required this.id,
    required this.name,
    required this.businessType,
    required this.profileImageUrl,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.services,
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
    );
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
}