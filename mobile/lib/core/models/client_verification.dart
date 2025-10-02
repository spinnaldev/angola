// mobile/lib/core/models/client_verification.dart
// CRÉEZ ce nouveau fichier

import 'package:flutter/material.dart';

class ClientVerification {
  final int? id;
  final int userId;
  final String documentType; // 'id_card' ou 'passport'
  final String? idCardFrontUrl;
  final String? idCardBackUrl;
  final String? passportImageUrl;
  final String verificationStatus; // 'not_started', 'pending', 'verified', 'rejected'
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? adminNotes;
  final bool canBeModified;
  final List<String> documentsProvided;
  final int verificationProgress;
  final int? daysSinceSubmission;

  ClientVerification({
    this.id,
    required this.userId,
    required this.documentType,
    this.idCardFrontUrl,
    this.idCardBackUrl,
    this.passportImageUrl,
    required this.verificationStatus,
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
    this.adminNotes,
    required this.canBeModified,
    required this.documentsProvided,
    required this.verificationProgress,
    this.daysSinceSubmission,
  });

  factory ClientVerification.fromJson(Map<String, dynamic> json) {
    return ClientVerification(
      id: json['id'],
      userId: json['user'],
      documentType: json['document_type'] ?? 'id_card',
      idCardFrontUrl: json['id_card_front'],
      idCardBackUrl: json['id_card_back'],
      passportImageUrl: json['passport_image'],
      verificationStatus: json['verification_status'] ?? 'not_started',
      submittedAt: json['submitted_at'] != null 
          ? DateTime.parse(json['submitted_at']) 
          : null,
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
      rejectionReason: json['rejection_reason'],
      adminNotes: json['admin_notes'],
      canBeModified: json['can_be_modified'] ?? true,
      documentsProvided: List<String>.from(json['documents_provided'] ?? []),
      verificationProgress: json['verification_progress'] ?? 0,
      daysSinceSubmission: json['days_since_submission'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user': userId,
      'document_type': documentType,
      if (idCardFrontUrl != null) 'id_card_front': idCardFrontUrl,
      if (idCardBackUrl != null) 'id_card_back': idCardBackUrl,
      if (passportImageUrl != null) 'passport_image': passportImageUrl,
      'verification_status': verificationStatus,
    };
  }

  // ============================================================
  // GETTERS UTILITAIRES
  // ============================================================

  bool get isNotStarted => verificationStatus == 'not_started';
  bool get isPending => verificationStatus == 'pending';
  bool get isVerified => verificationStatus == 'verified';
  bool get isRejected => verificationStatus == 'rejected';

  bool get canSubmit => canBeModified;

  String get statusText {
    switch (verificationStatus) {
      case 'not_started':
        return 'Non commencé';
      case 'pending':
        return 'En attente';
      case 'verified':
        return 'Vérifié';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  Color get statusColor {
    switch (verificationStatus) {
      case 'not_started':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (verificationStatus) {
      case 'not_started':
        return Icons.info_outline;
      case 'pending':
        return Icons.pending_outlined;
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  /// Documents manquants
  List<String> get missingDocuments {
    List<String> missing = [];

    if (documentType == 'id_card') {
      if (idCardFrontUrl == null) {
        missing.add('Carte d\'identité (recto)');
      }
      if (idCardBackUrl == null) {
        missing.add('Carte d\'identité (verso)');
      }
    } else if (documentType == 'passport') {
      if (passportImageUrl == null) {
        missing.add('Passeport');
      }
    }

    return missing;
  }

  /// Vérifie si tous les documents requis sont fournis
  bool get hasAllRequiredDocuments => missingDocuments.isEmpty;

  /// Obtient le message d'instruction selon l'état
  String get instructionMessage {
    if (isRejected) {
      return 'Votre vérification a été rejetée. Veuillez soumettre de nouveaux documents.';
    } else if (isPending) {
      return 'Votre demande de vérification est en cours d\'examen.';
    } else if (isVerified) {
      return 'Votre compte est vérifié ! Vous pouvez maintenant utiliser toutes les fonctionnalités.';
    } else {
      return 'Complétez votre vérification pour accéder à toutes les fonctionnalités.';
    }
  }

  /// Message détaillé avec nombre de jours
  String get detailedMessage {
    if (isPending && daysSinceSubmission != null) {
      return 'Votre demande est en cours d\'examen depuis $daysSinceSubmission jour(s).';
    }
    return instructionMessage;
  }

  ClientVerification copyWith({
    int? id,
    int? userId,
    String? documentType,
    String? idCardFrontUrl,
    String? idCardBackUrl,
    String? passportImageUrl,
    String? verificationStatus,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
    String? adminNotes,
    bool? canBeModified,
    List<String>? documentsProvided,
    int? verificationProgress,
    int? daysSinceSubmission,
  }) {
    return ClientVerification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      idCardFrontUrl: idCardFrontUrl ?? this.idCardFrontUrl,
      idCardBackUrl: idCardBackUrl ?? this.idCardBackUrl,
      passportImageUrl: passportImageUrl ?? this.passportImageUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      canBeModified: canBeModified ?? this.canBeModified,
      documentsProvided: documentsProvided ?? this.documentsProvided,
      verificationProgress: verificationProgress ?? this.verificationProgress,
      daysSinceSubmission: daysSinceSubmission ?? this.daysSinceSubmission,
    );
  }

  @override
  String toString() {
    return 'ClientVerification{id: $id, status: $verificationStatus, documentType: $documentType}';
  }
}