// lib/providers/location_provider.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _permissionGranted = false;

  Position? get currentPosition => _currentPosition;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get permissionGranted => _permissionGranted;

  // Vérifier si les services de localisation sont activés
  Future<bool> checkLocationServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Les services de localisation sont désactivés';
      notifyListeners();
      return false;
    }
    return true;
  }

  // Demander la permission de localisation
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Permission de localisation refusée';
          _permissionGranted = false;
          notifyListeners();
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Permission de localisation refusée définitivement. Veuillez l\'activer dans les paramètres.';
        _permissionGranted = false;
        notifyListeners();
        return false;
      }
      
      _permissionGranted = true;
      _errorMessage = '';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la demande de permission: $e';
      _permissionGranted = false;
      notifyListeners();
      return false;
    }
  }

  // Obtenir la position actuelle
  Future<bool> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Vérifier les services de localisation
      bool serviceEnabled = await checkLocationServices();
      if (!serviceEnabled) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Vérifier/demander la permission
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Récupérer la position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
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

  // Calculer la distance entre deux points
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000; // en km
  }

  // Calculer la distance depuis la position actuelle
  double getDistanceFromCurrent(double lat, double lng) {
    if (_currentPosition == null) return -1;
    
    return calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
  }

  // Réinitialiser les erreurs
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Ouvrir les paramètres de localisation
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Ouvrir les paramètres de l'application
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}