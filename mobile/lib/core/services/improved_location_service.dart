// lib/core/services/improved_location_service.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

enum LocationStatus {
  initial,
  loading,
  success,
  error,
  permissionDenied,
  serviceDisabled,
  timeout
}

class ImprovedLocationService with ChangeNotifier {
  // État de la localisation
  Position? _currentPosition;
  Position? _lastKnownPosition;
  String _errorMessage = '';
  LocationStatus _status = LocationStatus.initial;
  String _currentLocationName = '';
  
  // Configuration
  static const Duration _timeoutDuration = Duration(seconds: 15);
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  static const int _minimumDistanceFilter = 100; // mètres
  
  // Cache timestamp
  DateTime? _lastPositionUpdate;
  
  // Stream pour les updates en temps réel
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // Getters
  Position? get currentPosition => _currentPosition;
  Position? get lastKnownPosition => _lastKnownPosition;
  String get errorMessage => _errorMessage;
  LocationStatus get status => _status;
  String get currentLocationName => _currentLocationName;
  bool get isLoading => _status == LocationStatus.loading;
  bool get hasValidPosition => _currentPosition != null;
  bool get isPositionCacheValid => _lastPositionUpdate != null && 
      DateTime.now().difference(_lastPositionUpdate!) < _cacheValidityDuration;

  // Méthode principale pour obtenir la localisation
  Future<bool> getCurrentLocation({bool forceRefresh = false}) async {
    // Si on a une position valide en cache et qu'on ne force pas le refresh
    if (!forceRefresh && hasValidPosition && isPositionCacheValid) {
      print('📍 Position en cache valide utilisée');
      return true;
    }

    _updateStatus(LocationStatus.loading);
    print('📍 Récupération de la position GPS...');

    try {
      // 1. Vérifier les services de localisation
      if (!await _checkLocationServices()) {
        return false;
      }

      // 2. Vérifier et demander les permissions
      if (!await _handleLocationPermissions()) {
        return false;
      }

      // 3. Récupérer la position avec retry logic
      Position? position = await _getPositionWithRetry();
      
      if (position != null) {
        await _updatePosition(position);
        _updateStatus(LocationStatus.success);
        print('✅ Position GPS récupérée avec succès');
        return true;
      } else {
        _setError('Impossible de récupérer la position GPS', LocationStatus.error);
        return false;
      }

    } catch (e) {
      _setError('Erreur lors de la récupération de la position: $e', LocationStatus.error);
      return false;
    }
  }

  // Démarrer le suivi de position en temps réel
  Future<void> startLocationTracking() async {
    print('📍 Démarrage du suivi de position...');
    
    if (_positionStreamSubscription != null) {
      await stopLocationTracking();
    }

    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _minimumDistanceFilter,
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings
      ).listen(
        (Position position) async {
          await _updatePosition(position);
          print('📍 Position mise à jour automatiquement');
        },
        onError: (error) {
          print('❌ Erreur lors du suivi de position: $error');
          _setError(error.toString(), LocationStatus.error);
        },
      );
    } catch (e) {
      print('❌ Erreur lors du démarrage du suivi: $e');
    }
  }

  // Arrêter le suivi de position
  Future<void> stopLocationTracking() async {
    print('📍 Arrêt du suivi de position');
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  // Vérification des services de localisation
  Future<bool> _checkLocationServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setError(
        'Les services de localisation sont désactivés. Veuillez les activer dans les paramètres.',
        LocationStatus.serviceDisabled
      );
      return false;
    }
    return true;
  }

  // Gestion complète des permissions
  Future<bool> _handleLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setError(
          'Permission de localisation refusée. L\'application a besoin de cette permission pour fonctionner correctement.',
          LocationStatus.permissionDenied
        );
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _setError(
        'La permission de localisation est définitivement refusée. Veuillez l\'activer manuellement dans les paramètres de l\'application.',
        LocationStatus.permissionDenied
      );
      return false;
    }
    
    return true;
  }

  // Récupération de position avec logique de retry
  Future<Position?> _getPositionWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('📍 Tentative $attempt/$maxRetries...');
        
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: _timeoutDuration,
        );
        
        return position;
        
      } on TimeoutException {
        print('⏰ Timeout lors de la tentative $attempt');
        if (attempt == maxRetries) {
          _setError('Timeout: Impossible de récupérer la position dans le délai imparti', LocationStatus.timeout);
        }
      } catch (e) {
        print('❌ Erreur lors de la tentative $attempt: $e');
        if (attempt == maxRetries) {
          _setError('Erreur après $maxRetries tentatives: $e', LocationStatus.error);
        }
      }
      
      // Attendre avant le prochain retry
      if (attempt < maxRetries) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    return null;
  }

  // Mise à jour de la position avec géocodage
  Future<void> _updatePosition(Position position) async {
    _currentPosition = position;
    _lastKnownPosition = position;
    _lastPositionUpdate = DateTime.now();
    
    // Géocodage inverse pour obtenir le nom du lieu
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentLocationName = _buildLocationName(place);
      }
    } catch (e) {
      print('❌ Erreur lors du géocodage inverse: $e');
      _currentLocationName = 'Position actuelle';
    }
    
    notifyListeners();
  }

  // Construction du nom de localisation
  String _buildLocationName(Placemark place) {
    List<String> parts = [];
    
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Position actuelle';
  }

  // Calcul de distance optimisé
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000; // en km
  }

  // Distance depuis la position actuelle
  double getDistanceFromCurrent(double lat, double lng) {
    if (_currentPosition == null) return -1;
    
    return calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
  }

  // Vérifier si un point est dans un rayon donné
  bool isWithinRadius(double lat, double lng, double radiusKm) {
    double distance = getDistanceFromCurrent(lat, lng);
    return distance != -1 && distance <= radiusKm;
  }

  // Obtenir la dernière position connue même si pas récente
  Position? getLastKnownPosition() {
    return _lastKnownPosition ?? _currentPosition;
  }

  // Mise à jour du statut
  void _updateStatus(LocationStatus newStatus) {
    _status = newStatus;
    if (newStatus != LocationStatus.error) {
      _errorMessage = '';
    }
    notifyListeners();
  }

  // Gestion d'erreur
  void _setError(String message, LocationStatus status) {
    _errorMessage = message;
    _status = status;
    print('❌ Erreur de localisation: $message');
    notifyListeners();
  }

  // Réinitialiser les erreurs
  void clearError() {
    _errorMessage = '';
    if (_status == LocationStatus.error || 
        _status == LocationStatus.permissionDenied || 
        _status == LocationStatus.serviceDisabled ||
        _status == LocationStatus.timeout) {
      _status = LocationStatus.initial;
    }
    notifyListeners();
  }

  // Ouvrir les paramètres système
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Nettoyage des ressources
  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }

  // Méthode utilitaire pour obtenir une position de fallback
  ({double latitude, double longitude}) getDefaultPosition() {
    // Position par défaut: Cotonou, Bénin
    return (latitude: 6.3728, longitude: 2.3905);
  }

  // Méthode pour forcer un refresh de la position
  Future<bool> refreshLocation() async {
    return await getCurrentLocation(forceRefresh: true);
  }
}

// Extension pour faciliter l'utilisation
extension LocationServiceExtension on ImprovedLocationService {
  // Obtenir la position Google Maps ou la position par défaut
  getCurrentOrDefaultPosition() {
    if (hasValidPosition) {
      return (latitude: currentPosition!.latitude, longitude: currentPosition!.longitude);
    }
    return getDefaultPosition();
  }
}

// // Classe utilitaire pour les coordonnées
// class LatLng {
//   final double latitude;
//   final double longitude;

//   const LatLng(this.latitude, this.longitude);

//   @override
//   String toString() => 'LatLng($latitude, $longitude)';
  
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is LatLng &&
//           runtimeType == other.runtimeType &&
//           latitude == other.latitude &&
//           longitude == other.longitude;

//   @override
//   int get hashCode => latitude.hashCode ^ longitude.hashCode;
// }