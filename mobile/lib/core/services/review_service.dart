// lib/core/services/review_service.dart - VERSION MISE À JOUR

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import 'api_service.dart';
import 'package:http_parser/http_parser.dart';

class ReviewService {
  final ApiService _apiService;
  
  ReviewService(this._apiService);
  
  // NOUVELLE méthode: Créer un avis avec titre
  Future<Review> createReviewWithTitle(
    Review review,
    List<File> images
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/reviews/'),
      );
      
      final headers = await _apiService.getHeaders();
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
        final data = json.decode(response.body);
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
  
  // Récupérer les avis d'un prestataire
  Future<List<Review>> getProviderReviews(int providerId) async {
    try {
      print('Fetching reviews for provider: $providerId');
      
      final headers = await _apiService.getHeaders(requireAuth: false);
      final url = '${_apiService.baseUrl}/reviews/?provider=$providerId';
      
      print('Request URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        List<dynamic> data;
        if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          print('Unexpected response format: $responseData');
          return [];
        }
        
        print('Found ${data.length} reviews');
        
        final reviews = data.map((item) {
          print('Processing review item: $item');
          return Review.fromJson(item);
        }).toList();
        
        print('Successfully parsed ${reviews.length} reviews');
        return reviews;
        
      } else {
        print('Failed to get provider reviews. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in getProviderReviews: $e');
      return [];
    }
  }
  
  // Récupérer les avis de l'utilisateur connecté
  Future<List<Review>> getUserReviews() async {
    try {
      final headers = await _apiService.getHeaders();
      final url = '${_apiService.baseUrl}/reviews/my-reviews/';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        List<dynamic> data;
        if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          return [];
        }
        
        return data.map((item) => Review.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get user reviews');
      }
    } catch (e) {
      print('Error in getUserReviews: $e');
      rethrow;
    }
  }

  // Nouvelle méthode pour récupérer les avis d'un service spécifique
  Future<List<Review>> getServiceReviews(int serviceId) async {
    try {
      print('Fetching reviews for service: $serviceId');
      
      final headers = await _apiService.getHeaders(requireAuth: false);
      final url = '${_apiService.baseUrl}/reviews/?service=$serviceId';
      
      print('Request URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        List<dynamic> data;
        if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          print('Unexpected response format: $responseData');
          return [];
        }
        
        print('Found ${data.length} reviews for service $serviceId');
        
        final reviews = data.map((item) {
          print('Processing review item: $item');
          return Review.fromJson(item);
        }).toList();
        
        print('Successfully parsed ${reviews.length} reviews for service');
        return reviews;
        
      } else {
        print('Failed to get service reviews. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in getServiceReviews: $e');
      return [];
    }
  }
  
  // Récupérer les meilleurs avis pour la page d'accueil
  Future<List<Review>> getTopReviews() async {
    try {
      final headers = await _apiService.getHeaders(requireAuth: false);
      final url = '${_apiService.baseUrl}/reviews/top_reviews/';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('Top reviews response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        List<dynamic> data;
        if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          print('Unexpected top reviews response format: $responseData');
          return [];
        }
        
        print('Found ${data.length} top reviews');
        
        return data.map((item) => Review.fromJson(item)).toList();
      } else {
        print('Failed to get top reviews. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in getTopReviews: $e');
      return [];
    }
  }
}