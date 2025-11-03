// lib/providers/dispute_provider.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../core/models/dispute.dart';
import '../core/services/dispute_service.dart';

class DisputeProvider with ChangeNotifier {
  final DisputeService _disputeService;
  
  List<Dispute> _disputes = [];
  Dispute? _currentDispute;
  bool _isLoading = false;
  String? _errorMessage;
  
  DisputeProvider(this._disputeService);
  
  // Getters
  List<Dispute> get disputes => _disputes;
  Dispute? get currentDispute => _currentDispute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Méthodes pour obtenir les litiges par statut
  List<Dispute> getDisputesByStatus(String status) {
    return _disputes.where((dispute) => dispute.status == status).toList();
  }
  
  // Récupérer tous les litiges de l'utilisateur
  Future<void> fetchUserDisputes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final disputes = await _disputeService.getUserDisputes();
      _disputes = disputes;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Récupérer les détails d'un litige spécifique
  Future<void> fetchDisputeById(int disputeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Chercher d'abord dans les litiges déjà chargés
      _currentDispute = _disputes.firstWhere(
        (dispute) => dispute.id == disputeId,
        orElse: () => throw Exception('Litige non trouvé localement'),
      );
      
      // Si le litige est trouvé localement, nous l'utilisons
      // Sinon, il faudrait avoir une API pour récupérer un litige spécifique
      // await _disputeService.getDisputeById(disputeId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Créer un nouveau litige
  Future<bool> createDispute(
    int providerId,
    String title,
    String description, {
    int? serviceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final dispute = Dispute(
        providerId: providerId,
        providerName: 'À déterminer', // Sera remplacé par l'API
        title: title,
        description: description,
        serviceId: serviceId,
        clientName: 'Client', // Sera remplacé par l'API
      );
      
      final createdDispute = await _disputeService.createDispute(dispute);
      _disputes.add(createdDispute);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Ajouter une preuve à un litige
  Future<bool> addEvidence(
    int disputeId,
    String description,
    File file,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final evidence = await _disputeService.addDisputeEvidence(
        disputeId,
        description,
        file,
      );
      
      // // Mettre à jour le litige actuel si c'est celui auquel on ajoute la preuve
      // if (_currentDispute != null && _currentDispute!.id == disputeId) {
      //   _currentDispute!.evidence.add(evidence);
      // }
      
      // Mettre à jour le litige dans la liste complète
      final index = _disputes.indexWhere((d) => d.id == disputeId);
      if (index != -1) {
        _disputes[index].evidence.add(evidence);
      }
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ✅ NOUVELLE MÉTHODE : Ajouter un commentaire
  Future<bool> addComment(int disputeId, String commentText) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // ✅ NOUVEAU : Utiliser la méthode addComment du service
      final commentEvidence = await _disputeService.addComment(disputeId, commentText);
      
      // Mettre à jour le litige actuel si c'est celui auquel on ajoute le commentaire
      // if (_currentDispute != null && _currentDispute!.id == disputeId) {
      //   _currentDispute!.evidence.add(commentEvidence);
      // }
      
      // Mettre à jour le litige dans la liste complète
      final index = _disputes.indexWhere((d) => d.id == disputeId);
      if (index != -1) {
        _disputes[index].evidence.add(commentEvidence);
      }
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour le statut d'un litige (principalement pour les administrateurs)
  Future<bool> updateDisputeStatus(
    int disputeId,
    String status,
    String resolutionNote,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updatedDispute = await _disputeService.updateDisputeStatus(
        disputeId,
        status,
        resolutionNote,
      );
      
      // Mettre à jour le litige actuel si c'est celui qu'on modifie
      if (_currentDispute != null && _currentDispute!.id == disputeId) {
        _currentDispute = updatedDispute;
      }
      
      // Mettre à jour le litige dans la liste complète
      final index = _disputes.indexWhere((d) => d.id == disputeId);
      if (index != -1) {
        _disputes[index] = updatedDispute;
      }
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}