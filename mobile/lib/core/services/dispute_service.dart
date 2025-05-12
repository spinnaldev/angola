// lib/core/services/dispute_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/dispute.dart';
import 'api_service.dart';

class DisputeService {
  final ApiService _apiService;
  
  DisputeService(this._apiService);
  
  // Créer un nouveau litige
  Future<Dispute> createDispute(Dispute dispute) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/disputes/'),
        headers: headers,
        body: json.encode(dispute.toJson()),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Dispute.fromJson(data);
      } else {
        throw Exception('Failed to create dispute: ${response.body}');
      }
    } catch (e) {
      print('Error in createDispute: $e');
      rethrow;
    }
  }
  
  // Récupérer les litiges de l'utilisateur (client ou prestataire)
  Future<List<Dispute>> getUserDisputes() async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/disputes/'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => Dispute.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get user disputes: ${response.body}');
      }
    } catch (e) {
      print('Error in getUserDisputes: $e');
      rethrow;
    }
  }
  
  // Ajouter une preuve à un litige
  Future<DisputeEvidence> addDisputeEvidence(
    int disputeId, 
    String description, 
    File file
  ) async {
    try {
      // Utiliser multipart request pour pouvoir envoyer des fichiers
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/disputes/$disputeId/add_evidence/'),
      );
      
      // Ajouter les headers d'authentification
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);
      
      // Ajouter les champs du formulaire
      request.fields['description'] = description;
      
      // Ajouter le fichier
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      request.files.add(
        http.MultipartFile(
          'file',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: fileName,
          contentType: MediaType(
            _getMediaType(fileExtension),
            fileExtension,
          ),
        ),
      );
      
      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return DisputeEvidence.fromJson(data);
      } else {
        throw Exception('Failed to add evidence: ${response.body}');
      }
    } catch (e) {
      print('Error in addDisputeEvidence: $e');
      rethrow;
    }
  }
  
  // Mettre à jour le statut d'un litige (principalement pour les administrateurs)
  Future<Dispute> updateDisputeStatus(int disputeId, String status, String resolutionNote) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/disputes/$disputeId/update_status/'),
        headers: headers,
        body: json.encode({
          'status': status,
          'resolution_note': resolutionNote,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Dispute.fromJson(data);
      } else {
        throw Exception('Failed to update dispute status: ${response.body}');
      }
    } catch (e) {
      print('Error in updateDisputeStatus: $e');
      rethrow;
    }
  }
  
  // Utilitaire pour déterminer le type de média
  String _getMediaType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image';
      case 'png':
        return 'image';
      case 'pdf':
        return 'application';
      case 'doc':
      case 'docx':
        return 'application';
      case 'mp4':
        return 'video';
      default:
        return 'application';
    }
  }
}