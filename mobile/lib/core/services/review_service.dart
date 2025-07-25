// lib/core/services/review_service.dart - VERSION CORRIGÉE avec ApiClient

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import 'api_service.dart';
import '../api/api_client.dart'; // ✅ Import ApiClient
import 'package:http_parser/http_parser.dart';

class ReviewService {
  final ApiService _apiService;
  late final ApiClient _apiClient; // ✅ Référence ApiClient
  
  ReviewService(this._apiService) {
    // ✅ Initialiser ApiClient pour bénéficier des corrections d'encodage
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }
  
  // ✅ MÉTHODE CORRIGÉE: createReviewWithTitle (MultipartRequest conservé mais headers corrigés)
  Future<Review> createReviewWithTitle(
    Review review,
    List<File> images
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/reviews/'),
      );
      
      // ✅ Utiliser ApiClient pour les headers (cohérence avec encodage)
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      request.fields['provider'] = review.providerId.toString();
      if (review.serviceId != null) {
        request.fields['service'] = review.serviceId.toString();
      }
      
      request.fields['quality_rating'] = review.rating.toString();
      request.fields['punctuality_rating'] = review.rating.toString(); 
      request.fields['value_rating'] = review.rating.toString();
      request.fields['comment'] = review.comment;
      
      // NOUVEAU: Ajouter le titre de l'avis
      if (review.reviewTitle != null && review.reviewTitle!.isNotEmpty) {
        request.fields['review_title'] = review.reviewTitle!;
      }
      
      // Ajouter les images
      for (var i = 0; i < images.length; i++) {
        var file = images[i];
        var fileName = file.path.split('/').last;
        var extension = fileName.split('.').last.toLowerCase();
        
        var mimeType = 'image/jpeg';
        if (extension == 'png') mimeType = 'image/png';
        if (extension == 'gif') mimeType = 'image/gif';
        
        request.files.add(
          http.MultipartFile(
            'uploaded_images',
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Review creation response status: ${response.statusCode}');
      print('Review creation response body: ${response.body}');
      
      if (response.statusCode == 201) {
        // ✅ Traitement UTF-8 pour la réponse MultipartRequest
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }
        
        final data = json.decode(responseBody);
        return Review.fromJson(data);
      } else {
        throw Exception('Failed to create review: ${response.body}');
      }
    } catch (e) {
      print('Error in createReviewWithTitle: $e');
      rethrow;
    }
  }
  
  // Méthode existante conservée pour compatibilité
  Future<Review> createReview(
    Review review,
    List<File> images
  ) async {
    // Appeler la nouvelle méthode
    return createReviewWithTitle(review, images);
  }
  
  // ✅ MÉTHODE CORRIGÉE: getProviderReviews
  Future<List<Review>> getProviderReviews(int providerId) async {
    try {
      print('Fetching reviews for provider: $providerId');
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('reviews/?provider=$providerId', requireAuth: false);
      
      print('✅ Response data type: ${responseData.runtimeType}');
      print('✅ Response data: $responseData');
      
      if (responseData != null) {
        // ✅ Gérer les données déjà décodées par ApiClient
        List<dynamic> data = [];
        
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
        
        // ✅ Debug encodage des commentaires
        for (var review in reviews.take(2)) {
          print('✅ Review comment: ${review.comment} (encodage correct)');
        }
        
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
  
  // ✅ MÉTHODE CORRIGÉE: getUserReviews
  Future<List<Review>> getUserReviews() async {
    try {
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('reviews/my-reviews/', requireAuth: true);
      
      if (responseData != null) {
        // ✅ Gérer les données déjà décodées par ApiClient
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

  // ✅ MÉTHODE CORRIGÉE: getServiceReviews
  Future<List<Review>> getServiceReviews(int serviceId) async {
    try {
      print('Fetching reviews for service: $serviceId');
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('reviews/?service=$serviceId', requireAuth: false);
      
      print('✅ Service reviews response: $responseData');
      
      if (responseData != null) {
        // ✅ Gérer les données déjà décodées par ApiClient
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
        
        // ✅ Debug encodage
        for (var review in reviews.take(2)) {
          print('✅ Service review: ${review.comment}');
        }
        
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
  
  // ✅ MÉTHODE CORRIGÉE: getTopReviews
  Future<List<Review>> getTopReviews() async {
    try {
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('reviews/top_reviews/', requireAuth: false);
      
      print('✅ Top reviews response received');
      
      if (responseData != null) {
        // ✅ Gérer les données déjà décodées par ApiClient
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
        
        // ✅ Debug encodage des meilleurs avis
        for (var review in reviews.take(2)) {
          print('✅ Top review: ${review.comment} (encodage correct)');
        }
        
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