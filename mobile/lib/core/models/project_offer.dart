// lib/core/models/project_offer.dart
class ProjectOffer {
  final int? id;
  final int? projectId;
  final String? projectTitle;
  final String? projectDescription;
  final int? providerId;
  final String? providerName;
  final double? proposedPrice;
  final int? deliveryTime;
  final String? message;
  final bool? includesMaterials;
  final int? warrantyPeriod;
  final bool? travelCostsIncluded;
  final String status;
  final bool? viewedByClient;
  final String? clientNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectOffer({
    this.id,
    this.projectId,
    this.projectTitle,
    this.projectDescription,
    this.providerId,
    this.providerName,
    this.proposedPrice,
    this.deliveryTime,
    this.message,
    this.includesMaterials,
    this.warrantyPeriod,
    this.travelCostsIncluded,
    this.status = 'pending',
    this.viewedByClient,
    this.clientNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectOffer.fromJson(Map<String, dynamic> json) {
    return ProjectOffer(
      id: json['id'],
      projectId: json['project_id'] ?? json['project'],
      projectTitle: json['project_title'] ?? json['project_name'],
      projectDescription: json['project_description'],
      providerId: json['provider_id'] ?? json['provider'],
      providerName: json['provider_name'],
      proposedPrice: _parseDouble(json['proposed_price']),
      deliveryTime: json['delivery_time'],
      message: json['message'],
      includesMaterials: json['includes_materials'],
      warrantyPeriod: json['warranty_period'],
      travelCostsIncluded: json['travel_costs_included'],
      status: json['status'] ?? 'pending',
      viewedByClient: json['viewed_by_client'],
      clientNotes: json['client_notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': projectId,
      'project_title': projectTitle,
      'project_description': projectDescription,
      'provider': providerId,
      'provider_name': providerName,
      'proposed_price': proposedPrice,
      'delivery_time': deliveryTime,
      'message': message,
      'includes_materials': includesMaterials,
      'warranty_period': warrantyPeriod,
      'travel_costs_included': travelCostsIncluded,
      'status': status,
      'viewed_by_client': viewedByClient,
      'client_notes': clientNotes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProjectOffer copyWith({
    int? id,
    int? projectId,
    String? projectTitle,
    String? projectDescription,
    int? providerId,
    String? providerName,
    double? proposedPrice,
    int? deliveryTime,
    String? message,
    bool? includesMaterials,
    int? warrantyPeriod,
    bool? travelCostsIncluded,
    String? status,
    bool? viewedByClient,
    String? clientNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectOffer(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      projectDescription: projectDescription ?? this.projectDescription,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      message: message ?? this.message,
      includesMaterials: includesMaterials ?? this.includesMaterials,
      warrantyPeriod: warrantyPeriod ?? this.warrantyPeriod,
      travelCostsIncluded: travelCostsIncluded ?? this.travelCostsIncluded,
      status: status ?? this.status,
      viewedByClient: viewedByClient ?? this.viewedByClient,
      clientNotes: clientNotes ?? this.clientNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Méthodes utilitaires
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isWithdrawn => status == 'withdrawn';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Rejetée';
      case 'withdrawn':
        return 'Retirée';
      default:
        return 'Inconnu';
    }
  }

  String get priceDisplay {
    if (proposedPrice == null) return 'Prix non spécifié';
    return '${proposedPrice!.toStringAsFixed(0)} AOA';
  }

  String get deliveryTimeDisplay {
    if (deliveryTime == null) return 'Délai non spécifié';
    if (deliveryTime == 1) return '1 jour';
    return '$deliveryTime jours';
  }

  // Fonction helper pour parser les doubles
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  @override
  String toString() {
    return 'ProjectOffer(id: $id, projectTitle: $projectTitle, status: $status, proposedPrice: $proposedPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectOffer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}