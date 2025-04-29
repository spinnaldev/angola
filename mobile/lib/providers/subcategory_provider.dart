import 'package:flutter/material.dart';
import '../core/models/subcategory.dart';
import '../core/services/api_service.dart';

class SubcategoryProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Subcategory> _subcategories = [];
  bool _isLoading = false;

  SubcategoryProvider(this._apiService);

  List<Subcategory> get subcategories => _subcategories;
  bool get isLoading => _isLoading;

  Future<void> fetchSubcategories(int categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedSubcategories = await _apiService.getSubcategories(categoryId);
      _subcategories = fetchedSubcategories;
    } catch (error) {
      print('Error fetching subcategories: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}