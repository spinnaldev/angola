// lib/providers/reviews_provider.dart - VERSION CORRIGÉE

import 'package:flutter/material.dart';
import '../core/models/review.dart';
import '../core/services/review_service.dart';

class ReviewsProvider with ChangeNotifier {
  final ReviewService _reviewService;

  ReviewsProvider(this._reviewService);

  // États pour avis donnés
  List<Review> _reviewsGiven = [];
  bool _isLoadingGiven = false;
  double _averageRatingGiven = 0.0;

  // États pour avis reçus
  List<Review> _reviewsReceived = [];
  bool _isLoadingReceived = false;
  double _averageRatingReceived = 0.0;

  // État d'erreur général
  String _error = '';

  // Getters
  List<Review> get reviewsGiven => _reviewsGiven;
  List<Review> get reviewsReceived => _reviewsReceived;
  bool get isLoadingGiven => _isLoadingGiven;
  bool get isLoadingReceived => _isLoadingReceived;
  double get averageRatingGiven => _averageRatingGiven;
  double get averageRatingReceived => _averageRatingReceived;
  String get error => _error;

  // ✅ CORRIGÉ - Charger tous les avis
  Future<void> loadAllReviews() async {
    await Future.wait([
      loadReviewsGiven(),
      loadReviewsReceived(),
    ]);
  }

  // ✅ CORRIGÉ - Charger les avis donnés par l'utilisateur
  Future<void> loadReviewsGiven() async {
    print('📝 Chargement des avis donnés...');
    
    _isLoadingGiven = true;
    _error = '';
    notifyListeners();

    try {
      // ✅ UTILISER LA MÉTHODE CORRIGÉE
      _reviewsGiven = await _reviewService.getUserReviews();
      _averageRatingGiven = _calculateAverageRating(_reviewsGiven);
      
      print('✅ ${_reviewsGiven.length} avis donnés chargés');
    } catch (e) {
      print('❌ Erreur loadReviewsGiven: $e');
      _error = e.toString();
    } finally {
      _isLoadingGiven = false;
      notifyListeners();
    }
  }

  // ✅ CORRIGÉ - Charger les avis reçus (pour prestataires)
  Future<void> loadReviewsReceived() async {
    print('📨 Chargement des avis reçus...');
    
    _isLoadingReceived = true;
    _error = '';
    notifyListeners();

    try {
      // ✅ UTILISER LA NOUVELLE MÉTHODE
      _reviewsReceived = await _reviewService.getProviderReceivedReviews();
      _averageRatingReceived = _calculateAverageRating(_reviewsReceived);
      
      print('✅ ${_reviewsReceived.length} avis reçus chargés');
    } catch (e) {
      print('❌ Erreur loadReviewsReceived: $e');
      // Si pas prestataire, ne pas considérer comme erreur
      if (e.toString().contains('You are not a provider')) {
        _reviewsReceived = [];
        _averageRatingReceived = 0.0;
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoadingReceived = false;
      notifyListeners();
    }
  }

  // ✅ MÉTHODE UTILITAIRE - Calculer note moyenne
  double _calculateAverageRating(List<Review> reviews) {
    if (reviews.isEmpty) return 0.0;
    
    final total = reviews.map((r) => r.rating).reduce((a, b) => a + b);
    return total / reviews.length;
  }

  // Effacer les erreurs
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Effacer toutes les données
  void clearReviews() {
    _reviewsGiven = [];
    _reviewsReceived = [];
    _averageRatingGiven = 0.0;
    _averageRatingReceived = 0.0;
    _error = '';
    notifyListeners();
  }
}