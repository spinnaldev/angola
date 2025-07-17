// lib/core/models/dispute.dart
import 'dart:convert';

class Dispute {
  final int? id;
  final int providerId;
  final String providerName;
  final int? serviceId;
  final String? serviceName;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? resolutionNote;
  final List<DisputeEvidence> evidence;
  final String clientName;

  Dispute({
    this.id,
    required this.providerId,
    required this.providerName,
    this.serviceId,
    this.serviceName,
    required this.title,
    required this.description,
    this.status = 'open',
    DateTime? createdAt,
    this.resolutionNote,
    List<DisputeEvidence>? evidence,
    required this.clientName,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.evidence = evidence ?? [];

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'],
      providerId: _parseIntSafely(json['provider_id'] ?? json['provider']), 
      providerName: json['provider_name'] ?? 'Inconnu',
      serviceId: _parseIntSafely(json['service_id'] ?? json['service']),
      serviceName: json['service_name'],
      title: json['title'],
      description: json['description'],
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      resolutionNote: json['resolution_note'],
      evidence: json['evidence'] != null 
          ? (json['evidence'] as List)
              .map((e) => DisputeEvidence.fromJson(e))
              .toList() 
          : [],
      clientName: json['client_name'] ?? 'Client',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'service_id': serviceId,
      'title': title,
      'description': description,
    };
  }

  static int _parseIntSafely(dynamic value) {
    if (value == null) {
      print('⚠️ Valeur null pour int, retour 0');
      return 0;
    }
    
    try {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String && value.isNotEmpty) {
        return int.parse(value);
      }
      print('⚠️ Impossible de parser en int: $value (${value.runtimeType})');
      return 0;
    } catch (e) {
      print('❌ Erreur parsing int: $e pour valeur: $value');
      return 0;
    }
  }
}

class DisputeEvidence {
  final int? id;
  final int disputeId;
  final String description;
  final String fileUrl;
  final String userName;
  final DateTime createdAt;

  DisputeEvidence({
    this.id,
    required this.disputeId,
    required this.description,
    required this.fileUrl,
    required this.userName,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory DisputeEvidence.fromJson(Map<String, dynamic> json) {
    return DisputeEvidence(
      id: json['id'],
      disputeId: json['dispute_id'],
      description: json['description'],
      fileUrl: json['file_url'],
      userName: json['user_name'] ?? 'Utilisateur',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dispute_id': disputeId,
      'description': description,
    };
  }
}