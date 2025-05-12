// lib/providers/provider_verification_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/provider_verification.dart';
import '../core/services/provider_verification_service.dart';

class ProviderVerificationProvider with ChangeNotifier {
  final ProviderVerificationService _verificationService;
  ProviderVerification? _verification;
  bool _isLoading = false;
  String? _errorMessage;

  ProviderVerificationProvider(this._verificationService);

  ProviderVerification? get verification => _verification;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Vérifier si le prestataire est vérifié
  bool get isVerified => _verification?.isVerified ?? false;
  
  // Vérifier si le prestataire est une entreprise
  bool get isBusiness => _verification?.isBusiness ?? false;
  
  // Obtenir le statut de vérification
  String get verificationStatus => _verification?.verificationStatus ?? 'pending';

  // Récupérer les informations de vérification du prestataire
  Future<void> fetchVerificationInfo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _verification = await _verificationService.getProviderVerification();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Soumettre les informations de vérification pour une entreprise
  Future<bool> submitBusinessVerification(
    String businessName,
    String businessNif,
    String businessRegistrationNumber,
    File? registrationDoc,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _verification = await _verificationService.submitBusinessVerification(
        businessName,
        businessNif,
        businessRegistrationNumber,
        registrationDoc,
      );
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      return false;
    }
  
  }

  // Soumettre les informations de vérification pour un particulier
  Future<bool> submitIndividualVerification(
    File idCardFront,
    File idCardBack,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _verification = await _verificationService.submitIndividualVerification(
        idCardFront,
        idCardBack,
      );
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      return false;
    }
  }

  // Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}