import 'dart:convert';
import 'package:flutter/material.dart';

class VerificationInfo {
  final String type; // 'phone', 'documents', 'none'
  final String status; // 'not_started', 'pending', 'verified', 'rejected'
  final bool isVerified;
  
  // Pour vérification téléphone
  final String? phoneNumber;
  
  // Pour vérification documents
  final bool? isBusiness;
  final String? documentType;
  final String? rejectionReason;
  
  // Dates communes
  final DateTime? submittedAt;
  final DateTime? verifiedAt;

  VerificationInfo({
    required this.type,
    required this.status,
    required this.isVerified,
    this.phoneNumber,
    this.isBusiness,
    this.documentType,
    this.rejectionReason,
    this.submittedAt,
    this.verifiedAt,
  });

  /// Obtient la couleur du badge selon le statut
  Color get statusColor {
    switch (status) {
      case 'verified':
        return const Color(0xFF4CAF50); // Vert
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'rejected':
        return const Color(0xFFF44336); // Rouge
      default:
        return const Color(0xFF9E9E9E); // Gris
    }
  }

  /// Obtient l'icône du badge selon le statut
  IconData get statusIcon {
    switch (status) {
      case 'verified':
        return type == 'phone' ? Icons.verified : Icons.verified_user;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      default:
        return type == 'phone' ? Icons.phone : Icons.assignment;
    }
  }

  /// Obtient le titre du statut
  String get statusTitle {
    switch (status) {
      case 'verified':
        return type == 'phone' ? 'Téléphone vérifié' : 'Profil vérifié';
      case 'pending':
        return 'Vérification en cours';
      case 'rejected':
        return 'Vérification rejetée';
      default:
        return type == 'phone' ? 'Téléphone non vérifié' : 'Profil non vérifié';
    }
  }

  /// Obtient la description du statut
  String get statusDescription {
    switch (status) {
      case 'verified':
        return type == 'phone' 
            ? 'Votre numéro de téléphone est vérifié'
            : 'Votre profil prestataire est vérifié';
      case 'pending':
        return 'Votre demande de vérification est en cours d\'examen';
      case 'rejected':
        return 'Votre demande a été rejetée. ${rejectionReason ?? "Contactez le support."}';
      default:
        return type == 'phone'
            ? 'Vous devez vérifier votre numéro de téléphone'
            : 'Vous devez vérifier votre profil prestataire';
    }
  }

  /// Obtient le texte du bouton d'action
  String get actionButtonText {
    switch (status) {
      case 'rejected':
        return 'Soumettre de nouveaux documents';
      case 'pending':
        return 'Voir le statut';
      default:
        return type == 'phone' ? 'Vérifier mon téléphone' : 'Vérifier mon profil';
    }
  }
}