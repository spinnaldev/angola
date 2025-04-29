import 'package:flutter/material.dart';

class FilterProvider with ChangeNotifier {
  int _selectedRating = 0;
  RangeValues _priceRange = const RangeValues(0, 200);
  String _providerType = '';
  String _location = '';

  int get selectedRating => _selectedRating;
  RangeValues get priceRange => _priceRange;
  String get providerType => _providerType;
  String get location => _location;

  void setRating(int rating) {
    if (_selectedRating == rating) {
      _selectedRating = 0; // Désélectionner
    } else {
      _selectedRating = rating;
    }
    notifyListeners();
  }

  void setPriceRange(RangeValues values) {
    _priceRange = values;
    notifyListeners();
  }

  void setProviderType(String type) {
    if (_providerType == type) {
      _providerType = ''; // Désélectionner
    } else {
      _providerType = type;
    }
    notifyListeners();
  }

  void setLocation(String location) {
    _location = location;
    notifyListeners();
  }

  void resetFilters() {
    _selectedRating = 0;
    _priceRange = const RangeValues(0, 200);
    _providerType = '';
    _location = '';
    notifyListeners();
  }
}