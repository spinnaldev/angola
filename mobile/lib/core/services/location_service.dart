// lib/core/services/location_service.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService with ChangeNotifier {
  Position? _currentPosition;
  String _errorMessage = '';
  bool _isLoading = false;

  Position? get currentPosition => _currentPosition;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<bool> requestLocationPermission() async {
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        return true;
      } else {
        _errorMessage = 'Permission de localisation refusée';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la demande de permission: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Vérifier si la permission de localisation est accordée
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Récupérer la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = position;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la récupération de la position: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkLocationServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Les services de localisation sont désactivés';
      notifyListeners();
      return false;
    }
    return true;
  }

  double getDistanceInKm(double lat, double lng) {
    if (_currentPosition == null) return -1;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    ) / 1000; // Convertir en kilomètres
  }
}