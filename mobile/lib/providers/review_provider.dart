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
  List<Review> _topReviews = [];

  ReviewProvider(this._reviewService);

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Review> get topReviews => _topReviews;

  // Créer un nouvel avis
  Future<bool> createReview(
    int providerId,
    int rating,
    String comment,
    List<File> images,
    int? serviceId,
  ) async {
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
      // Vérifiez encore une fois
      print('Review object providerId: ${review.providerId}');

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

  // Nouvelle méthode pour récupérer les meilleurs avis pour la page d'accueil
  Future<void> fetchTopReviews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Utiliser votre service existant
      _topReviews = await _reviewService.getTopReviews();
      print("on a les top reviews");
      print(_topReviews);
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
