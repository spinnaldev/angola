
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

  // ✅ CORRIGÉ - Créer un avis avec titre
  Future<bool> createReviewWithTitle(
    int providerId,
    int rating,
    String title,
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
        reviewTitle: title,
        clientName: '', // Sera remplacé par l'API
        providerName: 'Prestataire', // ✅ AJOUT - valeur temporaire, sera remplacée par l'API
      );

      print('Review object providerId: ${review.providerId}');
      print('Review title: ${review.reviewTitle}');

      await _reviewService.createReviewWithTitle(review, images);

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

  // Méthode existante conservée pour compatibilité
  Future<bool> createReview(
    int providerId,
    int rating,
    String comment,
    String title,      
    List<File> images,
    int? serviceId,
  ) async {
    // Appeler la nouvelle méthode avec un titre par défaut
    return createReviewWithTitle(
      providerId,
      rating,
      title, // Titre par défaut
      comment,
      images,
      serviceId,
    );
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

  void clearReviews() {
    _reviews = [];
    _topReviews = [];
    _errorMessage = null;
    notifyListeners();
    print("🧹 ReviewProvider: Avis effacés");
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

  // Méthode pour récupérer les meilleurs avis pour la page d'accueil
  Future<void> fetchTopReviews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _topReviews = await _reviewService.getTopReviews();
      
      // Si pas d'avis depuis l'API, utiliser des données factices
      if (_topReviews.isEmpty) {
        _topReviews = _generateMockReviews();
      }
      
      print("Top reviews loaded: ${_topReviews.length}");
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des avis: $e');
      // En cas d'erreur, utiliser des données factices
      _topReviews = _generateMockReviews();
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Nouvelle méthode pour récupérer les avis spécifiques à un service
  Future<void> fetchServiceReviews(int serviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Récupération des avis pour le service: $serviceId');
      _reviews = await _reviewService.getServiceReviews(serviceId);
      print('${_reviews.length} avis trouvés pour le service $serviceId');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la récupération des avis du service: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ✅ CORRIGÉ - Générer des avis factices avec toutes les propriétés requises
  List<Review> _generateMockReviews() {
    return [
      Review(
        id: 1,
        clientId: 1,
        providerId: 1,
        rating: 5,
        comment: 'Travail impeccable, équipe très professionnelle et ponctuelle. Je recommande vivement pour tous vos travaux de rénovation.',
        reviewTitle: 'Excellent travail de rénovation',
        clientName: 'Marie Dubois',
        clientCompanyName: 'Restaurant Le Gourmet',
        providerName: 'RénoExpert SARL', // ✅ AJOUT - requis maintenant
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        qualityRating: 5, // ✅ AJOUT - optionnel mais recommandé pour les mocks
        punctualityRating: 5,
        valueRating: 4,
      ),
      Review(
        id: 2,
        clientId: 2,
        providerId: 2,
        rating: 5,
        comment: 'Service rapide et efficace. Le plombier est arrivé à l\'heure et a résolu le problème en moins d\'une heure.',
        reviewTitle: 'Dépannage rapide et efficace',
        clientName: 'Jean Martin',
        clientCompanyName: 'Café Central',
        providerName: 'Plomberie Express', // ✅ AJOUT
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        qualityRating: 5,
        punctualityRating: 5,
        valueRating: 5,
      ),
      Review(
        id: 3,
        clientId: 3,
        providerId: 3,
        rating: 5,
        comment: 'Excellent travail de peinture, finitions parfaites. L\'équipe a été très respectueuse et a nettoyé après les travaux.',
        reviewTitle: 'Peinture de qualité professionnelle',
        clientName: 'Sophie Laurent',
        clientCompanyName: null, // Pas d'entreprise
        providerName: 'Peinture Pro', // ✅ AJOUT
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        qualityRating: 5,
        punctualityRating: 4,
        valueRating: 4,
      ),
      Review(
        id: 4,
        clientId: 4,
        providerId: 4,
        rating: 5,
        comment: 'Installation électrique réalisée dans les règles de l\'art. Prestataire très compétent et de bon conseil.',
        reviewTitle: 'Installation électrique parfaite',
        clientName: 'Ahmed Ben Ali',
        clientCompanyName: 'Boulangerie Ben Ali',
        providerName: 'Électro Solutions', // ✅ AJOUT
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        qualityRating: 5,
        punctualityRating: 5,
        valueRating: 4,
      ),
      Review(
        id: 5,
        clientId: 5,
        providerId: 5,
        rating: 5,
        comment: 'Jardin transformé selon mes souhaits. Travail soigné et conseils précieux pour l\'entretien.',
        reviewTitle: 'Transformation réussie du jardin',
        clientName: 'Fatima Ndiaye',
        clientCompanyName: 'Salon de beauté Ndiaye',
        providerName: 'Jardins & Paysages', // ✅ AJOUT
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        qualityRating: 4,
        punctualityRating: 5,
        valueRating: 5,
      ),
    ];
  }

  // Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}