// lib/core/models/service.dart - Mettre à jour pour inclure priceType et subcategoryId

import 'package:teyago/core/models/service_option.dart';

class Service {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final int provider_id;
  final String businessType;
  final double price;
  final String priceType;
  final int subcategoryId;
  final int categoryId;
  final bool isAvailable;
  final List<GalleryImage> galleryImages;
  final List<ServiceOption> options;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.provider_id,
    required this.businessType,
    required this.price,
    required this.categoryId,
    this.priceType = 'quote',
    this.subcategoryId = 0,
    this.isAvailable = true,
    this.galleryImages = const [],
    this.options = const [],
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    List<GalleryImage> galleryImages = [];
    if (json['gallery_images'] != null) {
      galleryImages = (json['gallery_images'] as List)
          .map((x) => GalleryImage.fromJson(x))
          .toList();
    }

    List<ServiceOption> options = [];
    if (json['options'] != null) {
      options = (json['options'] as List)
          .map((x) => ServiceOption.fromJson(x))
          .toList();
    }

    double parsePrice(dynamic priceValue) {
      if (priceValue == null) return 0.0;

      if (priceValue is double) {
        return priceValue;
      } else if (priceValue is int) {
        return priceValue.toDouble();
      } else if (priceValue is String) {
        // ✅ CORRECTION PRINCIPALE : Parser le string en double
        if (priceValue.isEmpty) return 0.0;
        final parsed = double.tryParse(priceValue);
        return parsed ?? 0.0;
      } else {
        print(
            '⚠️ Type de prix inattendu: ${priceValue.runtimeType} - $priceValue');
        return double.tryParse(priceValue.toString()) ?? 0.0;
      }
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

    return Service(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      rating: parseRating(json['rating'] ?? json['average_rating'] ?? json['service_rating']),
      reviewCount: parseReviewCount(json['review_count'] ??
          json['reviews_count'] ??
          json['service_reviews_count'] ??
          json['total_reviews']),
      provider_id: json['provider_id'] ?? 0,
      businessType: json['business_type'] ?? 'Entreprise',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      priceType: json['price_type'] ?? 'quote',
      subcategoryId: json['subcategory'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      isAvailable: json['is_available'] ?? true,
      galleryImages: galleryImages,
      options: options,
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
      'provider_id': provider_id,
      'business_type': businessType,
      'price': price,
      'price_type': priceType,
      'subcategory': subcategoryId,
      'is_available': isAvailable,
    };
  }
}
