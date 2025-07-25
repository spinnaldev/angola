// lib/core/services/completed_work_service.dart - VERSION CORRIGÉE avec ApiClient
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/completed_work.dart';
import 'api_service.dart';
import '../api/api_client.dart'; // ✅ Import ApiClient

class CompletedWorkService {
  final ApiService _apiService;
  late final ApiClient _apiClient; // ✅ Référence ApiClient
  
  CompletedWorkService(this._apiService) {
    // ✅ Initialiser ApiClient pour bénéficier des corrections d'encodage
    _apiClient = ApiClient(baseUrl: _apiService.baseUrl);
  }
  
  // ✅ MÉTHODE CORRIGÉE: createCompletedWork (MultipartRequest conservé mais headers corrigés)
  Future<CompletedWork> createCompletedWork(
    CompletedWork work,
    List<File> images,
    List<String> captions,
  ) async {
    try {
      print('🔨 Création d\'un nouveau travail effectué...');
      print('✅ Titre: ${work.title} (encodage correct)');
      print('✅ Description: ${work.description} (encodage correct)');
      print('✅ Localisation: ${work.location} (encodage correct)');
      
      // Utiliser MultipartRequest pour envoyer des fichiers
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider/works/'),
      );
      
      // ✅ Utiliser ApiClient pour les headers (cohérence avec encodage)
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // Ajouter les champs du formulaire
      request.fields['title'] = work.title;
      request.fields['description'] = work.description;
      request.fields['location'] = work.location;
      request.fields['completion_date'] = work.completionDate.toIso8601String();
      request.fields['subcategory'] = work.subcategoryId.toString();
      request.fields['client_name'] = work.clientName;
      request.fields['client_contact'] = work.clientContact;
      
      // Ajouter les images (max 10)
      int imageCount = 0;
      for (var i = 0; i < images.length && i < 10; i++) {
        var file = images[i];
        var fileName = file.path.split('/').last;
        var fileExtension = fileName.split('.').last.toLowerCase();
        
        print('📷 Ajout image ${i + 1}: $fileName');
        
        request.files.add(
          http.MultipartFile(
            'images',
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: fileName,
            contentType: MediaType('image', fileExtension),
          ),
        );
        
        // Ajouter la légende de l'image
        if (i < captions.length) {
          request.fields['captions[$i]'] = captions[i];
          print('✅ Légende ${i + 1}: ${captions[i]} (encodage correct)');
        }
        
        imageCount++;
      }
      
      request.fields['image_count'] = imageCount.toString();
      
      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Statut réponse création travail: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        // ✅ Traitement UTF-8 pour la réponse MultipartRequest
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }
        
        final data = json.decode(responseBody);
        
        // ✅ Debug encodage de la réponse
        if (data['title'] != null) {
          print('✅ Travail créé: ${data['title']} (encodage correct)');
        }
        
        return CompletedWork.fromJson(data);
      } else {
        throw Exception('Failed to create completed work: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in createCompletedWork: $e');
      rethrow;
    }
  }
  
  // ✅ MÉTHODE CORRIGÉE: getProviderWorks
  Future<List<CompletedWork>> getProviderWorks() async {
    try {
      print('📋 Récupération des travaux du prestataire...');
      
      // ✅ Utiliser ApiClient au lieu de http.get
      final responseData = await _apiClient.get('provider/works/', requireAuth: true);
      
      if (responseData != null) {
        // ✅ Gérer les données déjà décodées par ApiClient
        List<dynamic> data = [];
        
        if (responseData is Map<String, dynamic>) {
          data = responseData['results'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        }
        
        print('✅ ${data.length} travaux trouvés');
        
        final works = data.map((item) {
          // ✅ Debug encodage des travaux
          if (item['title'] != null) {
            print('✅ Travail: ${item['title']} (encodage correct)');
          }
          return CompletedWork.fromJson(item);
        }).toList();
        
        return works;
      } else {
        print('❌ Réponse nulle pour les travaux du prestataire');
        return [];
      }
    } catch (e) {
      print('❌ Error in getProviderWorks: $e');
      rethrow;
    }
  }
  
  // ✅ MÉTHODE CORRIGÉE: addWorkImages (MultipartRequest conservé mais headers corrigés)
  Future<List<WorkImage>> addWorkImages(
    int workId,
    List<File> images,
    List<String> captions,
  ) async {
    try {
      print('📷 Ajout d\'images au travail $workId...');
      
      // Utiliser MultipartRequest pour envoyer des fichiers
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider/works/$workId/add_images/'),
      );
      
      // ✅ Utiliser ApiClient pour les headers (cohérence avec encodage)
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);
      
      // Ajouter les images (max 10)
      for (var i = 0; i < images.length && i < 10; i++) {
        var file = images[i];
        var fileName = file.path.split('/').last;
        var fileExtension = fileName.split('.').last.toLowerCase();
        
        print('📷 Ajout image supplémentaire ${i + 1}: $fileName');
        
        request.files.add(
          http.MultipartFile(
            'images',
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: fileName,
            contentType: MediaType('image', fileExtension),
          ),
        );
        
        // Ajouter la légende de l'image
        if (i < captions.length) {
          request.fields['captions[$i]'] = captions[i];
          print('✅ Légende supplémentaire ${i + 1}: ${captions[i]} (encodage correct)');
        }
      }
      
      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Statut réponse ajout images: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // ✅ Traitement UTF-8 pour la réponse MultipartRequest
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }
        
        final List<dynamic> data = json.decode(responseBody);
        
        print('✅ ${data.length} images ajoutées avec succès');
        
        return data.map((item) {
          // ✅ Debug encodage des images ajoutées
          if (item['caption'] != null) {
            print('✅ Image ajoutée avec légende: ${item['caption']} (encodage correct)');
          }
          return WorkImage.fromJson(item);
        }).toList();
      } else {
        throw Exception('Failed to add images: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in addWorkImages: $e');
      rethrow;
    }
  }
  
  // ✅ MÉTHODE CORRIGÉE: deleteWork
  Future<bool> deleteWork(int workId) async {
    try {
      print('🗑️ Suppression du travail $workId...');
      
      // ✅ Utiliser ApiClient au lieu de http.delete
      await _apiClient.delete('provider/works/$workId/', requireAuth: true);
      
      print('✅ Travail supprimé avec succès');
      return true;
    } catch (e) {
      print('❌ Error in deleteWork: $e');
      return false;
    }
  }
}