class ProjectOffer {
  final int id;
  final int projectId;
  final String? projectTitle;
  final int providerId;
  final String providerName;
  final String? providerBusinessType;
  final double providerRating;
  final String? providerAvatar;
  final String? providerLocation;
  final bool providerVerified;
  final double proposedPrice;
  final int deliveryTime;
  final String message;
  final bool includesMaterials;
  final int? warrantyPeriod;
  final bool travelCostsIncluded;
  final String status;
  final bool viewedByClient;
  final DateTime createdAt;

  ProjectOffer({
    required this.id,
    required this.projectId,
    this.projectTitle,
    required this.providerId,
    required this.providerName,
    this.providerBusinessType,
    required this.providerRating,
    this.providerAvatar,
    this.providerLocation,
    required this.providerVerified,
    required this.proposedPrice,
    required this.deliveryTime,
    required this.message,
    required this.includesMaterials,
    this.warrantyPeriod,
    required this.travelCostsIncluded,
    required this.status,
    required this.viewedByClient,
    required this.createdAt,
  });

  factory ProjectOffer.fromJson(Map<String, dynamic> json) {
    return ProjectOffer(
      id: json['id'],
      projectId: json['project'],
      projectTitle: json['project_title'],
      providerId: json['provider'],
      providerName: json['provider_name'],
      providerBusinessType: json['provider_business_type'],
      providerRating: _parseDoubleFromDynamic(json['provider_rating']) ?? 0.0,
      // providerRating: (json['provider_rating'] ?? 0).toDouble(),
      providerAvatar: json['provider_avatar'],
      providerLocation: json['provider_location'],
      providerVerified: json['provider_verified'] ?? false,
      proposedPrice: _parseDoubleFromDynamic(json['proposed_price']) ?? 0.0,
      // proposedPrice: double.parse(json['proposed_price'].toString()),
      deliveryTime: json['delivery_time'],
      message: json['message'],
      includesMaterials: json['includes_materials'] ?? false,
      warrantyPeriod: json['warranty_period'],
      travelCostsIncluded: json['travel_costs_included'] ?? true,
      status: json['status'],
      viewedByClient: json['viewed_by_client'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static double? _parseDoubleFromDynamic(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is double) {
        return value;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is String) {
        if (value.isEmpty) return null;
        return double.parse(value);
      } else {
        print('⚠️ Type inattendu pour nombre: ${value.runtimeType} - $value');
        return double.tryParse(value.toString());
      }
    } catch (e) {
      print('❌ Erreur parsing nombre: $e pour valeur: $value');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': projectId,
      'project_title': projectTitle,
      'provider': providerId,
      'provider_name': providerName,
      'provider_business_type': providerBusinessType,
      'provider_rating': providerRating,
      'provider_avatar': providerAvatar,
      'provider_location': providerLocation,
      'provider_verified': providerVerified,
      'proposed_price': proposedPrice,
      'delivery_time': deliveryTime,
      'message': message,
      'includes_materials': includesMaterials,
      'warranty_period': warrantyPeriod,
      'travel_costs_included': travelCostsIncluded,
      'status': status,
      'viewed_by_client': viewedByClient,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Getters utilitaires
  String get statusLabel {
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
        return status;
    }
  }

  String get deliveryTimeLabel {
    if (deliveryTime == 1) {
      return '1 jour';
    } else if (deliveryTime < 7) {
      return '$deliveryTime jours';
    } else if (deliveryTime < 30) {
      final weeks = (deliveryTime / 7).round();
      return '$weeks semaine${weeks > 1 ? 's' : ''}';
    } else {
      final months = (deliveryTime / 30).round();
      return '$months mois';
    }
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isWithdrawn => status == 'withdrawn';
}
