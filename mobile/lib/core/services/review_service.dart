// lib/core/services/review_service.dart

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
      // Utiliser multipart request pour pouvoir envoyer des fichiers
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/reviews/'),
      );
      
      // Ajouter les headers d'authentification
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);
      
      // Ajouter les champs du formulaire
      request.fields['provider'] = review.providerId.toString();
      if (review.serviceId != null) {
        request.fields['service'] = review.serviceId.toString();
      }
      request.fields['quality_rating'] = review.rating.toString();
      request.fields['punctuality_rating'] = review.rating.toString();
      request.fields['value_rating'] = review.rating.toString();
      request.fields['comment'] = review.comment;
      
      // Ajouter les images
      for (var i = 0; i < images.length; i++) {
        var file = images[i];
        var fileName = file.path.split('/').last;
        
        request.files.add(
          http.MultipartFile(
            'uploaded_images',
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: fileName,
            contentType: MediaType('image', 'jpeg'), // Adapter selon le type d'image
          ),
        );
      }
      
      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
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
  
  // Récupérer les avis d'un prestataire
  Future<List<Review>> getProviderReviews(int providerId) async {
    try {
      final headers = await _apiService.getHeaders(requireAuth: false);
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/reviews/?provider=$providerId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Review.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get provider reviews: ${response.body}');
      }
    } catch (e) {
      print('Error in getProviderReviews: $e');
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
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Review.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get user reviews: ${response.body}');
      }
    } catch (e) {
      print('Error in getUserReviews: $e');
      rethrow;
    }
  }
}