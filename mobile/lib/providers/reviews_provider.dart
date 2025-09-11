import 'package:flutter/material.dart';
import 'package:teyago/providers/auth_provider.dart';
import '../core/models/review.dart';
import '../core/services/review_service.dart';

class ReviewsProvider with ChangeNotifier {
  final ReviewService _reviewService;

  List<Review> _reviewsGiven = [];
  List<Review> _reviewsReceived = [];
  bool _isLoadingGiven = false;
  bool _isLoadingReceived = false;
  String _error = '';

  ReviewsProvider(this._reviewService);

  // Getters
  List<Review> get reviewsGiven => _reviewsGiven;
  List<Review> get reviewsReceived => _reviewsReceived;
  bool get isLoadingGiven => _isLoadingGiven;
  bool get isLoadingReceived => _isLoadingReceived;
  bool get isLoading => _isLoadingGiven || _isLoadingReceived;
  String get error => _error;
  int get totalReviews => _reviewsGiven.length + _reviewsReceived.length;
  static AuthProvider? _authProvider;

  /// Charger tous les avis
  Future<void> loadAllReviews() async {
    await Future.wait([
      loadReviewsGiven(),
      loadReviewsReceived(),
    ]);
  }

  /// Charger les avis donnés
  Future<void> loadReviewsGiven() async {
    _isLoadingGiven = true;
    _error = '';
    notifyListeners();

    try {
      print('📝 Chargement des avis donnés...');
      // ✅ Utiliser votre méthode existante
      _reviewsGiven = await _reviewService.getUserReviews();
      print('✅ ${_reviewsGiven.length} avis donnés chargés');
    } catch (e) {
      _error = 'Erreur lors du chargement des avis donnés: $e';
      print('❌ Erreur loadReviewsGiven: $e');
      _reviewsGiven = [];
    } finally {
      _isLoadingGiven = false;
      notifyListeners();
    }
  }

  /// Charger les avis reçus
  Future<void> loadReviewsReceived() async {
    _isLoadingReceived = true;
    _error = '';
    notifyListeners();

    try {
      print('📨 Chargement des avis reçus...');
      // ✅ Utiliser votre méthode existante
      final user = _authProvider!.currentUser;
      if (user != null){
        _reviewsReceived = await _reviewService.getProviderReviews(user.id);
        print('✅ ${_reviewsReceived.length} avis reçus chargés');
      }
      
    } catch (e) {
      _error = 'Erreur lors du chargement des avis reçus: $e';
      print('❌ Erreur loadReviewsReceived: $e');
      _reviewsReceived = [];
    } finally {
      _isLoadingReceived = false;
      notifyListeners();
    }
  }

  /// Calculer la note moyenne des avis reçus
  double get averageRatingReceived {
    if (_reviewsReceived.isEmpty) return 0.0;
    
    final totalRating = _reviewsReceived
        .map((review) => review.rating)
        .reduce((a, b) => a + b);
    
    return totalRating / _reviewsReceived.length;
  }

  /// Calculer la note moyenne des avis donnés
  double get averageRatingGiven {
    if (_reviewsGiven.isEmpty) return 0.0;
    
    final totalRating = _reviewsGiven
        .map((review) => review.rating)
        .reduce((a, b) => a + b);
    
    return totalRating / _reviewsGiven.length;
  }

  /// Effacer les erreurs
  void clearError() {
    _error = '';
    notifyListeners();
  }
}