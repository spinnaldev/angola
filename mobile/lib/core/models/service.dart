// lib/core/models/service.dart - Mettre à jour pour inclure priceType et subcategoryId

class Service {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final int providerId;
  final String businessType;
  final double price;
  final String priceType;
  final int subcategoryId;
  final int categoryId;  
  final bool isAvailable;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.providerId,
    required this.businessType,
    required this.price,
    required this.categoryId, 
    this.priceType = 'quote',
    this.subcategoryId = 0,
    this.isAvailable = true,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      providerId: json['provider_id'] ?? 0,
      businessType: json['business_type'] ?? 'Entreprise',
      price: (json['price'] ?? 0.0).toDouble(),
      priceType: json['price_type'] ?? 'quote',
      subcategoryId: json['subcategory'] ?? 0,
      categoryId: json['category_id'] ?? 0, 
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'review_count': reviewCount,
      'provider_id': providerId,
      'business_type': businessType,
      'price': price,
      'price_type': priceType,
      'subcategory': subcategoryId,
      'is_available': isAvailable,
    };
  }
}