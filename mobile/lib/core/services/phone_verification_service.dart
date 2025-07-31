
import '../models/phone_verification.dart';
import 'package:teyago/core/api/api_client.dart';
import 'package:teyago/core/services/api_service.dart';

class PhoneVerificationService {
  final ApiService _apiService;
  late final ApiClient _apiClient;
  
  PhoneVerificationService(this._apiService) {
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }
  
  /// Récupérer le statut de vérification téléphone
  Future<PhoneVerification?> getMyVerificationStatus() async {
    try {
      print('📞 Récupération du statut de vérification téléphone...');
      
      final responseData = await _apiClient.get(
        'phone-verification/my-status/', 
        requireAuth: true
      );
      
      if (responseData != null) {
        // Si status existe, c'est une vérification existante
        if (responseData['status'] != null && responseData['status'] != 'not_started') {
          return PhoneVerification.fromJson(responseData);
        }
        // Sinon, pas encore de vérification
        return null;
      }
      
      return null;
    } catch (e) {
      print('❌ Erreur récupération statut téléphone: $e');
      
      // Gérer le cas 404 (pas de vérification)
      if (e.toString().contains('404')) {
        return null;
      }
      
      rethrow;
    }
  }
  
  /// Envoyer un code de vérification par SMS
  Future<PhoneVerification> sendVerificationCode(String phoneNumber) async {
    try {
      print('📱 Envoi du code de vérification à $phoneNumber...');
      
      final responseData = await _apiClient.post(
        'phone-verification/send-code/',
        data: {'phone_number': phoneNumber},
        requireAuth: true,
      );
      
      if (responseData != null) {
        print('✅ Code envoyé avec succès');
        
        // Le backend retourne { "message": "...", "verification": {...}, "debug_code": "..." }
        if (responseData['verification'] != null) {
          final verification = PhoneVerification.fromJson(responseData['verification']);
          
          // En développement, afficher le code de debug
          if (responseData['debug_code'] != null) {
            print('🔍 CODE DEBUG: ${responseData['debug_code']}');
          }
          
          return verification;
        } else {
          return PhoneVerification.fromJson(responseData);
        }
      } else {
        throw Exception('Réponse nulle lors de l\'envoi du code');
      }
    } catch (e) {
      print('❌ Erreur envoi code SMS: $e');
      rethrow;
    }
  }
  
  /// Vérifier le code SMS reçu
  Future<PhoneVerification> verifyCode(String code) async {
    try {
      print('✅ Vérification du code: $code');
      
      final responseData = await _apiClient.post(
        'phone-verification/verify-code/',
        data: {'code': code},
        requireAuth: true,
      );
      
      if (responseData != null) {
        if (responseData['verification'] != null) {
          print('✅ Code vérifié avec succès');
          return PhoneVerification.fromJson(responseData['verification']);
        } else {
          return PhoneVerification.fromJson(responseData);
        }
      } else {
        throw Exception('Réponse nulle lors de la vérification');
      }
    } catch (e) {
      print('❌ Erreur vérification code: $e');
      
      // Analyser l'erreur pour donner un message plus spécifique
      if (e.toString().contains('Code incorrect')) {
        throw Exception('Code incorrect');
      } else if (e.toString().contains('expiré')) {
        throw Exception('Code expiré');
      } else if (e.toString().contains('tentatives')) {
        throw Exception('Trop de tentatives');
      }
      
      rethrow;
    }
  }
  
  /// Renvoyer le code de vérification
  Future<PhoneVerification> resendCode() async {
    try {
      print('🔄 Renvoi du code de vérification...');
      
      final responseData = await _apiClient.post(
        'phone-verification/resend-code/',
        data: {},
        requireAuth: true,
      );
      
      if (responseData != null) {
        print('✅ Nouveau code envoyé avec succès');
        
        if (responseData['verification'] != null) {
          final verification = PhoneVerification.fromJson(responseData['verification']);
          
          // En développement, afficher le code de debug
          if (responseData['debug_code'] != null) {
            print('🔍 NOUVEAU CODE DEBUG: ${responseData['debug_code']}');
          }
          
          return verification;
        } else {
          return PhoneVerification.fromJson(responseData);
        }
      } else {
        throw Exception('Réponse nulle lors du renvoi du code');
      }
    } catch (e) {
      print('❌ Erreur renvoi code: $e');
      
      // Analyser l'erreur
      if (e.toString().contains('429')) {
        throw Exception('Vous devez attendre avant de demander un nouveau code');
      }
      
      rethrow;
    }
  }
}
