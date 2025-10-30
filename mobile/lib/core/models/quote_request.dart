class QuoteRequest {
  final int? id;
  final int clientId;
  final int providerId;
  final String subject;
  final double budget;
  final String description;
  final String status;
  final DateTime createdAt;
  
  // ✅ Ajout des relations optionnelles
  final String? providerName;
  final String? clientName;
  final Map<String, dynamic>? provider;  // Objet provider complet si disponible
  final Map<String, dynamic>? client;    // Objet client complet si disponible

  QuoteRequest({
    this.id,
    required this.clientId,
    required this.providerId,
    required this.subject,
    required this.budget,
    required this.description,
    this.status = 'pending',
    DateTime? createdAt,
    this.providerName,
    this.clientName,
    this.provider,
    this.client,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory QuoteRequest.fromJson(Map<String, dynamic> json) {
    // Extraire les données provider et client s'ils sont présents
    final providerData = json['provider'];
    final clientData = json['client'];
    
    return QuoteRequest(
      id: json['id'],
      clientId: _parseIntSafely(
        json['client_id'] ?? 
        (clientData is Map ? clientData['id'] : null)
      ),
      providerId: _parseIntSafely(
        json['provider_id'] ?? 
        (providerData is Map ? providerData['id'] : null)
      ),
      subject: json['subject'] ?? '',
      budget: _parseDoubleSafely(json['budget']),
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      
      // ✅ Parser les noms et objets complets
      providerName: providerData is Map 
          ? (providerData['name'] ?? providerData['business_name']) 
          : json['provider_name'],
      clientName: clientData is Map 
          ? (clientData['name'] ?? clientData['full_name']) 
          : json['client_name'],
      provider: providerData is Map ? Map<String, dynamic>.from(providerData) : null,
      client: clientData is Map ? Map<String, dynamic>.from(clientData) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'provider_id': providerId,
      'subject': subject,
      'budget': budget,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (providerName != null) 'provider_name': providerName,
      if (clientName != null) 'client_name': clientName,
    };
  }

  // ✅ Getters utilitaires
  String get providerDisplayName => providerName ?? 'Fournisseur #$providerId';
  String get clientDisplayName => clientName ?? 'Client #$clientId';

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

  static double _parseDoubleSafely(dynamic value) {
    if (value == null) return 0.0;
    
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String && value.isNotEmpty) {
        return double.parse(value);
      }
      return 0.0;
    } catch (e) {
      print('❌ Erreur parsing double: $e pour valeur: $value');
      return 0.0;
    }
  }
}