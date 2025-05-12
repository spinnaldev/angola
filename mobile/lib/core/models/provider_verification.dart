// lib/core/models/provider_verification.dart
import 'dart:convert';

class ProviderVerification {
  final int providerId;
  final bool isBusiness;
  final String? businessName;
  final String? businessNif; // Numéro d'identification fiscale pour les entreprises
  final String? businessRegistrationNumber;
  final String? idCardFrontUrl; // Pièce d'identité recto
  final String? idCardBackUrl; // Pièce d'identité verso
  final String? businessRegistrationDocUrl;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verificationStatus; // 'pending', 'verified', 'rejected'
  final String? rejectionReason;

  ProviderVerification({
    required this.providerId,
    required this.isBusiness,
    this.businessName,
    this.businessNif,
    this.businessRegistrationNumber,
    this.idCardFrontUrl,
    this.idCardBackUrl,
    this.businessRegistrationDocUrl,
    this.isVerified = false,
    this.verifiedAt,
    this.verificationStatus = 'pending',
    this.rejectionReason,
  });

  factory ProviderVerification.fromJson(Map<String, dynamic> json) {
    return ProviderVerification(
      providerId: json['provider'],
      isBusiness: json['is_business'] ?? false,
      businessName: json['business_name'],
      businessNif: json['business_nif'],
      businessRegistrationNumber: json['business_registration_number'],
      idCardFrontUrl: json['id_card_front'],
      idCardBackUrl: json['id_card_back'],
      businessRegistrationDocUrl: json['business_registration_doc'],
      isVerified: json['is_verified'] ?? false,
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
      verificationStatus: json['verification_status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': providerId,
      'is_business': isBusiness,
      'business_name': businessName,
      'business_nif': businessNif,
      'business_registration_number': businessRegistrationNumber,
      'id_card_front': idCardFrontUrl,
      'id_card_back': idCardBackUrl,
      'business_registration_doc': businessRegistrationDocUrl,
    };
  }

  ProviderVerification copyWith({
    int? providerId,
    bool? isBusiness,
    String? businessName,
    String? businessNif,
    String? businessRegistrationNumber,
    String? idCardFrontUrl,
    String? idCardBackUrl,
    String? businessRegistrationDocUrl,
    bool? isVerified,
    DateTime? verifiedAt,
    String? verificationStatus,
    String? rejectionReason,
  }) {
    return ProviderVerification(
      providerId: providerId ?? this.providerId,
      isBusiness: isBusiness ?? this.isBusiness,
      businessName: businessName ?? this.businessName,
      businessNif: businessNif ?? this.businessNif,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      idCardFrontUrl: idCardFrontUrl ?? this.idCardFrontUrl,
      idCardBackUrl: idCardBackUrl ?? this.idCardBackUrl,
      businessRegistrationDocUrl: businessRegistrationDocUrl ?? this.businessRegistrationDocUrl,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}