// lib/core/services/review_service.dart - Version corrigée

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import 'api_service.dart';
import 'package:http_parser/http_parser.dart';

class ReviewService {
  final ApiService _apiService;
  
  ReviewService(this._apiService);
  
  // Créer un nouvel avis
  Future<Review> createReview(
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
      print('Error in createReview: $e');
      rethrow;
    }
  }
  
  // Récupérer les avis d'un prestataire avec meilleur debugging
  Future<List<Review>> getProviderReviews(int providerId) async {
    try {
      print('Fetching reviews for provider: $providerId');
      
      final headers = await _apiService.getHeaders(requireAuth: false);
      final url = '${_apiService.baseUrl}/reviews/?provider=$providerId';
      
      print('Request URL: $url');
      print('Request headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Gérer différents formats de réponse
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
        print('Error body: ${response.body}');
        throw Exception('Failed to get provider reviews: ${response.body}');
      }
    } catch (e) {
      print('Error in getProviderReviews: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
  
  // Récupérer les avis laissés par l'utilisateur
  Future<List<Review>> getUserReviews() async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/reviews/my_reviews/'),
        headers: headers,
      );
      
      print('User reviews response status: ${response.statusCode}');
      print('User reviews response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? responseData ?? [];
        return data.map((item) => Review.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get user reviews: ${response.body}');
      }
    } catch (e) {
      print('Error in getUserReviews: $e');
      rethrow;
    }
  }

  Future<List<Review>> getTopReviews() async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/reviews/top_reviews/'),
        headers: headers,
      );

      print('Top reviews response status: ${response.statusCode}');
      print('Top reviews response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Review.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des meilleurs avis');
      }
    } catch (e) {
      print('Error in getTopReviews: $e');
      throw Exception('Erreur réseau: ${e.toString()}');
    }
  }
}