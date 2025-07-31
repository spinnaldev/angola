import 'package:flutter/material.dart';

class ProviderVerification {
  final int? id;
  final int providerId;
  final bool isBusiness;
  final String? businessName;
  final String? businessNif;
  final String? businessRegistrationNumber;
  final String documentType; // 'id_card' ou 'passport'
  final String? idCardFrontUrl;
  final String? idCardBackUrl;
  final String? passportImageUrl;
  final String? businessRegistrationDocUrl;
  final String verificationStatus; // 'not_started', 'pending', 'verified', 'rejected'
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? adminNotes;
  final bool canBeModified;
  final List<String> documentsProvided;
  final int verificationProgress;
  final int? daysSinceSubmission;

  ProviderVerification({
    this.id,
    required this.providerId,
    required this.isBusiness,
    this.businessName,
    this.businessNif,
    this.businessRegistrationNumber,
    required this.documentType,
    this.idCardFrontUrl,
    this.idCardBackUrl,
    this.passportImageUrl,
    this.businessRegistrationDocUrl,
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

  factory ProviderVerification.fromJson(Map<String, dynamic> json) {
    return ProviderVerification(
      id: json['id'],
      providerId: json['provider'],
      isBusiness: json['is_business'] ?? false,
      businessName: json['business_name'],
      businessNif: json['business_nif'],
      businessRegistrationNumber: json['business_registration_number'],
      documentType: json['document_type'] ?? 'id_card',
      idCardFrontUrl: json['id_card_front'],
      idCardBackUrl: json['id_card_back'],
      passportImageUrl: json['passport_image'],
      businessRegistrationDocUrl: json['business_registration_doc'],
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
      'provider': providerId,
      'is_business': isBusiness,
      'business_name': businessName,
      'business_nif': businessNif,
      'business_registration_number': businessRegistrationNumber,
      'document_type': documentType,
      // Les URLs d'images ne sont généralement pas envoyées dans toJson
      // car elles sont gérées par les uploads multipart
    };
  }

  /// Vérifie si la vérification est terminée (approuvée ou rejetée)
  bool get isCompleted => verificationStatus == 'verified' || verificationStatus == 'rejected';

  /// Vérifie si la vérification est en attente
  bool get isPending => verificationStatus == 'pending';

  /// Vérifie si la vérification est approuvée
  bool get isVerified => verificationStatus == 'verified';

  /// Vérifie si la vérification est rejetée
  bool get isRejected => verificationStatus == 'rejected';

  /// Obtient la couleur du statut
  Color get statusColor {
    switch (verificationStatus) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtient l'icône du statut
  IconData get statusIcon {
    switch (verificationStatus) {
      case 'verified':
        return Icons.verified_user;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.assignment;
    }
  }

  /// Obtient le libellé du statut
  String get statusLabel {
    switch (verificationStatus) {
      case 'verified':
        return 'Vérifié';
      case 'pending':
        return 'En attente';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Non commencé';
    }
  }

  /// Obtient les documents manquants
  List<String> get missingDocuments {
    List<String> required = [];
    List<String> missing = [];

    if (documentType == 'id_card') {
      required.addAll(['Carte d\'identité (recto)', 'Carte d\'identité (verso)']);
      if (idCardFrontUrl == null) {
        missing.add('Carte d\'identité (recto)');
      }
      if (idCardBackUrl == null) {
        missing.add('Carte d\'identité (verso)');
      }
    } else if (documentType == 'passport') {
      required.add('Passeport');
      if (passportImageUrl == null) {
        missing.add('Passeport');
      }
    }

    if (isBusiness) {
      required.add('Nom de l\'entreprise');
      if (businessName == null || businessName!.isEmpty) {
        missing.add('Nom de l\'entreprise');
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
      return 'Votre profil est vérifié ! Vous pouvez maintenant utiliser toutes les fonctionnalités.';
    } else {
      return 'Complétez votre vérification pour accéder à toutes les fonctionnalités.';
    }
  }

  ProviderVerification copyWith({
    int? id,
    int? providerId,
    bool? isBusiness,
    String? businessName,
    String? businessNif,
    String? businessRegistrationNumber,
    String? documentType,
    String? idCardFrontUrl,
    String? idCardBackUrl,
    String? passportImageUrl,
    String? businessRegistrationDocUrl,
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
    return ProviderVerification(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      isBusiness: isBusiness ?? this.isBusiness,
      businessName: businessName ?? this.businessName,
      businessNif: businessNif ?? this.businessNif,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      documentType: documentType ?? this.documentType,
      idCardFrontUrl: idCardFrontUrl ?? this.idCardFrontUrl,
      idCardBackUrl: idCardBackUrl ?? this.idCardBackUrl,
      passportImageUrl: passportImageUrl ?? this.passportImageUrl,
      businessRegistrationDocUrl: businessRegistrationDocUrl ?? this.businessRegistrationDocUrl,
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
}