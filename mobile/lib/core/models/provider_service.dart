// lib/core/models/provider_service.dart
class ProviderService {
  final int id;
  final String title;
  final String description;
  final double? price;
  final String priceType;
  final String? imageUrl;
  final String subcategoryName;
  final String categoryName;
  final double avgRating;

  ProviderService({
    required this.id,
    required this.title,
    required this.description,
    this.price,
    required this.priceType,
    this.imageUrl,
    required this.subcategoryName,
    required this.categoryName,
    required this.avgRating,
  });

  factory ProviderService.fromJson(Map<String, dynamic> json) {
    return ProviderService(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price']?.toDouble(),
      priceType: json['price_type'],
      imageUrl: json['image_url'],
      subcategoryName: json['subcategory_name'],
      categoryName: json['category_name'],
      avgRating: (json['avg_rating'] ?? 0.0).toDouble(),
    );
  }
}