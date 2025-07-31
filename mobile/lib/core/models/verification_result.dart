
import 'package:flutter/material.dart';

class VerificationResult {
  final bool canAccess;
  final String? title;
  final String? message;
  final String? redirectRoute;
  final String? buttonText;
  final String? verificationType;

  VerificationResult({
    required this.canAccess,
    this.title,
    this.message,
    this.redirectRoute,
    this.buttonText,
    this.verificationType,
  });

  factory VerificationResult.allowed() {
    return VerificationResult(canAccess: true);
  }

  factory VerificationResult.blocked({
    required String title,
    required String message,
    String? redirectRoute,
    String? buttonText,
    String? verificationType,
  }) {
    return VerificationResult(
      canAccess: false,
      title: title,
      message: message,
      redirectRoute: redirectRoute,
      buttonText: buttonText,
      verificationType: verificationType,
    );
  }

  /// Obtient la couleur selon le type de vérification
  Color get iconColor {
    switch (verificationType) {
      case 'phone':
        return Colors.blue;
      case 'documents':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Obtient l'icône selon le type de vérification
  IconData get icon {
    switch (verificationType) {
      case 'phone':
        return Icons.phone_android;
      case 'documents':
        return Icons.verified_user;
      default:
        return Icons.security;
    }
  }
}