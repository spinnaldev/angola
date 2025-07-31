


import 'package:teyago/core/api/api_client.dart';
import 'package:teyago/core/services/api_service.dart';

class VerificationStatusService {
  final ApiService _apiService;
  late final ApiClient _apiClient;
  
  VerificationStatusService(this._apiService) {
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }
  
  /// Récupérer le statut de vérification global de l'utilisateur
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      print('🔍 Récupération du statut de vérification global...');
      
      final responseData = await _apiClient.get(
        'verification/status/', 
        requireAuth: true
      );
      
      if (responseData != null) {
        return responseData;
      }
      
      throw Exception('Réponse nulle lors de la récupération du statut');
    } catch (e) {
      print('❌ Erreur récupération statut global: $e');
      rethrow;
    }
  }
  
  /// Vérifier si une action spécifique est autorisée
  Future<bool> checkActionPermission(String actionDescription) async {
    try {
      print('🔒 Vérification permission pour: $actionDescription');
      
      final responseData = await _apiClient.post(
        'verification/check-action/',
        data: {'action': actionDescription},
        requireAuth: true,
      );
      
      if (responseData != null) {
        return responseData['allowed'] == true;
      }
      
      return false;
    } catch (e) {
      print('❌ Erreur vérification permission: $e');
      
      // Si l'erreur contient verification_required, c'est un blocage
      if (e.toString().contains('verification_required')) {
        return false;
      }
      
      rethrow;
    }
  }
}