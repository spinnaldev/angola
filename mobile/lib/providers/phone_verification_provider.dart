
import 'package:flutter/material.dart';

import '../core/models/phone_verification.dart';
import '../core/services/phone_verification_service.dart';
import 'dart:async';

class PhoneVerificationProvider with ChangeNotifier {
  final PhoneVerificationService _verificationService;
  
  PhoneVerification? _verification;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _countdownTimer;

  PhoneVerificationProvider(this._verificationService);

  // ================================================================
  // GETTERS
  // ================================================================
  
  PhoneVerification? get verification => _verification;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// Vérifier si le téléphone est vérifié
  bool get isVerified => _verification?.isVerified ?? false;
  
  /// Vérifier si la vérification est en cours
  bool get isPending => _verification?.isPending ?? false;
  
  /// Vérifier si la vérification a échoué
  bool get isFailed => _verification?.isFailed ?? false;
  
  /// Vérifier si la vérification est expirée
  bool get isExpired => _verification?.isExpired ?? false;
  
  /// Obtenir le temps restant formaté
  String get formattedTimeRemaining => _verification?.formattedTimeRemaining ?? '00:00';
  
  /// Vérifier si on peut renvoyer le code
  bool get canResend => _verification?.canResend ?? false;
  
  /// Obtenir les tentatives restantes
  int get attemptsRemaining => _verification?.attemptsRemaining ?? 0;
  
  /// Obtenir le numéro de téléphone
  String get phoneNumber => _verification?.phoneNumber ?? '';
  
  /// Obtenir le statut pour affichage
  String get statusDisplayText {
    if (_verification == null) {
      return 'Non vérifié';
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
      return Icons.phone;
    }
    return _verification!.statusIcon;
  }
  
  /// Obtenir le message d'instruction
  String get instructionMessage {
    if (_verification == null) {
      return 'Nous allons envoyer un code de vérification à votre numéro.';
    }
    return _verification!.instructionMessage;
  }

  // ================================================================
  // MÉTHODES PRINCIPALES
  // ================================================================
  
  /// Récupérer le statut de vérification
  Future<void> fetchVerificationStatus() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _verification = await _verificationService.getMyVerificationStatus();
      print('📞 Statut téléphone récupéré: ${_verification?.status ?? 'Aucune vérification'}');
      
      // Démarrer le timer si une vérification est en cours
      if (_verification != null && _verification!.isPending) {
        _startCountdownTimer();
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Erreur fetch status téléphone: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Envoyer un code de vérification
  Future<bool> sendVerificationCode(String phoneNumber) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _verification = await _verificationService.sendVerificationCode(phoneNumber);
      print('✅ Code envoyé à $phoneNumber');
      
      // Démarrer le timer de compte à rebours
      _startCountdownTimer();
      
      return true;
    } catch (e) {
      _errorMessage = _getReadableError(e.toString());
      print('❌ Erreur envoi code: $_errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Vérifier le code SMS
  Future<bool> verifyCode(String code) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _verification = await _verificationService.verifyCode(code);
      print('✅ Code vérifié avec succès');
      
      // Arrêter le timer si la vérification est réussie
      if (_verification!.isVerified) {
        _stopCountdownTimer();
      }
      
      return _verification!.isVerified;
    } catch (e) {
      _errorMessage = _getReadableError(e.toString());
      print('❌ Erreur vérification code: $_errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Renvoyer le code de vérification
  Future<bool> resendCode() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _verification = await _verificationService.resendCode();
      print('✅ Nouveau code envoyé');
      
      // Redémarrer le timer
      _startCountdownTimer();
      
      return true;
    } catch (e) {
      _errorMessage = _getReadableError(e.toString());
      print('❌ Erreur renvoi code: $_errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // GESTION DU TIMER
  // ================================================================
  
  void _startCountdownTimer() {
    _stopCountdownTimer(); // Arrêter le timer existant
    
    if (_verification != null && _verification!.timeRemaining > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_verification != null) {
          final newTimeRemaining = _verification!.timeRemaining - 1;
          _verification = _verification!.copyWith(
            timeRemaining: newTimeRemaining > 0 ? newTimeRemaining : 0,
            canResend: newTimeRemaining <= 0,
          );
          
          notifyListeners();
          
          // Arrêter le timer quand le temps est écoulé
          if (newTimeRemaining <= 0) {
            _stopCountdownTimer();
          }
        } else {
          _stopCountdownTimer();
        }
      });
    }
  }
  
  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
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
    if (error.contains('Code incorrect')) {
      return 'Code incorrect. Vérifiez le code reçu par SMS.';
    } else if (error.contains('Code expiré')) {
      return 'Le code a expiré. Demandez un nouveau code.';
    } else if (error.contains('Trop de tentatives')) {
      return 'Trop de tentatives incorrectes. Demandez un nouveau code.';
    } else if (error.contains('attendre')) {
      return 'Vous devez attendre avant de demander un nouveau code.';
    } else if (error.contains('Format invalide')) {
      return 'Format de numéro de téléphone invalide.';
    } else if (error.contains('Network')) {
      return 'Erreur de connexion. Vérifiez votre connexion internet.';
    } else if (error.contains('500')) {
      return 'Erreur serveur temporaire. Veuillez réessayer plus tard.';
    }
    
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
  
  @override
  void dispose() {
    _stopCountdownTimer();
    super.dispose();
  }
}
