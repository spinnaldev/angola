
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/verification_guard_service.dart';
import '../core/models/verification_result.dart';
import '../core/models/user.dart';

class VerificationGuardProvider with ChangeNotifier {
  Map<String, VerificationResult> _cachedResults = {};
  
  /// Vérifier si une action est autorisée (avec cache)
  VerificationResult checkAccess(User? user, String actionDescription) {
    final cacheKey = '${user?.id}_$actionDescription';
    
    // Utiliser le cache si disponible et récent
    if (_cachedResults.containsKey(cacheKey)) {
      return _cachedResults[cacheKey]!;
    }
    
    // Calculer le résultat
    final result = VerificationGuardService.checkAccess(user, actionDescription);
    
    // Mettre en cache pendant 30 secondes
    _cachedResults[cacheKey] = result;
    Timer(const Duration(seconds: 30), () {
      _cachedResults.remove(cacheKey);
    });
    
    return result;
  }
  
  /// Vérifier rapidement si un utilisateur peut effectuer des actions
  bool canPerformActions(User? user) {
    return VerificationGuardService.canPerformActions(user);
  }
  
  /// Obtenir le type de vérification requis
  String getRequiredVerificationType(User? user) {
    return VerificationGuardService.getRequiredVerificationType(user);
  }
  
  /// Vider le cache (utile après changement de statut)
  void clearCache() {
    _cachedResults.clear();
    notifyListeners();
  }
}