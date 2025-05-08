// lib/providers/review_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/review.dart';
import '../core/services/review_service.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService;
  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReviewProvider(this._reviewService);

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Créer un nouvel avis
  Future<bool> createReview(
    int providerId,
    double rating,
    String comment,
    List<File> images, {
    int? serviceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final review = Review(
        clientId: 0, // Sera remplacé par l'API
        providerId: providerId,
        serviceId: serviceId,
        rating: rating,
        comment: comment,
        clientName: '', // Sera remplacé par l'API
      );
      
      await _reviewService.createReview(review, images);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      return false;
    }
  }

  // Récupérer les avis d'un prestataire
  Future<void> fetchProviderReviews(int providerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reviews = await _reviewService.getProviderReviews(providerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Récupérer les avis laissés par l'utilisateur
  Future<void> fetchUserReviews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reviews = await _reviewService.getUserReviews();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}