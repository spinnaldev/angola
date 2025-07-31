import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/provider_verification.dart';
import '../api/api_client.dart';
import 'api_service.dart';

class ProviderVerificationService {
  final ApiService _apiService;
  late final ApiClient _apiClient;
  
  ProviderVerificationService(this._apiService) {
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }
  
  /// Récupérer le statut de vérification du prestataire connecté
  Future<ProviderVerification?> getMyVerificationStatus() async {
    try {
      print('📋 Récupération du statut de vérification prestataire...');
      
      final responseData = await _apiClient.get(
        'provider-verification/my-status/', 
        requireAuth: true
      );
      
      if (responseData != null) {
        // Si verification_status existe, c'est une vérification existante
        if (responseData['verification_status'] != null) {
          return ProviderVerification.fromJson(responseData);
        }
        // Sinon, pas encore de vérification
        return null;
      }
      
      return null;
    } catch (e) {
      print('❌ Erreur récupération statut vérification: $e');
      
      // Gérer le cas 404 (pas de vérification)
      if (e.toString().contains('404')) {
        return null;
      }
      
      rethrow;
    }
  }
  
  /// Soumettre une vérification d'entreprise
  Future<ProviderVerification> submitBusinessVerification({
    required String businessName,
    String? businessNif,
    String? businessRegistrationNumber,
    required File idCardFront,
    required File idCardBack,
    File? businessRegistrationDoc,
  }) async {
    try {
      print('🏢 Soumission vérification entreprise...');
      print('✅ Nom entreprise: $businessName');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider-verification/submit-business/'),
      );
      
      // Utiliser les headers de ApiClient pour cohérence
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // Champs du formulaire
      request.fields['business_name'] = businessName;
      if (businessNif != null) {
        request.fields['business_nif'] = businessNif;
      }
      if (businessRegistrationNumber != null) {
        request.fields['business_registration_number'] = businessRegistrationNumber;
      }
      request.fields['is_business'] = 'true';
      request.fields['document_type'] = 'id_card';
      
      // Ajouter les fichiers
      await _addFileToRequest(request, 'id_card_front', idCardFront);
      await _addFileToRequest(request, 'id_card_back', idCardBack);
      
      if (businessRegistrationDoc != null) {
        await _addFileToRequest(request, 'business_registration_doc', businessRegistrationDoc);
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Vérification entreprise soumise avec succès');
        
        // Le backend retourne { "message": "...", "verification": {...} }
        if (data['verification'] != null) {
          return ProviderVerification.fromJson(data['verification']);
        } else {
          return ProviderVerification.fromJson(data);
        }
      } else {
        print('❌ Erreur soumission entreprise: ${response.statusCode}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de la soumission');
      }
    } catch (e) {
      print('❌ Exception soumission entreprise: $e');
      rethrow;
    }
  }
  
  /// Soumettre une vérification individuelle avec carte d'identité
  Future<ProviderVerification> submitIndividualVerificationWithId({
    required File idCardFront,
    required File idCardBack,
  }) async {
    try {
      print('👤 Soumission vérification individuelle (carte ID)...');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider-verification/submit-individual/'),
      );
      
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // Champs du formulaire
      request.fields['is_business'] = 'false';
      request.fields['document_type'] = 'id_card';
      
      // Ajouter les fichiers
      await _addFileToRequest(request, 'id_card_front', idCardFront);
      await _addFileToRequest(request, 'id_card_back', idCardBack);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Vérification carte ID soumise avec succès');
        
        if (data['verification'] != null) {
          return ProviderVerification.fromJson(data['verification']);
        } else {
          return ProviderVerification.fromJson(data);
        }
      } else {
        print('❌ Erreur soumission carte ID: ${response.statusCode}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de la soumission');
      }
    } catch (e) {
      print('❌ Exception soumission carte ID: $e');
      rethrow;
    }
  }
  
  /// Soumettre une vérification individuelle avec passeport
  Future<ProviderVerification> submitIndividualVerificationWithPassport({
    required File passportImage,
  }) async {
    try {
      print('🛂 Soumission vérification individuelle (passeport)...');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider-verification/submit-individual/'),
      );
      
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // Champs du formulaire
      request.fields['is_business'] = 'false';
      request.fields['document_type'] = 'passport';
      
      // Ajouter le fichier passeport
      await _addFileToRequest(request, 'passport_image', passportImage);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Vérification passeport soumise avec succès');
        
        if (data['verification'] != null) {
          return ProviderVerification.fromJson(data['verification']);
        } else {
          return ProviderVerification.fromJson(data);
        }
      } else {
        print('❌ Erreur soumission passeport: ${response.statusCode}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de la soumission');
      }
    } catch (e) {
      print('❌ Exception soumission passeport: $e');
      rethrow;
    }
  }
  
  /// Renvoyer des documents après rejet
  Future<ProviderVerification> resendDocuments({
    required int verificationId,
    File? idCardFront,
    File? idCardBack,
    File? passportImage,
    File? businessRegistrationDoc,
    String? businessName,
    String? businessNif,
    String? businessRegistrationNumber,
  }) async {
    try {
      print('🔄 Renvoi de documents...');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider-verification/$verificationId/resend-documents/'),
      );
      
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // Ajouter les champs texte si fournis
      if (businessName != null) {
        request.fields['business_name'] = businessName;
      }
      if (businessNif != null) {
        request.fields['business_nif'] = businessNif;
      }
      if (businessRegistrationNumber != null) {
        request.fields['business_registration_number'] = businessRegistrationNumber;
      }
      
      // Ajouter les fichiers si fournis
      if (idCardFront != null) {
        await _addFileToRequest(request, 'id_card_front', idCardFront);
      }
      if (idCardBack != null) {
        await _addFileToRequest(request, 'id_card_back', idCardBack);
      }
      if (passportImage != null) {
        await _addFileToRequest(request, 'passport_image', passportImage);
      }
      if (businessRegistrationDoc != null) {
        await _addFileToRequest(request, 'business_registration_doc', businessRegistrationDoc);
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Documents renvoyés avec succès');
        
        if (data['verification'] != null) {
          return ProviderVerification.fromJson(data['verification']);
        } else {
          return ProviderVerification.fromJson(data);
        }
      } else {
        print('❌ Erreur renvoi documents: ${response.statusCode}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors du renvoi');
      }
    } catch (e) {
      print('❌ Exception renvoi documents: $e');
      rethrow;
    }
  }
  
  /// Récupérer les exigences de vérification
  Future<Map<String, dynamic>> getVerificationRequirements() async {
    try {
      final responseData = await _apiClient.get(
        'provider-verification/requirements/', 
        requireAuth: true
      );
      
      if (responseData != null) {
        return responseData;
      }
      
      // Fallback avec exigences par défaut
      return {
        'document_types': [
          {
            'value': 'id_card',
            'label': 'Carte d\'identité',
            'description': 'Les deux faces de la carte d\'identité sont requises',
            'required_files': ['id_card_front', 'id_card_back']
          },
          {
            'value': 'passport',
            'label': 'Passeport',
            'description': 'Page principale du passeport avec photo',
            'required_files': ['passport_image']
          }
        ],
        'file_requirements': {
          'max_size_mb': 5,
          'allowed_formats': ['jpg', 'jpeg', 'png', 'pdf'],
          'image_min_resolution': '800x600'
        }
      };
    } catch (e) {
      print('❌ Erreur récupération exigences: $e');
      rethrow;
    }
  }
  
  /// Méthode utilitaire pour ajouter un fichier à la requête
  Future<void> _addFileToRequest(
    http.MultipartRequest request, 
    String fieldName, 
    File file
  ) async {
    final fileName = file.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();
    
    // Déterminer le type MIME
    MediaType? contentType;
    if (['jpg', 'jpeg'].contains(fileExtension)) {
      contentType = MediaType('image', 'jpeg');
    } else if (fileExtension == 'png') {
      contentType = MediaType('image', 'png');
    } else if (fileExtension == 'pdf') {
      contentType = MediaType('application', 'pdf');
    }
    
    final multipartFile = await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: contentType,
    );
    
    request.files.add(multipartFile);
  }
}