// lib/providers/provider_list_provider.dart
import 'package:flutter/material.dart';
import '../core/models/provider_model.dart';
import '../core/services/api_service.dart';

class ProviderListProvider with ChangeNotifier {
  final ApiService _apiService;
  List<ProviderModel> _providers = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  ProviderListProvider(this._apiService);

  List<ProviderModel> get providers => _providers;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  Future<void> fetchProviders() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final fetchedProviders = await _apiService.getProviders();
      _providers = fetchedProviders;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchProvidersByCategory(int categoryId) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final fetchedProviders = await _apiService.getProvidersByCategory(categoryId);
      _providers = fetchedProviders;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchProvidersBySubcategory(int subcategoryId) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final fetchedProviders = await _apiService.getProvidersBySubcategory(subcategoryId);
      _providers = fetchedProviders;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> fetchNearbyProviders(double latitude, double longitude, {double radius = 10.0}) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final fetchedProviders = await _apiService.getNearbyProviders(latitude, longitude, radius: radius);
      _providers = fetchedProviders;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  ProviderModel? getProviderById(int id) {
    try {
      return _providers.firstWhere((provider) => provider.id == id);
    } catch (e) {
      return null;
    }
  }

  // Méthode pour filtrer les prestataires par notation
  void filterByRating(int minRating) {
    if (minRating <= 0) {
      // Ne pas filtrer
      return;
    }
    
    // Filtrer les prestataires qui ont une note supérieure ou égale à minRating
    _providers = _providers.where((provider) => provider.rating >= minRating).toList();
    notifyListeners();
  }

  // Méthode pour filtrer les prestataires par type (entreprise ou freelance)
  void filterByType(String type) {
    if (type.isEmpty) {
      // Ne pas filtrer
      return;
    }
    
    // Filtrer les prestataires par type
    _providers = _providers.where((provider) => provider.businessType.toLowerCase() == type.toLowerCase()).toList();
    notifyListeners();
  }

  // Méthode pour filtrer les prestataires par localisation
  void filterByLocation(String location) {
    if (location.isEmpty) {
      // Ne pas filtrer
      return;
    }
    
    // Filtrer les prestataires par localisation
    _providers = _providers.where((provider) => 
      provider.address != null && 
      provider.address!.toLowerCase().contains(location.toLowerCase())
    ).toList();
    notifyListeners();
  }

  // Réinitialiser les filtres
  Future<void> resetFilters({int? categoryId}) async {
    // Recharger tous les prestataires ou ceux de la catégorie spécifiée
    if (categoryId != null) {
      await fetchProvidersByCategory(categoryId);
    } else {
      await fetchProviders();
    }
  }
}