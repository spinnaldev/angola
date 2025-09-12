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
  final String? fileUrl; // ✅ MODIFICATION : Maintenant optionnel
  final String userName;
  final DateTime createdAt;
  final String evidenceType; // ✅ NOUVEAU : Type de preuve
  final bool hasFile; // ✅ NOUVEAU : Indicateur de présence de fichier

  DisputeEvidence({
    this.id,
    required this.disputeId,
    required this.description,
    this.fileUrl, // ✅ MODIFICATION : Plus obligatoire
    required this.userName,
    DateTime? createdAt,
    this.evidenceType = 'comment', // ✅ NOUVEAU : Par défaut commentaire
    this.hasFile = false, // ✅ NOUVEAU : Par défaut pas de fichier
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory DisputeEvidence.fromJson(Map<String, dynamic> json) {
    try {
      print('📋 Debug DisputeEvidence.fromJson: $json');
      
      // Parsing sécurisé de l'ID
      int? parsedId;
      if (json['id'] != null) {
        parsedId = _parseIntSafely(json['id']);
      }
      
      // Parsing sécurisé du dispute_id
      int parsedDisputeId = 0;
      if (json['dispute_id'] != null) {
        parsedDisputeId = _parseIntSafely(json['dispute_id']);
      } else if (json['dispute'] != null) {
        parsedDisputeId = _parseIntSafely(json['dispute']);
      }
      
      // ✅ MODIFICATION : fileUrl maintenant optionnel
      String? parsedFileUrl;
      if (json['file_url'] != null && json['file_url'].toString().isNotEmpty) {
        parsedFileUrl = json['file_url'].toString();
      } else if (json['file'] != null && json['file'].toString().isNotEmpty) {
        parsedFileUrl = json['file'].toString();
      }
      // Si null ou vide, reste null
      
      // ✅ NOUVEAU : Récupération du type et indicateur de fichier
      String parsedEvidenceType = json['evidence_type']?.toString() ?? 'comment';
      bool parsedHasFile = json['has_file'] == true || parsedFileUrl != null;
      
      String parsedDescription = json['description']?.toString() ?? '';
      String parsedUserName = json['user_name']?.toString() ?? 
                              json['username']?.toString() ??
                              json['user']?.toString() ?? 
                              'Utilisateur';
      
      DateTime parsedCreatedAt;
      if (json['created_at'] != null) {
        try {
          parsedCreatedAt = DateTime.parse(json['created_at'].toString());
        } catch (e) {
          print('⚠️ Erreur parsing date: $e');
          parsedCreatedAt = DateTime.now();
        }
      } else {
        parsedCreatedAt = DateTime.now();
      }

      final evidence = DisputeEvidence(
        id: parsedId,
        disputeId: parsedDisputeId,
        description: parsedDescription,
        fileUrl: parsedFileUrl, // ✅ MODIFICATION : Peut être null
        userName: parsedUserName,
        createdAt: parsedCreatedAt,
        evidenceType: parsedEvidenceType, // ✅ NOUVEAU
        hasFile: parsedHasFile, // ✅ NOUVEAU
      );
      
      print('✅ DisputeEvidence créé: Type=${evidence.evidenceType}, HasFile=${evidence.hasFile}');
      return evidence;
      
    } catch (e, stackTrace) {
      print('❌ Erreur dans DisputeEvidence.fromJson: $e');
      print('❌ JSON problématique: $json');
      
      // ✅ MODIFICATION : Objet par défaut avec fileUrl null
      return DisputeEvidence(
        id: null,
        disputeId: 0,
        description: json['description']?.toString() ?? 'Description non disponible',
        fileUrl: null, // ✅ MODIFICATION : Peut être null
        userName: 'Utilisateur',
        createdAt: DateTime.now(),
        evidenceType: 'comment',
        hasFile: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispute_id': disputeId,
      'description': description,
      'file_url': fileUrl,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
      'evidence_type': evidenceType,
      'has_file': hasFile,
    };
  }

  // ✅ NOUVEAU : Méthodes helper
  bool get isComment => evidenceType == 'comment';
  bool get isDocument => evidenceType == 'document';
  bool get isImage => hasFile && fileUrl != null && (
    fileUrl!.toLowerCase().endsWith('.jpg') ||
    fileUrl!.toLowerCase().endsWith('.jpeg') ||
    fileUrl!.toLowerCase().endsWith('.png')
  );

  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    try {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String && value.isNotEmpty) {
        return int.parse(value);
      }
      return 0;
    } catch (e) {
      print('❌ Erreur parsing int: $e pour valeur: $value');
      return 0;
    }
  }
}