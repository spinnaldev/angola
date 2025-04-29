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
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      providerId: json['provider_id'],
      businessType: json['business_type'] ?? 'Entreprise',
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }
}