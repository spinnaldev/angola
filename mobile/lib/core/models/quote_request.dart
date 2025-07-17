class QuoteRequest {
  final int? id;
  final int clientId;
  final int providerId;
  final String subject;
  final double budget;
  final String description;
  final String status; // 'pending', 'accepted', 'rejected', 'completed'
  final DateTime createdAt;

  QuoteRequest({
    this.id,
    required this.clientId,
    required this.providerId,
    required this.subject,
    required this.budget,
    required this.description,
    this.status = 'pending',
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory QuoteRequest.fromJson(Map<String, dynamic> json) {
    return QuoteRequest(
      id: json['id'],
      clientId: _parseIntSafely(json['client_id'] ?? json['client']), // ✅ Fallback client
      providerId: _parseIntSafely(json['provider_id'] ?? json['provider']), // ✅ Fallback provider  
      subject: json['subject'],
      budget: _parseDoubleSafely(json['budget']), 
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
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
    };
  }

  // ✅ Méthodes utilitaires pour parsing sécurisé
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
      print('Erreur parsing double: $e pour valeur: $value');
      return 0.0;
    }
  }
}
