import 'package:flutter/material.dart';
import '../core/models/provider_model.dart';
import '../core/services/api_service.dart';

class ProviderDetailProvider with ChangeNotifier {
  final ApiService _apiService;
  ProviderModel? _currentProvider;
  bool _isLoading = false;

  ProviderDetailProvider(this._apiService);

  ProviderModel? get currentProvider => _currentProvider;
  bool get isLoading => _isLoading;

  Future<void> fetchProviderDetails(int providerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedProvider = await _apiService.getProviderDetails(providerId);
      _currentProvider = fetchedProvider;
    } catch (error) {
      print('Error fetching provider details: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProviderByServiceId(int serviceId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedProvider = await _apiService.getProviderByServiceId(serviceId);
      _currentProvider = fetchedProvider;
    } catch (error) {
      print('Error fetching provider by service: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}