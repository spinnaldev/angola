// lib/core/services/review_service.dart - VERSION CORRIGÉE avec bons endpoints

import '../api/api_client.dart';
import '../models/review.dart';

class ReviewService {
  final ApiClient _apiClient;

  ReviewService(this._apiClient);

  // ✅ CORRIGÉ - Créer un avis avec titre
  Future<void> createReviewWithTitle(
      Review review, List<dynamic> images) async {
    try {
      print('🚀 Création d\'avis avec titre...');

      final Map<String, dynamic> reviewData = {
        'provider': review.providerId,
        'service': review.serviceId,
        'overall_rating': review.rating,
        'quality_rating': review.qualityRating ?? review.rating,
        'punctuality_rating': review.punctualityRating ?? review.rating,
        'value_rating': review.valueRating ?? review.rating,
        'comment': review.comment,
        'review_title': review.reviewTitle, // ✅ AJOUT du titre
      };

      await _apiClient.post('reviews/', data: reviewData, requireAuth: true);
      print('✅ Avis créé avec succès');
    } catch (e) {
      print('❌ Erreur création avis: $e');
      throw e;
    }
  }

  // ✅ CORRIGÉ - Avis d'un prestataire spécifique
  Future<List<Review>> getProviderReviews(int providerId) async {
    try {
      print('📥 Récupération avis prestataire: $providerId');

      // ✅ ENDPOINT CORRIGÉ - Utiliser le bon endpoint
      final responseData = await _apiClient.get('reviews/?provider=$providerId',
          requireAuth: false);

      if (responseData != null) {
        List<dynamic> data = [];
        print(responseData);
        if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          print('Unexpected response format: $responseData');
          return [];
        }

        print('✅ Found ${data.length} reviews');

        final reviews = data.map((item) {
          print('✅ Processing review item: $item');
          return Review.fromJson(item);
        }).toList();

        print('✅ Successfully parsed ${reviews.length} reviews');

        return reviews;
      } else {
        print('❌ Null response from API');
        return [];
      }
    } catch (e) {
      print('❌ Error in getProviderReviews: $e');
      return [];
    }
  }

  // ✅ CORRIGÉ - Mes avis donnés (utilisateur connecté)
  Future<List<Review>> getUserReviews() async {
    try {
      print('📥 Récupération de mes avis donnés...');

      // ✅ ENDPOINT CORRIGÉ - Utiliser l'action custom du ViewSet
      final responseData =
          await _apiClient.get('reviews/my_reviews/', requireAuth: true);

      if (responseData != null) {
        List<dynamic> data = [];

        if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          return [];
        }

        final reviews = data.map((item) => Review.fromJson(item)).toList();

        print('✅ Récupéré ${reviews.length} avis utilisateur');

        return reviews;
      } else {
        throw Exception('Réponse nulle de l\'API pour les avis utilisateur');
      }
    } catch (e) {
      print('❌ Error in getUserReviews: $e');
      rethrow;
    }
  }

  // ✅ NOUVEAU - Avis reçus par un prestataire (utilisateur connecté)
  Future<List<Review>> getProviderReceivedReviews() async {
    try {
      print('📨 Récupération des avis reçus...');

      // ✅ ENDPOINT CORRIGÉ - Utiliser l'action custom du ViewSet
      final responseData =
          await _apiClient.get('reviews/provider_reviews/', requireAuth: true);

      if (responseData != null) {
        List<dynamic> data = [];

        if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          return [];
        }

        final reviews = data.map((item) => Review.fromJson(item)).toList();

        print('✅ Récupéré ${reviews.length} avis reçus');

        return reviews;
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error in getProviderReceivedReviews: $e');
      // Si l'utilisateur n'est pas prestataire, retourner liste vide
      if (e.toString().contains('You are not a provider')) {
        return [];
      }
      rethrow;
    }
  }

  // ✅ CORRIGÉ - Avis d'un service spécifique
  Future<List<Review>> getServiceReviews(int serviceId) async {
    try {
      print('Fetching reviews for service: $serviceId');

      // ✅ ENDPOINT CORRIGÉ - Filtrer par service
      final responseData = await _apiClient.get('reviews/?service=$serviceId',
          requireAuth: false);

      print('✅ Service reviews response: $responseData');

      if (responseData != null) {
        List<dynamic> data = [];

        if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          print('Unexpected response format: $responseData');
          return [];
        }

        print('✅ Found ${data.length} reviews for service $serviceId');

        final reviews = data.map((item) {
          print('✅ Processing service review item: $item');
          return Review.fromJson(item);
        }).toList();

        print('✅ Successfully parsed ${reviews.length} reviews for service');

        return reviews;
      } else {
        print('❌ Null response for service reviews');
        return [];
      }
    } catch (e) {
      print('❌ Error in getServiceReviews: $e');
      return [];
    }
  }

  // ✅ CORRIGÉ - Meilleurs avis
  Future<List<Review>> getTopReviews() async {
    try {
      print('📥 Récupération des meilleurs avis...');

      // ✅ ENDPOINT CORRIGÉ - Utiliser l'action custom
      final responseData =
          await _apiClient.get('reviews/top_reviews/', requireAuth: false);

      print('✅ Top reviews response received');

      if (responseData != null) {
        List<dynamic> data = [];

        if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          print('Unexpected top reviews response format: $responseData');
          return [];
        }

        print('✅ Found ${data.length} top reviews');

        final reviews = data.map((item) => Review.fromJson(item)).toList();

        return reviews;
      } else {
        print('❌ Null response for top reviews');
        return [];
      }
    } catch (e) {
      print('❌ Error in getTopReviews: $e');
      return [];
    }
  }
}
