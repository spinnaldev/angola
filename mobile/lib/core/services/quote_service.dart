import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quote_request.dart';
import 'api_service.dart';

class QuoteService {
  final ApiService _apiService;

  QuoteService(this._apiService);

  // Créer une nouvelle demande de devis
  Future<QuoteRequest> createQuoteRequest(QuoteRequest quoteRequest) async {
    try {
      final headers = await _apiService.getHeaders();
      headers['Content-Type'] = 'application/json; charset=utf-8';

      // ✅ Debug: Log des données envoyées
      final requestBody = json.encode(quoteRequest.toJson());
      print('📤 Données envoyées au serveur: $requestBody');

      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/quote-requests/'),
        headers: headers,
        body: requestBody,
      );

      print('📥 Status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Données reçues du serveur: $data'); // ✅ Debug crucial
        
        // ✅ Vérification avant parsing
        if (data == null) {
          throw Exception('Réponse vide du serveur');
        }
        
        return QuoteRequest.fromJson(data);
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to create quote request: ${response.body}');
      }
    } catch (e) {
      print("💥 Erreur dans createQuoteRequest: $e");
      print("💥 Type d'erreur: ${e.runtimeType}");
      rethrow;
    }
  }

  // Récupérer les demandes de devis de l'utilisateur
  Future<List<QuoteRequest>> getUserQuoteRequests() async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/quote-requests/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => QuoteRequest.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get quote requests: ${response.body}');
      }
    } catch (e) {
      print('Error in getUserQuoteRequests: $e');
      rethrow;
    }
  }

  // Mettre à jour le statut d'une demande de devis (pour les prestataires)
  Future<QuoteRequest> updateQuoteRequestStatus(
      int quoteRequestId, String status) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.post(
        Uri.parse(
            '${_apiService.baseUrl}/quote-requests/$quoteRequestId/update_status/'),
        headers: headers,
        body: json.encode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuoteRequest.fromJson(data);
      } else {
        throw Exception(
            'Failed to update quote request status: ${response.body}');
      }
    } catch (e) {
      print('Error in updateQuoteRequestStatus: $e');
      rethrow;
    }
  }
}
