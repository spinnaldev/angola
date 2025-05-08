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
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/quote-requests/'),
        headers: headers,
        body: json.encode({
          'provider': quoteRequest.providerId,
          'service': null, // Optionnel
          'subject': quoteRequest.subject,
          'budget': quoteRequest.budget,
          'description': quoteRequest.description,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return QuoteRequest.fromJson(data);
      } else {
        throw Exception('Failed to create quote request: ${response.body}');
      }
    } catch (e) {
      print('Error in createQuoteRequest: $e');
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
  Future<QuoteRequest> updateQuoteRequestStatus(int quoteRequestId, String status) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/quote-requests/$quoteRequestId/update_status/'),
        headers: headers,
        body: json.encode({
          'status': status,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuoteRequest.fromJson(data);
      } else {
        throw Exception('Failed to update quote request status: ${response.body}');
      }
    } catch (e) {
      print('Error in updateQuoteRequestStatus: $e');
      rethrow;
    }
  }
}