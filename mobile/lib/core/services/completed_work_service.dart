// lib/core/services/completed_work_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/completed_work.dart';
import 'api_service.dart';

class CompletedWorkService {
  final ApiService _apiService;
  
  CompletedWorkService(this._apiService);
  
  // Créer un nouveau travail effectué
  Future<CompletedWork> createCompletedWork(
    CompletedWork work,
    List<File> images,
    List<String> captions,
  ) async {
    try {
      // Utiliser MultipartRequest pour envoyer des fichiers
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider/works/'),
      );
      
      // Ajouter les headers d'authentification
      final headers = await _apiService.getHeaders();
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
        }
        
        imageCount++;
      }
      
      request.fields['image_count'] = imageCount.toString();
      
      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return CompletedWork.fromJson(data);
      } else {
        throw Exception('Failed to create completed work: ${response.body}');
      }
    } catch (e) {
      print('Error in createCompletedWork: $e');
      rethrow;
    }
  }
  
  // Récupérer les travaux effectués du prestataire
  Future<List<CompletedWork>> getProviderWorks() async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/provider/works/'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['results'] ?? [];
        return data.map((item) => CompletedWork.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get provider works: ${response.body}');
      }
    } catch (e) {
      print('Error in getProviderWorks: $e');
      rethrow;
    }
  }
  
  // Ajouter des images à un travail existant
  Future<List<WorkImage>> addWorkImages(
    int workId,
    List<File> images,
    List<String> captions,
  ) async {
    try {
      // Utiliser MultipartRequest pour envoyer des fichiers
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/provider/works/$workId/add_images/'),
      );
      
      // Ajouter les headers d'authentification
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);
      
      // Ajouter les images (max 10)
      for (var i = 0; i < images.length && i < 10; i++) {
        var file = images[i];
        var fileName = file.path.split('/').last;
        var fileExtension = fileName.split('.').last.toLowerCase();
        
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
        }
      }
      
      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => WorkImage.fromJson(item)).toList();
      } else {
        throw Exception('Failed to add images: ${response.body}');
      }
    } catch (e) {
      print('Error in addWorkImages: $e');
      rethrow;
    }
  }
  
  // Supprimer un travail effectué
  Future<bool> deleteWork(int workId) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.delete(
        Uri.parse('${_apiService.baseUrl}/provider/works/$workId/'),
        headers: headers,
      );
      
      return response.statusCode == 204;
    } catch (e) {
      print('Error in deleteWork: $e');
      rethrow;
    }
  }
}