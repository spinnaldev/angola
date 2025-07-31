
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/provider_verification.dart';
import '../core/services/provider_verification_service.dart';

class ProviderVerificationProvider with ChangeNotifier {
  final ProviderVerificationService _verificationService;
  
  ProviderVerification? _verification;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _requirements;

  ProviderVerificationProvider(this._verificationService);

  // ================================================================
  // GETTERS
  // ================================================================
  
  ProviderVerification? get verification => _verification;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get requirements => _requirements;
  
  /// Vérifier si le prestataire est vérifié
  bool get isVerified => _verification?.isVerified ?? false;
  
  /// Vérifier si la vérification est en attente
  bool get isPending => _verification?.isPending ?? false;
  
  /// Vérifier si la vérification est rejetée
  bool get isRejected => _verification?.isRejected ?? false;
  
  /// Vérifier si aucune vérification n'a été commencée
  bool get isNotStarted => _verification == null || _verification!.verificationStatus == 'not_started';
  
  /// Obtenir le statut pour affichage
  String get statusDisplayText {
    if (_verification == null) {
      return 'Non commencé';
    }
    return _verification!.statusLabel;
  }
  
  /// Obtenir la couleur du statut
  Color get statusColor {
    if (_verification == null) {
      return Colors.grey;
    }
    return _verification!.statusColor;
  }
  
  /// Obtenir l'icône du statut
  IconData get statusIcon {
    if (_verification == null) {
      return Icons.assignment;
    }
    return _verification!.statusIcon;
  }
  
  /// Obtenir le message d'instruction
  String get instructionMessage {
    if (_verification == null) {
      return 'Complétez votre vérification pour accéder à toutes les fonctionnalités.';
    }
    return _verification!.instructionMessage;
  }
  
  /// Obtenir le pourcentage de progression
  int get progressPercentage => _verification?.verificationProgress ?? 0;
  
  /// Vérifier si la vérification peut être modifiée
  bool get canBeModified => _verification?.canBeModified ?? true;
  
  /// Obtenir les documents fournis
  List<String> get documentsProvided => _verification?.documentsProvided ?? [];
  
  /// Obtenir les documents manquants
  List<String> get missingDocuments => _verification?.missingDocuments ?? [];

  // ================================================================
  // MÉTHODES PRINCIPALES
  // ================================================================
  
  /// Récupérer le statut de vérification
  Future<void> fetchVerificationStatus() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _verification = await _verificationService.getMyVerificationStatus();
      print('📋 Statut récupéré: ${_verification?.verificationStatus ?? 'Aucune vérification'}');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Erreur fetch status: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Récupérer les exigences de vérification
  Future<void> fetchRequirements() async {
    try {
      _requirements = await _verificationService.getVerificationRequirements();
      notifyListeners();
    } catch (e) {
      print('❌ Erreur fetch requirements: $e');
      // Ne pas afficher l'erreur à l'utilisateur pour les exigences
    }
  }
  
  /// Soumettre une vérification d'entreprise
  Future<bool> submitBusinessVerification({
    required String businessName,
    String? businessNif,
    String? businessRegistrationNumber,
    required File idCardFront,
    required File idCardBack,
    File? businessRegistrationDoc,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _verification = await _verificationService.submitBusinessVerification(
        businessName: businessName,
        businessNif: businessNif,
        businessRegistrationNumber: businessRegistrationNumber,
        idCardFront: idCardFront,
        idCardBack: idCardBack,
        businessRegistrationDoc: businessRegistrationDoc,
      );
      
      print('✅ Vérification entreprise soumise avec succès');
      return true;
    } catch (e) {
      _errorMessage = _getReadableError(e.toString());
      print('❌ Erreur soumission entreprise: $_errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Soumettre une vérification individuelle avec carte d'identité
  Future<bool> submitIndividualVerificationWithId({
    required File idCardFront,
    required File idCardBack,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _verification = await _verificationService.submitIndividualVerificationWithId(
        idCardFront: idCardFront,
        idCardBack: idCardBack,
      );
      
      print('✅ Vérification carte ID soumise avec succès');
      return true;
    } catch (e) {
      _errorMessage = _getReadableError(e.toString());
      print('❌ Erreur soumission carte ID: $_errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Soumettre une vérification individuelle avec passeport
  Future<bool> submitIndividualVerificationWithPassport({
    required File passportImage,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _verification = await _verificationService.submitIndividualVerificationWithPassport(
        passportImage: passportImage,
      );
      
      print('✅ Vérification passeport soumise avec succès');
      return true;
    } catch (e) {
      _errorMessage = _getReadableError(e.toString());
      print('❌ Erreur soumission passeport: $_errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Renvoyer des documents après rejet
  Future<bool> resendDocuments({
    File? idCardFront,
    File? idCardBack,
    File? passportImage,
    File? businessRegistrationDoc,
    String? businessName,
    String? businessNif,
    String? businessRegistrationNumber,
  }) async {
    if (_verification?.id == null) {
      _errorMessage = 'Aucune vérification à modifier';
      return false;
    }
    
    _setLoading(true);
    _errorMessage = null;

    try {
      _verification = await _verificationService.resendDocuments(
        verificationId: _verification!.id!,
        idCardFront: idCardFront,
        idCardBack: idCardBack,
        passportImage: passportImage,
        businessRegistrationDoc: businessRegistrationDoc,
        businessName: businessName,
        businessNif: businessNif,
        businessRegistrationNumber: businessRegistrationNumber,
      );
      
      print('✅ Documents renvoyés avec succès');
      return true;
    } catch (e) {
      _errorMessage = _getReadableError(e.toString());
      print('❌ Erreur renvoi documents: $_errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // MÉTHODES UTILITAIRES
  // ================================================================
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  String _getReadableError(String error) {
    if (error.contains('Documents illisibles')) {
      return 'Les documents fournis ne sont pas lisibles. Veuillez prendre des photos plus nettes.';
    } else if (error.contains('Format non supporté')) {
      return 'Format de fichier non supporté. Utilisez JPG, PNG ou PDF.';
    } else if (error.contains('Fichier trop volumineux')) {
      return 'Le fichier est trop volumineux. Taille maximum : 5MB.';
    } else if (error.contains('Données manquantes')) {
      return 'Certaines informations obligatoires sont manquantes.';
    } else if (error.contains('Network')) {
      return 'Erreur de connexion. Vérifiez votre connexion internet.';
    } else if (error.contains('500')) {
      return 'Erreur serveur temporaire. Veuillez réessayer plus tard.';
    }
    
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}