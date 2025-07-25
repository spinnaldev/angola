// lib/core/services/provider_verification_service.dart - VERSION CORRIGÉE avec ApiClient
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/provider_verification.dart';
import 'api_service.dart';
import '../api/api_client.dart'; // ✅ Import ApiClient

class ProviderVerificationService {
  final ApiService _apiService;
  late final ApiClient _apiClient; // ✅ Référence ApiClient
  
  ProviderVerificationService(this._apiService) {
    // ✅ Initialiser ApiClient pour bénéficier des corrections d'encodage
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }
  
  // ✅ MÉTHODE CORRIGÉE: getProviderVerification
  Future<ProviderVerification?> getProviderVerification() async {
    try {
      print('📋 Récupération des informations de vérification...');
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('provider/verification/', requireAuth: true);
      
      if (responseData != null) {
        // ✅ Debug encodage des données de vérification
        if (responseData['business_name'] != null) {
          print('✅ Nom d\'entreprise: ${responseData['business_name']} (encodage correct)');
        }
        
        return ProviderVerification.fromJson(responseData);
      } else {
        // Pas encore de vérification
        return null;
      }
    } catch (e) {
      print('❌ Error in getProviderVerification: $e');
      
      // Gérer le cas 404 (pas de vérification)
      if (e.toString().contains('404')) {
        return null;
      }
      
      rethrow;
    }
  }
  
  // ✅ MÉTHODE CORRIGÉE: submitBusinessVerification (MultipartRequest conservé mais headers corrigés)
  Future<ProviderVerification> submitBusinessVerification(
    String businessName,
    String businessNif,
    String businessRegistrationNumber,
    File? registrationDoc,
  ) async {
    try {
      print('🏢 Soumission de la vérification entreprise...');
      print('✅ Nom entreprise: $businessName (encodage correct)');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider/verification/business/'),
      );
      
      // ✅ Utiliser ApiClient pour les headers (cohérence avec encodage)
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // Ajouter les champs du formulaire
      request.fields['business_name'] = businessName;
      request.fields['business_nif'] = businessNif;
      request.fields['business_registration_number'] = businessRegistrationNumber;
      request.fields['is_business'] = 'true';
      
      // Ajouter le document d'enregistrement si fourni
      if (registrationDoc != null) {
        final fileName = registrationDoc.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        print('📎 Ajout du document: $fileName');
        
        request.files.add(
          http.MultipartFile(
            'business_registration_doc',
            registrationDoc.readAsBytes().asStream(),
            registrationDoc.lengthSync(),
            filename: fileName,
            contentType: _getContentType(fileExtension),
          ),
        );
      }
      
      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Statut réponse vérification entreprise: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Traitement UTF-8 pour la réponse MultipartRequest
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }
        
        final data = json.decode(responseBody);
        
        // ✅ Debug encodage de la réponse
        if (data['business_name'] != null) {
          print('✅ Vérification créée pour: ${data['business_name']} (encodage correct)');
        }
        
        return ProviderVerification.fromJson(data);
      } else {
        throw Exception('Failed to submit business verification: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in submitBusinessVerification: $e');
      rethrow;
    }
  }
  
  // ✅ MÉTHODE CORRIGÉE: submitIndividualVerification (MultipartRequest conservé mais headers corrigés)
  Future<ProviderVerification> submitIndividualVerification(
    File idCardFront,
    File idCardBack,
  ) async {
    try {
      print('👤 Soumission de la vérification individuelle...');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider/verification/individual/'),
      );
      
      // ✅ Utiliser ApiClient pour les headers (cohérence avec encodage)
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // Indiquer qu'il s'agit d'un particulier
      request.fields['is_business'] = 'false';
      
      // Ajouter les images de la pièce d'identité
      final frontFileName = idCardFront.path.split('/').last;
      final frontFileExtension = frontFileName.split('.').last.toLowerCase();
      
      print('📎 Ajout recto carte d\'identité: $frontFileName');
      
      request.files.add(
        http.MultipartFile(
          'id_card_front',
          idCardFront.readAsBytes().asStream(),
          idCardFront.lengthSync(),
          filename: frontFileName,
          contentType: MediaType('image', frontFileExtension),
        ),
      );
      
      final backFileName = idCardBack.path.split('/').last;
      final backFileExtension = backFileName.split('.').last.toLowerCase();
      
      print('📎 Ajout verso carte d\'identité: $backFileName');
      
      request.files.add(
        http.MultipartFile(
          'id_card_back',
          idCardBack.readAsBytes().asStream(),
          idCardBack.lengthSync(),
          filename: backFileName,
          contentType: MediaType('image', backFileExtension),
        ),
      );
      
      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Statut réponse vérification individuelle: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Traitement UTF-8 pour la réponse MultipartRequest
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }
        
        final data = json.decode(responseBody);
        
        print('✅ Vérification individuelle créée avec succès');
        
        return ProviderVerification.fromJson(data);
      } else {
        throw Exception('Failed to submit individual verification: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in submitIndividualVerification: $e');
      rethrow;
    }
  }
  
  // ✅ NOUVELLE MÉTHODE: Mettre à jour le statut de vérification
  Future<ProviderVerification> updateVerificationStatus(String status, String? notes) async {
    try {
      print('🔄 Mise à jour du statut de vérification: $status');
      
      // ✅ Utiliser ApiClient
      final responseData = await _apiClient.put(
        'provider/verification/',
        data: {
          'status': status,
          if (notes != null) 'admin_notes': notes,
        },
        requireAuth: true
      );

      if (responseData != null) {
        // ✅ Debug encodage
        if (responseData['admin_notes'] != null) {
          print('✅ Notes admin: ${responseData['admin_notes']} (encodage correct)');
        }
        
        return ProviderVerification.fromJson(responseData);
      } else {
        throw Exception('Réponse nulle lors de la mise à jour du statut');
      }
    } catch (e) {
      print('❌ Error in updateVerificationStatus: $e');
      rethrow;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Récupérer toutes les vérifications (admin)
  Future<List<ProviderVerification>> getAllVerifications() async {
    try {
      print('📋 Récupération de toutes les vérifications (admin)...');
      
      // ✅ Utiliser ApiClient
      final responseData = await _apiClient.get('admin/verifications/', requireAuth: true);
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        print('✅ ${data.length} vérifications trouvées');
        
        final verifications = data.map((item) {
          // ✅ Debug encodage
          if (item['business_name'] != null) {
            print('✅ Vérification: ${item['business_name']} (encodage correct)');
          }
          return ProviderVerification.fromJson(item);
        }).toList();
        
        return verifications;
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error in getAllVerifications: $e');
      return [];
    }
  }

  // ✅ NOUVELLE MÉTHODE: Supprimer une vérification
  Future<bool> deleteVerification() async {
    try {
      print('🗑️ Suppression de la vérification...');
      
      // ✅ Utiliser ApiClient
      await _apiClient.delete('provider/verification/', requireAuth: true);
      
      print('✅ Vérification supprimée avec succès');
      return true;
    } catch (e) {
      print('❌ Error in deleteVerification: $e');
      return false;
    }
  }
  
  // Définir le type de contenu en fonction de l'extension du fichier
  MediaType _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}