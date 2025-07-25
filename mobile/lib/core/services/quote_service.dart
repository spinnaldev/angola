import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quote_request.dart';
import 'api_service.dart';
import '../api/api_client.dart'; // ✅ Import ApiClient

class QuoteService {
  final ApiService _apiService;
  late final ApiClient _apiClient; // ✅ Référence ApiClient

  QuoteService(this._apiService) {
    // ✅ Initialiser ApiClient pour bénéficier des corrections d'encodage
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }

  // ✅ MÉTHODE CORRIGÉE: createQuoteRequest
  Future<QuoteRequest> createQuoteRequest(QuoteRequest quoteRequest) async {
    try {
      // ✅ Debug: Log des données envoyées
      final requestData = quoteRequest.toJson();
      print('📤 Données envoyées au serveur: $requestData');

      // ✅ Utiliser ApiClient au lieu de http.post
      final responseData = await _apiClient.post(
        'quote-requests/',
        data: requestData,
        requireAuth: true
      );

      print('✅ Réponse reçue du serveur');
      print('✅ Données reçues: $responseData'); // ✅ Debug crucial
      
      // ✅ Vérification avant parsing (responseData déjà décodé par ApiClient)
      if (responseData == null) {
        throw Exception('Réponse vide du serveur');
      }
      
      // ✅ Vérifier l'encodage des données texte
      if (responseData['description'] != null) {
        print('✅ Description de la demande: ${responseData['description']} (encodage correct)');
      }
      
      return QuoteRequest.fromJson(responseData);
    } catch (e) {
      print("💥 Erreur dans createQuoteRequest: $e");
      print("💥 Type d'erreur: ${e.runtimeType}");
      rethrow;
    }
  }

  // ✅ MÉTHODE CORRIGÉE: getUserQuoteRequests
  Future<List<QuoteRequest>> getUserQuoteRequests() async {
    try {
      print('📋 Récupération des demandes de devis utilisateur...');
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('quote-requests/', requireAuth: true);
      
      print('✅ Réponse reçue pour les demandes utilisateur');
      
      if (responseData != null) {
        // ✅ Gérer les données déjà décodées par ApiClient
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        print('✅ ${data.length} demandes de devis trouvées');
        
        final quoteRequests = data.map((item) {
          // ✅ Debug encodage des demandes
          if (item['description'] != null) {
            print('✅ Demande: ${item['description']} (encodage correct)');
          }
          return QuoteRequest.fromJson(item);
        }).toList();
        
        return quoteRequests;
      } else {
        print('❌ Réponse nulle pour les demandes de devis');
        return [];
      }
    } catch (e) {
      print('❌ Error in getUserQuoteRequests: $e');
      rethrow;
    }
  }

  // ✅ MÉTHODE CORRIGÉE: updateQuoteRequestStatus
  Future<QuoteRequest> updateQuoteRequestStatus(
      int quoteRequestId, String status) async {
    try {
      print('🔄 Mise à jour du statut de la demande $quoteRequestId vers: $status');
      
      // ✅ Utiliser ApiClient au lieu de http.post
      final responseData = await _apiClient.post(
        'quote-requests/$quoteRequestId/update_status/',
        data: {'status': status},
        requireAuth: true
      );

      print('✅ Statut mis à jour avec succès');
      
      if (responseData != null) {
        // ✅ Debug encodage de la réponse
        if (responseData['description'] != null) {
          print('✅ Demande mise à jour: ${responseData['description']} (encodage correct)');
        }
        
        return QuoteRequest.fromJson(responseData);
      } else {
        throw Exception('Réponse nulle lors de la mise à jour du statut');
      }
    } catch (e) {
      print('❌ Error in updateQuoteRequestStatus: $e');
      rethrow;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Récupérer les demandes de devis pour un prestataire
  Future<List<QuoteRequest>> getProviderQuoteRequests() async {
    try {
      print('📋 Récupération des demandes de devis pour le prestataire...');
      
      // ✅ Utiliser ApiClient
      final responseData = await _apiClient.get('quote-requests/provider/', requireAuth: true);
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        print('✅ ${data.length} demandes trouvées pour le prestataire');
        
        final quoteRequests = data.map((item) {
          // ✅ Debug encodage
          if (item['description'] != null) {
            print('✅ Demande prestataire: ${item['description']}');
          }
          return QuoteRequest.fromJson(item);
        }).toList();
        
        return quoteRequests;
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error in getProviderQuoteRequests: $e');
      rethrow;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Récupérer une demande de devis spécifique
  Future<QuoteRequest?> getQuoteRequestById(int quoteRequestId) async {
    try {
      print('🔍 Récupération de la demande de devis $quoteRequestId...');
      
      // ✅ Utiliser ApiClient
      final responseData = await _apiClient.get('quote-requests/$quoteRequestId/', requireAuth: true);
      
      if (responseData != null) {
        // ✅ Debug encodage
        if (responseData['description'] != null) {
          print('✅ Demande récupérée: ${responseData['description']} (encodage correct)');
        }
        
        return QuoteRequest.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error in getQuoteRequestById: $e');
      rethrow;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Supprimer une demande de devis
  Future<bool> deleteQuoteRequest(int quoteRequestId) async {
    try {
      print('🗑️ Suppression de la demande de devis $quoteRequestId...');
      
      // ✅ Utiliser ApiClient
      await _apiClient.delete('quote-requests/$quoteRequestId/', requireAuth: true);
      
      print('✅ Demande de devis supprimée avec succès');
      return true;
    } catch (e) {
      print('❌ Error in deleteQuoteRequest: $e');
      return false;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Mettre à jour une demande de devis
  Future<QuoteRequest> updateQuoteRequest(
      int quoteRequestId, QuoteRequest updatedQuoteRequest) async {
    try {
      print('📝 Mise à jour de la demande de devis $quoteRequestId...');
      
      // ✅ Utiliser ApiClient
      final responseData = await _apiClient.put(
        'quote-requests/$quoteRequestId/',
        data: updatedQuoteRequest.toJson(),
        requireAuth: true
      );

      if (responseData != null) {
        // ✅ Debug encodage
        if (responseData['description'] != null) {
          print('✅ Demande mise à jour: ${responseData['description']} (encodage correct)');
        }
        
        return QuoteRequest.fromJson(responseData);
      } else {
        throw Exception('Réponse nulle lors de la mise à jour');
      }
    } catch (e) {
      print('❌ Error in updateQuoteRequest: $e');
      rethrow;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Rechercher des demandes de devis
  Future<List<QuoteRequest>> searchQuoteRequests(String query) async {
    try {
      print('🔍 Recherche de demandes de devis: "$query"...');
      
      // ✅ Utiliser ApiClient
      final responseData = await _apiClient.get(
        'quote-requests/search/?q=${Uri.encodeComponent(query)}',
        requireAuth: true
      );
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        print('✅ ${data.length} demandes trouvées pour "$query"');
        
        final quoteRequests = data.map((item) {
          // ✅ Debug encodage des résultats de recherche
          if (item['description'] != null) {
            print('✅ Résultat: ${item['description']} (encodage correct)');
          }
          return QuoteRequest.fromJson(item);
        }).toList();
        
        return quoteRequests;
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error in searchQuoteRequests: $e');
      return [];
    }
  }
}