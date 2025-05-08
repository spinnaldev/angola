class QuoteRequest {
  final int? id;
  final int clientId;
  final int providerId;
  final String subject;
  final double budget;
  final String description;
  final String status;  // 'pending', 'accepted', 'rejected', 'completed'
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
      clientId: json['client_id'],
      providerId: json['provider_id'],
      subject: json['subject'],
      budget: json['budget'].toDouble(),
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
}