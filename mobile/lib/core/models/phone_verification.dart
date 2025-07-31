
import 'package:flutter/material.dart';

class PhoneVerification {
  final int? id;
  final int userId;
  final String phoneNumber;
  final String status; // 'pending', 'verified', 'expired', 'failed'
  final int attempts;
  final int maxAttempts;
  final DateTime? expiresAt;
  final DateTime? verifiedAt;
  final DateTime? lastCodeSentAt;
  final int timeRemaining; // en secondes
  final bool canResend;
  final int attemptsRemaining;

  PhoneVerification({
    this.id,
    required this.userId,
    required this.phoneNumber,
    required this.status,
    required this.attempts,
    required this.maxAttempts,
    this.expiresAt,
    this.verifiedAt,
    this.lastCodeSentAt,
    required this.timeRemaining,
    required this.canResend,
    required this.attemptsRemaining,
  });

  factory PhoneVerification.fromJson(Map<String, dynamic> json) {
    return PhoneVerification(
      id: json['id'],
      userId: json['user'],
      phoneNumber: json['phone_number'],
      status: json['status'],
      attempts: json['attempts'] ?? 0,
      maxAttempts: json['max_attempts'] ?? 3,
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
      lastCodeSentAt: json['last_code_sent_at'] != null 
          ? DateTime.parse(json['last_code_sent_at']) 
          : null,
      timeRemaining: json['time_remaining'] ?? 0,
      canResend: json['can_resend'] ?? false,
      attemptsRemaining: json['attempts_remaining'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user': userId,
      'phone_number': phoneNumber,
      'status': status,
    };
  }

  /// Vérifie si la vérification est expirée
  bool get isExpired => status == 'expired' || 
      (expiresAt != null && DateTime.now().isAfter(expiresAt!));

  /// Vérifie si la vérification est réussie
  bool get isVerified => status == 'verified';

  /// Vérifie si la vérification est en cours
  bool get isPending => status == 'pending';

  /// Vérifie si la vérification a échoué
  bool get isFailed => status == 'failed';

  /// Obtient le temps restant formaté
  String get formattedTimeRemaining {
    if (timeRemaining <= 0) return '00:00';
    
    int minutes = timeRemaining ~/ 60;
    int seconds = timeRemaining % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Obtient la couleur du statut
  Color get statusColor {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtient l'icône du statut
  IconData get statusIcon {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.access_time;
      case 'failed':
        return Icons.error;
      case 'expired':
        return Icons.timer_off;
      default:
        return Icons.phone;
    }
  }

  /// Obtient le libellé du statut
  String get statusLabel {
    switch (status) {
      case 'verified':
        return 'Vérifié';
      case 'pending':
        return 'En attente';
      case 'failed':
        return 'Échec';
      case 'expired':
        return 'Expiré';
      default:
        return 'Non vérifié';
    }
  }

  /// Obtient le message d'instruction
  String get instructionMessage {
    if (isVerified) {
      return 'Votre numéro de téléphone est vérifié !';
    } else if (isPending) {
      return 'Entrez le code reçu par SMS sur $phoneNumber';
    } else if (isExpired) {
      return 'Le code a expiré. Demandez un nouveau code.';
    } else if (isFailed) {
      return 'Nombre maximum de tentatives atteint. Demandez un nouveau code.';
    } else {
      return 'Nous allons envoyer un code de vérification à votre numéro.';
    }
  }

  PhoneVerification copyWith({
    int? id,
    int? userId,
    String? phoneNumber,
    String? status,
    int? attempts,
    int? maxAttempts,
    DateTime? expiresAt,
    DateTime? verifiedAt,
    DateTime? lastCodeSentAt,
    int? timeRemaining,
    bool? canResend,
    int? attemptsRemaining,
  }) {
    return PhoneVerification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      expiresAt: expiresAt ?? this.expiresAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      lastCodeSentAt: lastCodeSentAt ?? this.lastCodeSentAt,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      canResend: canResend ?? this.canResend,
      attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
    );
  }
}