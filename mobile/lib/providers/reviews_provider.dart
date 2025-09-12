// lib/providers/reviews_provider.dart - VERSION SIMPLIFIÉE

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

  // ✅ SUPPRIMÉ - Plus de loadAllReviews qui charge tout
  // Maintenant on charge seulement ce dont on a besoin

  // ✅ Charger les avis donnés par l'utilisateur (CLIENTS)
  Future<void> loadReviewsGiven() async {
    print('📝 [CLIENT] Chargement des avis donnés...');
    
    _isLoadingGiven = true;
    _error = '';
    notifyListeners();

    try {
      _reviewsGiven = await _reviewService.getUserReviews();
      _averageRatingGiven = _calculateAverageRating(_reviewsGiven);
      
      print('✅ ${_reviewsGiven.length} avis donnés chargés');
    } catch (e) {
      print('❌ Erreur loadReviewsGiven: $e');
      _error = e.toString();
      _reviewsGiven = []; // Réinitialiser en cas d'erreur
    } finally {
      _isLoadingGiven = false;
      notifyListeners();
    }
  }

  // ✅ Charger les avis reçus (PRESTATAIRES uniquement)
  Future<void> loadReviewsReceived() async {
    print('📨 [PROVIDER] Chargement des avis reçus...');
    
    _isLoadingReceived = true;
    _error = '';
    notifyListeners();

    try {
      _reviewsReceived = await _reviewService.getProviderReceivedReviews();
      _averageRatingReceived = _calculateAverageRating(_reviewsReceived);
      
      print('✅ ${_reviewsReceived.length} avis reçus chargés');
    } catch (e) {
      print('❌ Erreur loadReviewsReceived: $e');
      
      // ✅ GESTION SPÉCIALE - Si pas prestataire, ne pas traiter comme erreur
      if (e.toString().contains('You are not a provider') || 
          e.toString().contains('not a provider') ||
          e.toString().contains('400')) {
        print('ℹ️ Utilisateur n\'est pas prestataire - normal');
        _reviewsReceived = [];
        _averageRatingReceived = 0.0;
        // Ne pas définir d'erreur car c'est normal
      } else {
        _error = e.toString();
        _reviewsReceived = [];
        _averageRatingReceived = 0.0;
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

  // ✅ NOUVEAU - Effacer seulement les avis donnés
  void clearReviewsGiven() {
    _reviewsGiven = [];
    _averageRatingGiven = 0.0;
    _isLoadingGiven = false;
    if (_error.isNotEmpty && !_isLoadingReceived) {
      _error = '';
    }
    notifyListeners();
  }

  // ✅ NOUVEAU - Effacer seulement les avis reçus  
  void clearReviewsReceived() {
    _reviewsReceived = [];
    _averageRatingReceived = 0.0;
    _isLoadingReceived = false;
    if (_error.isNotEmpty && !_isLoadingGiven) {
      _error = '';
    }
    notifyListeners();
  }

  // Effacer toutes les données
  void clearReviews() {
    _reviewsGiven = [];
    _reviewsReceived = [];
    _averageRatingGiven = 0.0;
    _averageRatingReceived = 0.0;
    _error = '';
    _isLoadingGiven = false;
    _isLoadingReceived = false;
    notifyListeners();
  }

  // ✅ NOUVEAU - Debug info
  void debugState() {
    print('=== REVIEWS PROVIDER DEBUG ===');
    print('Reviews given: ${_reviewsGiven.length}');
    print('Reviews received: ${_reviewsReceived.length}');
    print('Loading given: $_isLoadingGiven');
    print('Loading received: $_isLoadingReceived');
    print('Error: $_error');
    print('Average given: $_averageRatingGiven');
    print('Average received: $_averageRatingReceived');
    print('=============================');
  }
}