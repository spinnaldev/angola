// mobile/lib/providers/client_verification_provider.dart
// CRÉEZ ce nouveau fichier

import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/client_verification.dart';
import '../core/services/client_verification_service.dart';

class ClientVerificationProvider with ChangeNotifier {
  final ClientVerificationService _verificationService;
  
  ClientVerification? _verification;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerified = false;
  
  ClientVerificationProvider(this._verificationService);
  
  // Getters
  ClientVerification? get verification => _verification;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isVerified => _isVerified;
  bool get hasVerification => _verification != null;
  bool get isPending => _verification?.isPending ?? false;
  bool get isRejected => _verification?.isRejected ?? false;
  bool get canSubmit => _verification?.canSubmit ?? true;
  
  // Setters privés
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  /// Récupérer le statut de vérification
  Future<void> fetchVerificationStatus() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final statusData = await _verificationService.getVerificationStatus();
      
      if (statusData['has_verification'] == true && statusData['verification'] != null) {
        _verification = ClientVerification.fromJson(statusData['verification']);
        _isVerified = statusData['is_verified'] ?? false;
      } else {
        _verification = null;
        _isVerified = false;
      }
      
      print('✅ Statut vérification client récupéré : ${_verification?.verificationStatus ?? "none"}');
    } catch (e) {
      _errorMessage = 'Erreur lors de la récupération du statut : $e';
      print('❌ Erreur récupération statut : $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Soumettre une vérification avec carte d'identité
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
      print('❌ Erreur soumission carte ID : $_errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Soumettre une vérification avec passeport
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
      print('❌ Erreur soumission passeport : $_errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Nettoyer les données (utile lors de la déconnexion)
  void clear() {
    _verification = null;
    _isVerified = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Réinitialiser l'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Obtenir un message d'erreur lisible
  String _getReadableError(String error) {
    if (error.contains('SocketException') || error.contains('NetworkException')) {
      return 'Erreur de connexion. Vérifiez votre connexion internet.';
    }
    if (error.contains('TimeoutException')) {
      return 'La requête a expiré. Veuillez réessayer.';
    }
    if (error.contains('403')) {
      return 'Vous n\'avez pas les permissions nécessaires.';
    }
    if (error.contains('404')) {
      return 'Service non trouvé.';
    }
    if (error.contains('500')) {
      return 'Erreur serveur. Veuillez réessayer plus tard.';
    }
    
    // Extraire le message d'erreur si c'est une Exception
    if (error.startsWith('Exception:')) {
      return error.replaceFirst('Exception:', '').trim();
    }
    
    return error;
  }
  
  /// Obtenir des conseils pour améliorer les photos
  List<String> getPhotoTips() {
    return [
      '📸 Prenez les photos dans un endroit bien éclairé',
      '✨ Assurez-vous que tous les textes sont lisibles',
      '🚫 Évitez les reflets et les ombres',
      '📏 Cadrez bien le document dans son intégralité',
      '💾 Taille maximale: 5 MB par fichier',
    ];
  }
  
  /// Vérifier si un fichier est valide (taille, format)
  Future<bool> isFileValid(File file) async {
    try {
      final fileSize = await file.length();
      const maxSize = 5 * 1024 * 1024; // 5 MB
      
      if (fileSize > maxSize) {
        _errorMessage = 'Le fichier est trop volumineux (maximum 5 MB)';
        notifyListeners();
        return false;
      }
      
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la validation du fichier';
      notifyListeners();
      return false;
    }
  }
}