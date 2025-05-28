// lib/core/models/service_option.dart
class ServiceOption {
  final int? id;
  final String name;
  final String description;
  final double? price;
  final bool isIncluded;
  
  ServiceOption({
    this.id,
    required this.name,
    this.description = '',
    this.price,
    this.isIncluded = true,
  });
  
  factory ServiceOption.fromJson(Map<String, dynamic> json) {
    return ServiceOption(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      isIncluded: json['is_included'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'price': price,
      'is_included': isIncluded,
    };
  }
}

// lib/core/models/gallery_image.dart
class GalleryImage {
  final int? id;
  final String? imageUrl;
  final String caption;
  final int order;
  
  GalleryImage({
    this.id,
    this.imageUrl,
    this.caption = '',
    this.order = 0,
  });
  
  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      id: json['id'],
      imageUrl: json['image_url'],
      caption: json['caption'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}