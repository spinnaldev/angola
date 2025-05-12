// lib/core/services/provider_verification_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/provider_verification.dart';
import 'api_service.dart';

class ProviderVerificationService {
  final ApiService _apiService;
  
  ProviderVerificationService(this._apiService);
  
  // Récupérer les informations de vérification du prestataire
  Future<ProviderVerification?> getProviderVerification() async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/provider/verification/'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProviderVerification.fromJson(data);
      } else if (response.statusCode == 404) {
        // Pas encore de vérification
        return null;
      } else {
        throw Exception('Failed to get provider verification: ${response.body}');
      }
    } catch (e) {
      print('Error in getProviderVerification: $e');
      rethrow;
    }
  }
  
  // Soumettre/Mettre à jour les informations de vérification pour une entreprise
  Future<ProviderVerification> submitBusinessVerification(
    String businessName,
    String businessNif,
    String businessRegistrationNumber,
    File? registrationDoc,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider/verification/business/'),
      );
      
      // Ajouter les headers d'authentification
      final headers = await _apiService.getHeaders();
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
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ProviderVerification.fromJson(data);
      } else {
        throw Exception('Failed to submit business verification: ${response.body}');
      }
    } catch (e) {
      print('Error in submitBusinessVerification: $e');
      rethrow;
    }
  }
  
  // Soumettre/Mettre à jour les informations de vérification pour un particulier
  Future<ProviderVerification> submitIndividualVerification(
    File idCardFront,
    File idCardBack,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider/verification/individual/'),
      );
      
      // Ajouter les headers d'authentification
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);
      
      // Indiquer qu'il s'agit d'un particulier
      request.fields['is_business'] = 'false';
      
      // Ajouter les images de la pièce d'identité
      final frontFileName = idCardFront.path.split('/').last;
      final frontFileExtension = frontFileName.split('.').last.toLowerCase();
      
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
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ProviderVerification.fromJson(data);
      } else {
        throw Exception('Failed to submit individual verification: ${response.body}');
      }
    } catch (e) {
      print('Error in submitIndividualVerification: $e');
      rethrow;
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