// lib/providers/completed_work_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/completed_work.dart';
import '../core/services/completed_work_service.dart';

class CompletedWorkProvider with ChangeNotifier {
  final CompletedWorkService _workService;
  List<CompletedWork> _works = [];
  bool _isLoading = false;
  String? _errorMessage;

  CompletedWorkProvider(this._workService);

  List<CompletedWork> get works => _works;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Créer un nouveau travail effectué
  Future<bool> createCompletedWork(
    String title,
    String description,
    String location,
    DateTime completionDate,
    int subcategoryId,
    String clientName,
    String clientContact,
    List<File> images,
    List<String> captions,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final work = CompletedWork(
        providerId: 0, // Sera rempli par l'API
        title: title,
        description: description,
        location: location,
        completionDate: completionDate,
        subcategoryId: subcategoryId,
        clientName: clientName,
        clientContact: clientContact,
      );
      
      final createdWork = await _workService.createCompletedWork(
        work,
        images,
        captions,
      );
      
      // Ajouter à la liste locale
      _works.add(createdWork);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      return false;
    }
  }

  // Récupérer les travaux effectués du prestataire
  Future<void> fetchProviderWorks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _works = await _workService.getProviderWorks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Ajouter des images à un travail existant
  Future<bool> addWorkImages(
    int workId,
    List<File> images,
    List<String> captions,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final addedImages = await _workService.addWorkImages(
        workId,
        images,
        captions,
      );
      
      // Mettre à jour le travail dans la liste locale
      final index = _works.indexWhere((w) => w.id == workId);
      if (index >= 0) {
        final work = _works[index];
        final newImageUrls = [...work.imageUrls];
        
        for (var image in addedImages) {
          newImageUrls.add(image.imageUrl);
        }
        
        _works[index] = CompletedWork(
          id: work.id,
          providerId: work.providerId,
          title: work.title,
          description: work.description,
          location: work.location,
          completionDate: work.completionDate,
          imageUrls: newImageUrls,
          subcategoryId: work.subcategoryId,
          clientName: work.clientName,
          clientContact: work.clientContact,
          createdAt: work.createdAt,
        );
      }
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      return false;
    }
  }

  // Supprimer un travail effectué
  Future<bool> deleteWork(int workId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _workService.deleteWork(workId);
      
      if (success) {
        // Supprimer de la liste locale
        _works.removeWhere((w) => w.id == workId);
      }
      
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      return false;
    }
  }

  // Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}