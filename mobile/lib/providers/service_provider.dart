import 'package:flutter/material.dart';
import '../core/models/service.dart';
import '../core/services/api_service.dart';

class ServiceProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Service> _services = [];
  Service? _currentService;
  bool _isLoading = false;

  ServiceProvider(this._apiService);

  List<Service> get services => _services;
  Service? get currentService => _currentService;
  bool get isLoading => _isLoading;

  Future<void> fetchServicesByCategory(int categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedServices = await _apiService.getServicesByCategory(categoryId);
      _services = fetchedServices;
    } catch (error) {
      print('Error fetching services by category: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchServicesBySubcategory(int subcategoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedServices = await _apiService.getServicesBySubcategory(subcategoryId);
      _services = fetchedServices;
    } catch (error) {
      print('Error fetching services by subcategory: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchServiceDetails(int serviceId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedService = await _apiService.getServiceDetails(serviceId);
      _currentService = fetchedService;
    } catch (error) {
      print('Error fetching service details: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}