// mobile/lib/core/services/client_verification_service.dart
// CRÉEZ ce nouveau fichier

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../models/client_verification.dart';
import 'api_service.dart';
import '../api/api_client.dart';

class ClientVerificationService {
  final ApiService _apiService;
  final ApiClient _apiClient;

  ClientVerificationService({
    required ApiService apiService,
    required ApiClient apiClient,
  })  : _apiService = apiService,
        _apiClient = apiClient;

  /// Récupérer le statut de vérification actuel
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      print('📱 Récupération statut vérification client...');
      
      final response = await _apiClient.get('/client-verification/my-status/');
      
      print('✅ Statut récupéré : ${response['verification_status'] ?? 'not_started'}');
      return response;
      
    } catch (e) {
      print('❌ Erreur récupération statut : $e');
      rethrow;
    }
  }

  /// Soumettre une vérification avec carte d'identité (recto + verso)
  Future<ClientVerification> submitIndividualVerificationWithId({
    required File idCardFront,
    required File idCardBack,
  }) async {
    try {
      print('🆔 Soumission vérification client (carte d\'identité)...');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/client-verification/submit-individual-id/'),
      );
      
      // Utiliser les headers de ApiClient pour cohérence
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // Ajouter les fichiers
      await _addFileToRequest(request, 'id_card_front', idCardFront);
      await _addFileToRequest(request, 'id_card_back', idCardBack);
      
      print('📤 Envoi de la requête...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Réponse reçue : ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Vérification carte ID soumise avec succès');
        
        // Le backend retourne { "message": "...", "verification": {...} }
        if (data['verification'] != null) {
          return ClientVerification.fromJson(data['verification']);
        } else {
          return ClientVerification.fromJson(data);
        }
      } else {
        print('❌ Erreur soumission carte ID : ${response.statusCode}');
        print('Body: ${response.body}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de la soumission');
      }
    } catch (e) {
      print('❌ Exception soumission carte ID : $e');
      rethrow;
    }
  }

  /// Soumettre une vérification avec passeport
  Future<ClientVerification> submitIndividualVerificationWithPassport({
    required File passportImage,
  }) async {
    try {
      print('🛂 Soumission vérification client (passeport)...');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/client-verification/submit-passport/'),
      );
      
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // Ajouter le fichier passeport
      await _addFileToRequest(request, 'passport_image', passportImage);
      
      print('📤 Envoi de la requête...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Réponse reçue : ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Vérification passeport soumise avec succès');
        
        if (data['verification'] != null) {
          return ClientVerification.fromJson(data['verification']);
        } else {
          return ClientVerification.fromJson(data);
        }
      } else {
        print('❌ Erreur soumission passeport : ${response.statusCode}');
        print('Body: ${response.body}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Erreur lors de la soumission');
      }
    } catch (e) {
      print('❌ Exception soumission passeport : $e');
      rethrow;
    }
  }

  /// Méthode utilitaire pour ajouter un fichier à la requête
  Future<void> _addFileToRequest(
    http.MultipartRequest request,
    String fieldName,
    File file,
  ) async {
    try {
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: basename(file.path),
      );
      request.files.add(multipartFile);
      print('✅ Fichier ajouté : $fieldName (${fileBytes.length} bytes)');
    } catch (e) {
      print('❌ Erreur ajout fichier $fieldName : $e');
      rethrow;
    }
  }

  /// Vérifier si l'utilisateur a une vérification en cours
  Future<bool> hasVerification() async {
    try {
      final status = await getVerificationStatus();
      return status['has_verification'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Vérifier si l'utilisateur est vérifié
  Future<bool> isVerified() async {
    try {
      final status = await getVerificationStatus();
      return status['is_verified'] == true;
    } catch (e) {
      return false;
    }
  }
}