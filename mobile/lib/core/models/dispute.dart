// lib/core/models/dispute.dart
class Dispute {
  final int? id;
  final int clientId;
  final int providerId;
  final int? serviceId;
  final String title;
  final String description;
  final String status; // 'open', 'under_review', 'resolved', 'closed'
  final String? resolutionNote;
  final DateTime createdAt;
  final List<DisputeEvidence> evidence;
  
  // Propriétés calculées pour faciliter l'affichage
  final String clientName;
  final String providerName;
  final String? serviceName;

  Dispute({
    this.id,
    required this.clientId,
    required this.providerId,
    this.serviceId,
    required this.title,
    required this.description,
    this.status = 'open',
    this.resolutionNote,
    DateTime? createdAt,
    this.evidence = const [],
    this.clientName = '',
    this.providerName = '',
    this.serviceName,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory Dispute.fromJson(Map<String, dynamic> json) {
    // Traiter la liste des preuves
    List<DisputeEvidence> evidenceList = [];
    if (json['evidence'] != null) {
      evidenceList = (json['evidence'] as List)
          .map((item) => DisputeEvidence.fromJson(item))
          .toList();
    }

    return Dispute(
      id: json['id'],
      clientId: json['client'],
      providerId: json['provider'],
      serviceId: json['service'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      resolutionNote: json['resolution_note'],
      createdAt: DateTime.parse(json['created_at']),
      evidence: evidenceList,
      clientName: json['client_name'] ?? '',
      providerName: json['provider_name'] ?? '',
      serviceName: json['service_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client': clientId,
      'provider': providerId,
      'service': serviceId,
      'title': title,
      'description': description,
    };
  }
}

class DisputeEvidence {
  final int? id;
  final int userId;
  final String description;
  final String fileUrl;
  final DateTime createdAt;
  final String userName;

  DisputeEvidence({
    this.id,
    required this.userId,
    required this.description,
    required this.fileUrl,
    DateTime? createdAt,
    this.userName = '',
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory DisputeEvidence.fromJson(Map<String, dynamic> json) {
    return DisputeEvidence(
      id: json['id'],
      userId: json['user'],
      description: json['description'],
      fileUrl: json['file'],
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'file': fileUrl,
    };
  }
}