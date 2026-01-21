import 'dart:convert';

import 'package:teyago/core/models/verification_info.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? bio;
  final String? profilePicture;
  final String role;
  final bool isVerified;
  final String? location;
  final DateTime dateJoined;
  final String? companyName;

  final String? verificationStatus;
  final Map<String, dynamic>? verificationDetails;
  final bool isPhoneVerified;
  final bool isProviderVerified;
  final bool needsVerification;

  final bool isClientVerified;
  final String? clientVerificationStatus;
  
  // Coordonnées GPS
  final double? latitude;
  final double? longitude;
  
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.bio,
    this.profilePicture,
    required this.role,
    required this.isVerified,
    this.location,
    required this.dateJoined,
    this.companyName,

    this.verificationStatus,
    this.verificationDetails,
    this.isPhoneVerified = false,
    this.isProviderVerified = false,
    this.needsVerification = false,
    this.isClientVerified = false,
    this.clientVerificationStatus,
    
    // Coordonnées GPS
    this.latitude,
    this.longitude,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      bio: json['bio'],
      profilePicture: json['profile_picture'],
      role: json['role'],
      isVerified: json['is_verified'],
      location: json['location'],
      dateJoined: DateTime.parse(json['date_joined']),
      companyName: json['company_name'], 

      verificationStatus: json['verification_status'],
      verificationDetails: json['verification_details'],
      isPhoneVerified: json['is_phone_verified'] ?? false,
      isProviderVerified: json['is_provider_verified'] ?? false,
      needsVerification: json['needs_verification'] ?? false,

      isClientVerified: json['is_client_verified'] ?? false,
      clientVerificationStatus: json['client_verification_status'],
      
      // Coordonnées GPS
      latitude: json['latitude'] != null ? (json['latitude'] is double ? json['latitude'] : double.tryParse(json['latitude'].toString())) : null,
      longitude: json['longitude'] != null ? (json['longitude'] is double ? json['longitude'] : double.tryParse(json['longitude'].toString())) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'bio': bio,
      'profile_picture': profilePicture,
      'role': role,
      'is_verified': isVerified,
      'location': location,
      'date_joined': dateJoined.toIso8601String(),
      'company_name': companyName,

      'verification_status': verificationStatus,
      'verification_details': verificationDetails,
      'is_phone_verified': isPhoneVerified,
      'is_provider_verified': isProviderVerified,
      'needs_verification': needsVerification,

      'is_client_verified': isClientVerified,
      'client_verification_status': clientVerificationStatus,
      
      // Coordonnées GPS
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static String toJsonString(User user) {
    return json.encode(user.toJson());
  }

  static User fromJsonString(String jsonString) {
    return User.fromJson(json.decode(jsonString));
  }

  String get fullName => '$firstName $lastName';

  String get displayName {
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return username.isNotEmpty ? username : email.split('@').first;
  }

  
  String get displayNameWithCompany {
    if (role == 'provider' && companyName != null && companyName!.isNotEmpty) {
      return companyName!;
    }
    return displayName;
  }

  /// Vérifie si l'utilisateur peut effectuer des actions selon son rôle
  bool get canPerformActions {
    if (role == 'admin') return true;
    
    if (role == 'client') {
      return isClientVerified;
    } else if (role == 'provider') {
      return isProviderVerified;
    }
    
    return true;
  }

  /// Obtient le type de vérification requis selon le rôle
  String get requiredVerificationType {
    if (role == 'client') {
      return 'client_documents';
    } else if (role == 'provider') {
      return 'provider_documents';
    }
    return 'none';
  }

  /// Obtient le statut de vérification affiché selon le rôle
  String get displayVerificationStatus {
    if (role == 'client') {
      return clientVerificationStatus ?? 'not_started';
    } else if (role == 'provider') {
      return verificationStatus ?? 'not_started';
    }
    return 'not_applicable';
  }

  /// Vérifie si la vérification est en cours
  bool get isVerificationPending {
    if (role == 'client') {
      return clientVerificationStatus == 'pending';
    } else if (role == 'provider') {
      return verificationStatus == 'pending';
    }
    return false;
  }

  /// Vérifie si la vérification a été rejetée
  bool get isVerificationRejected {
    if (role == 'client') {
      return clientVerificationStatus == 'rejected';
    } else if (role == 'provider') {
      return verificationStatus == 'rejected';
    }
    return false;
  }

  /// Obtient les détails de vérification selon le rôle
  VerificationInfo get verificationInfo {
    if (role == 'client') {
      return VerificationInfo(
        type: 'client_documents',
        status: displayVerificationStatus,
        isVerified: isClientVerified,
        documentType: verificationDetails?['document_type'],
        submittedAt: verificationDetails?['submitted_at'] != null 
            ? DateTime.parse(verificationDetails!['submitted_at']) 
            : null,
        verifiedAt: verificationDetails?['verified_at'] != null 
            ? DateTime.parse(verificationDetails!['verified_at']) 
            : null,
        rejectionReason: verificationDetails?['rejection_reason'],
      );
    } else if (role == 'provider') {
      return VerificationInfo(
        type: 'provider_documents',
        status: displayVerificationStatus,
        isVerified: isProviderVerified,
        isBusiness: verificationDetails?['is_business'] ?? false,
        documentType: verificationDetails?['document_type'],
        submittedAt: verificationDetails?['submitted_at'] != null 
            ? DateTime.parse(verificationDetails!['submitted_at']) 
            : null,
        verifiedAt: verificationDetails?['verified_at'] != null 
            ? DateTime.parse(verificationDetails!['verified_at']) 
            : null,
        rejectionReason: verificationDetails?['rejection_reason'],
      );
    }
    
    return VerificationInfo(
      type: 'none',
      status: 'not_applicable',
      isVerified: true,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    String? profilePicture,
    String? role,
    bool? isVerified,
    String? location,
    DateTime? dateJoined,
    String? companyName,
    String? verificationStatus,
    Map<String, dynamic>? verificationDetails,
    bool? isPhoneVerified,
    bool? isProviderVerified,
    bool? needsVerification,
    bool? isClientVerified,
    String? clientVerificationStatus,
    double? latitude,
    double? longitude,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      location: location ?? this.location,
      dateJoined: dateJoined ?? this.dateJoined,
      companyName: companyName ?? this.companyName,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationDetails: verificationDetails ?? this.verificationDetails,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isProviderVerified: isProviderVerified ?? this.isProviderVerified,
      needsVerification: needsVerification ?? this.needsVerification,
      
      // NOUVEAU
      isClientVerified: isClientVerified ?? this.isClientVerified,
      clientVerificationStatus: clientVerificationStatus ?? this.clientVerificationStatus,
      
      // Coordonnées GPS
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, fullName: $fullName, role: $role, companyName: $companyName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}