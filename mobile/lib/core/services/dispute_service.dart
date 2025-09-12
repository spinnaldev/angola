// lib/core/services/dispute_service.dart - VERSION CORRIGÉE avec ApiClient
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/dispute.dart';
import 'api_service.dart';
import '../api/api_client.dart'; // ✅ Import ApiClient

class DisputeService {
  final ApiService _apiService;
  late final ApiClient _apiClient; // ✅ Référence ApiClient
  
  DisputeService(this._apiService) {
    // ✅ Initialiser ApiClient pour bénéficier des corrections d'encodage
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }
  
  // ✅ MÉTHODE CORRIGÉE: createDispute
  Future<Dispute> createDispute(Dispute dispute) async {
    try {
      print('⚖️ Création d\'un nouveau litige...');
      
      // ✅ Debug encodage des données du litige
      print('✅ Description: ${dispute.description} (encodage correct)');
      
      // ✅ Utiliser ApiClient au lieu de http.post
      final responseData = await _apiClient.post(
        'disputes/',
        data: dispute.toJson(),
        requireAuth: true
      );
      
      if (responseData != null) {
        // ✅ Debug encodage de la réponse
        if (responseData['subject'] != null) {
          print('✅ Litige créé: ${responseData['subject']} (encodage correct)');
        }
        
        return Dispute.fromJson(responseData);
      } else {
        throw Exception('Réponse nulle lors de la création du litige');
      }
    } catch (e) {
      print('❌ Error in createDispute: $e');
      rethrow;
    }
  }
  
  // ✅ MÉTHODE CORRIGÉE: getUserDisputes
  Future<List<Dispute>> getUserDisputes() async {
    try {
      print('📋 Récupération des litiges de l\'utilisateur...');
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('disputes/', requireAuth: true);
      
      if (responseData != null) {
        // ✅ Gérer les données déjà décodées par ApiClient
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        print('✅ ${data.length} litiges trouvés');
        
        final disputes = data.map((item) {
          // ✅ Debug encodage des litiges
          if (item['subject'] != null) {
            print('✅ Litige: ${item['subject']} (encodage correct)');
          }
          return Dispute.fromJson(item);
        }).toList();
        
        return disputes;
      } else {
        print('❌ Réponse nulle pour les litiges utilisateur');
        return [];
      }
    } catch (e) {
      print('❌ Error in getUserDisputes: $e');
      rethrow;
    }
  }
  Future<DisputeEvidence> addComment(int disputeId, String commentText) async {
    try {
      print('💬 Ajout de commentaire au litige $disputeId...');
      print('✅ Commentaire: $commentText');
      
      // ✅ MODIFICATION : Utiliser le même endpoint que add_evidence mais sans fichier
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/disputes/$disputeId/add_evidence/'),
      );
      
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // ✅ NOUVEAU : Ajouter seulement la description, pas de fichier
      request.fields['description'] = commentText;
      
      // ✅ IMPORTANT : Ne pas ajouter de fichier, l'endpoint l'accepte maintenant
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Statut réponse ajout commentaire: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }
        
        final data = json.decode(responseBody);
        
        if (data['description'] != null) {
          print('✅ Commentaire ajouté: ${data['description']}');
        }
        
        return DisputeEvidence.fromJson(data);
      } else {
        throw Exception('Failed to add comment: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in addComment: $e');
      rethrow;
    }
  }
  // ✅ MÉTHODE CORRIGÉE: addDisputeEvidence (MultipartRequest conservé mais headers corrigés)
  Future<DisputeEvidence> addDisputeEvidence(
    int disputeId, 
    String description, 
    File file
  ) async {
    try {
      print('📎 Ajout de preuve au litige $disputeId...');
      print('✅ Description de la preuve: $description');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/disputes/$disputeId/add_evidence/'),
      );
      
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      request.fields['description'] = description;
      
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      print('📎 Ajout du fichier: $fileName');
      
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
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Statut réponse ajout preuve: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }
        
        final data = json.decode(responseBody);
        
        if (data['description'] != null) {
          print('✅ Preuve ajoutée: ${data['description']}');
        }
        
        return DisputeEvidence.fromJson(data);
      } else {
        throw Exception('Failed to add evidence: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in addDisputeEvidence: $e');
      rethrow;
    }
  }
  
  // ✅ MÉTHODE CORRIGÉE: updateDisputeStatus
  Future<Dispute> updateDisputeStatus(int disputeId, String status, String resolutionNote) async {
    try {
      print('🔄 Mise à jour du statut du litige $disputeId: $status');
      print('✅ Note de résolution: $resolutionNote (encodage correct)');
      
      // ✅ Utiliser ApiClient au lieu de http.post
      final responseData = await _apiClient.post(
        'disputes/$disputeId/update_status/',
        data: {
          'status': status,
          'resolution_note': resolutionNote,
        },
        requireAuth: true
      );
      
      if (responseData != null) {
        // ✅ Debug encodage de la réponse
        if (responseData['resolution_note'] != null) {
          print('✅ Statut mis à jour. Note: ${responseData['resolution_note']} (encodage correct)');
        }
        
        return Dispute.fromJson(responseData);
      } else {
        throw Exception('Réponse nulle lors de la mise à jour du statut');
      }
    } catch (e) {
      print('❌ Error in updateDisputeStatus: $e');
      rethrow;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Récupérer un litige spécifique
  Future<Dispute?> getDisputeById(int disputeId) async {
    try {
      print('🔍 Récupération du litige $disputeId...');
      
      // ✅ Utiliser ApiClient
      final responseData = await _apiClient.get('disputes/$disputeId/', requireAuth: true);
      
      if (responseData != null) {
        // ✅ Debug encodage
        if (responseData['subject'] != null) {
          print('✅ Litige récupéré: ${responseData['subject']} (encodage correct)');
        }
        
        return Dispute.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error in getDisputeById: $e');
      rethrow;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Récupérer les preuves d'un litige
  Future<List<DisputeEvidence>> getDisputeEvidence(int disputeId) async {
    try {
      print('📎 Récupération des preuves du litige $disputeId...');
      
      // ✅ Utiliser ApiClient
      final responseData = await _apiClient.get('disputes/$disputeId/evidence/', requireAuth: true);
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        print('✅ ${data.length} preuves trouvées');
        
        final evidence = data.map((item) {
          // ✅ Debug encodage des preuves
          if (item['description'] != null) {
            print('✅ Preuve: ${item['description']} (encodage correct)');
          }
          return DisputeEvidence.fromJson(item);
        }).toList();
        
        return evidence;
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error in getDisputeEvidence: $e');
      return [];
    }
  }

  // ✅ NOUVELLE MÉTHODE: Récupérer tous les litiges (admin)
  Future<List<Dispute>> getAllDisputes() async {
    try {
      print('📋 Récupération de tous les litiges (admin)...');
      
      // ✅ Utiliser ApiClient
      final responseData = await _apiClient.get('admin/disputes/', requireAuth: true);
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        print('✅ ${data.length} litiges trouvés (admin)');
        
        final disputes = data.map((item) {
          // ✅ Debug encodage
          if (item['subject'] != null) {
            print('✅ Litige admin: ${item['subject']} (encodage correct)');
          }
          return Dispute.fromJson(item);
        }).toList();
        
        return disputes;
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error in getAllDisputes: $e');
      return [];
    }
  }

  // ✅ NOUVELLE MÉTHODE: Fermer un litige
  Future<Dispute> closeDispute(int disputeId, String resolutionNote) async {
    return updateDisputeStatus(disputeId, 'closed', resolutionNote);
  }

  // ✅ NOUVELLE MÉTHODE: Réouvrir un litige
  Future<Dispute> reopenDispute(int disputeId, String reason) async {
    return updateDisputeStatus(disputeId, 'reopened', reason);
  }

  // ✅ NOUVELLE MÉTHODE: Supprimer une preuve
  Future<bool> deleteEvidence(int disputeId, int evidenceId) async {
    try {
      print('🗑️ Suppression de la preuve $evidenceId du litige $disputeId...');
      
      // ✅ Utiliser ApiClient
      await _apiClient.delete('disputes/$disputeId/evidence/$evidenceId/', requireAuth: true);
      
      print('✅ Preuve supprimée avec succès');
      return true;
    } catch (e) {
      print('❌ Error in deleteEvidence: $e');
      return false;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Rechercher des litiges
  Future<List<Dispute>> searchDisputes(String query) async {
    try {
      print('🔍 Recherche de litiges: "$query"...');
      
      // ✅ Utiliser ApiClient
      final responseData = await _apiClient.get(
        'disputes/search/?q=${Uri.encodeComponent(query)}',
        requireAuth: true
      );
      
      if (responseData != null) {
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        print('✅ ${data.length} litiges trouvés pour "$query"');
        
        final disputes = data.map((item) {
          // ✅ Debug encodage des résultats de recherche
          if (item['subject'] != null) {
            print('✅ Résultat: ${item['subject']} (encodage correct)');
          }
          return Dispute.fromJson(item);
        }).toList();
        
        return disputes;
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error in searchDisputes: $e');
      return [];
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

class DisputeComment {
  final int? id;
  final int disputeId;
  final String comment;
  final String userName;
  final DateTime createdAt;

  DisputeComment({
    this.id,
    required this.disputeId,
    required this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory DisputeComment.fromJson(Map<String, dynamic> json) {
    return DisputeComment(
      id: json['id'],
      disputeId: json['dispute_id'] ?? json['dispute'],
      comment: json['comment'] ?? '',
      userName: json['user_name'] ?? json['user']?['name'] ?? 'Utilisateur',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispute_id': disputeId,
      'comment': comment,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}