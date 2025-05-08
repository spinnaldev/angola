import 'package:flutter/material.dart';
import '../core/models/quote_request.dart';
import '../core/services/quote_service.dart';

class QuoteProvider with ChangeNotifier {
  final QuoteService _quoteService;
  List<QuoteRequest> _quoteRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  QuoteProvider(this._quoteService);

  List<QuoteRequest> get quoteRequests => _quoteRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Créer une nouvelle demande de devis
  Future<bool> createQuoteRequest(
    int providerId,
    String subject,
    double budget,
    String description
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final quoteRequest = QuoteRequest(
        clientId: 0, // Sera remplacé par l'API
        providerId: providerId,
        subject: subject,
        budget: budget,
        description: description,
      );
      
      await _quoteService.createQuoteRequest(quoteRequest);
      
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

  // Récupérer les demandes de devis de l'utilisateur
  Future<void> fetchUserQuoteRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quoteRequests = await _quoteService.getUserQuoteRequests();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Mettre à jour le statut d'une demande de devis (pour les prestataires)
  Future<bool> updateQuoteRequestStatus(int quoteRequestId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _quoteService.updateQuoteRequestStatus(quoteRequestId, status);
      
      // Mettre à jour la liste locale
      final index = _quoteRequests.indexWhere((q) => q.id == quoteRequestId);
      if (index != -1) {
        // Créer une nouvelle liste pour déclencher les notifications
        final updatedRequests = List<QuoteRequest>.from(_quoteRequests);
        
        // Mettre à jour le statut de l'élément
        final updatedRequest = QuoteRequest(
          id: _quoteRequests[index].id,
          clientId: _quoteRequests[index].clientId,
          providerId: _quoteRequests[index].providerId,
          subject: _quoteRequests[index].subject,
          budget: _quoteRequests[index].budget,
          description: _quoteRequests[index].description,
          status: status,
          createdAt: _quoteRequests[index].createdAt,
        );
        
        updatedRequests[index] = updatedRequest;
        _quoteRequests = updatedRequests;
      }
      
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

  // Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}