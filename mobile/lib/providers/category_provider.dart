// lib/providers/category_provider.dart
import 'package:flutter/material.dart';
import '../core/models/category.dart';
import '../core/services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Category> _categories = [];
  bool _isLoading = false;

  CategoryProvider(this._apiService);

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedCategories = await _apiService.getCategories();
      _categories = fetchedCategories;
    } catch (error) {
      print('Error fetching categories: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
