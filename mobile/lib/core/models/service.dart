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
    // ✅ PARSING DES GALLERY IMAGES avec protection
    List<GalleryImage> galleryImages = [];
    if (json['gallery_images'] != null) {
      try {
        galleryImages = (json['gallery_images'] as List)
            .where((x) => x != null) // Filtrer les nulls
            .map((x) => GalleryImage.fromJson(x))
            .toList();
      } catch (e) {
        print('Erreur parsing gallery_images: $e');
        galleryImages = [];
      }
    }

    // ✅ PARSING DES OPTIONS avec protection
    List<ServiceOption> options = [];
    if (json['options'] != null) {
      try {
        options = (json['options'] as List)
            .where((x) => x != null) // Filtrer les nulls
            .map((x) => ServiceOption.fromJson(x))
            .toList();
      } catch (e) {
        print('Erreur parsing options: $e');
        options = [];
      }
    }

    // ✅ FONCTIONS DE PARSING SÉCURISÉ (vos fonctions existantes améliorées)
    double parsePrice(dynamic priceValue) {
      if (priceValue == null) return 0.0;

      if (priceValue is double) {
        return priceValue;
      } else if (priceValue is int) {
        return priceValue.toDouble();
      } else if (priceValue is String) {
        if (priceValue.isEmpty) return 0.0;
        final parsed = double.tryParse(priceValue);
        return parsed ?? 0.0;
      } else {
        print('⚠️ Type de prix inattendu: ${priceValue.runtimeType} - $priceValue');
        return double.tryParse(priceValue.toString()) ?? 0.0;
      }
    }

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

    // ✅ FONCTION DE PARSING STRING SÉCURISÉ
    String parseString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      return value.toString().trim();
    }

    // ✅ FONCTION DE PARSING INT SÉCURISÉ
    int parseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String && value.isNotEmpty) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    // ✅ FONCTION DE PARSING BOOL SÉCURISÉ
    bool parseBool(dynamic value, [bool defaultValue = false]) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        final lowerValue = value.toLowerCase().trim();
        return lowerValue == 'true' || lowerValue == '1' || lowerValue == 'yes';
      }
      return defaultValue;
    }

    // ✅ CONSTRUCTION DU SERVICE avec parsing sécurisé
    try {
      return Service(
        // ID - Vérification obligatoire
        id: parseInt(json['id']) > 0 ? parseInt(json['id']) : throw Exception('ID service invalide'),
        
        // Title - Obligatoire avec fallback
        title: parseString(json['title'], 'Service sans titre'),
        
        // Description avec fallback
        description: parseString(json['description'], ''),
        
        // Image URL
        imageUrl: parseString(json['image_url']),
        
        // Rating avec multiples sources possibles
        rating: parseRating(
          json['avg_rating'] ??
          json['rating']
        ),
        
        // Review count avec multiples sources possibles
        reviewCount: parseReviewCount(
          json['review_count'] ??
          json['reviews_count'] ??
          json['service_reviews_count'] ??
          json['total_reviews']
        ),
        
        // Provider ID
        provider_id: parseInt(json['provider_id']) ?? 0,
        
        // Business type
        businessType: parseString(json['business_type'], 'Entreprise'),
        
        // Price avec parsing sécurisé
        price: parsePrice(json['price']),
        
        // Price type
        priceType: parseString(json['price_type'], 'quote'),
        
        // Subcategory ID
        subcategoryId: parseInt(json['subcategory']),
        
        // Category ID
        categoryId: parseInt(json['category_id']),
        
        // Availability
        isAvailable: parseBool(json['is_available'], true),
        
        // Gallery images (déjà parsées plus haut)
        galleryImages: galleryImages,
        
        // Options (déjà parsées plus haut)
        options: options,
      );
    } catch (e) {
      // ✅ GESTION D'ERREUR avec service par défaut pour éviter les crashes
      print('❌ ERREUR dans Service.fromJson: $e');
      print('JSON problématique: $json');
      
      // Retourner un service minimal mais valide
      return Service(
        id: parseInt(json['id'], -1),
        title: 'Service indisponible',
        description: 'Erreur de chargement',
        imageUrl: '',
        rating: 0.0,
        reviewCount: 0,
        provider_id: 0,
        businessType: 'Entreprise',
        price: 0.0,
        priceType: 'quote',
        subcategoryId: 0,
        categoryId: 0,
        isAvailable: false,
        galleryImages: [],
        options: [],
      );
    }
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
