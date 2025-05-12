// lib/providers/dispute_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/dispute.dart';
import '../core/services/dispute_service.dart';

class DisputeProvider with ChangeNotifier {
  final DisputeService _disputeService;
  List<Dispute> _disputes = [];
  Dispute? _currentDispute;
  bool _isLoading = false;
  String? _errorMessage;

  DisputeProvider(this._disputeService);

  List<Dispute> get disputes => _disputes;
  Dispute? get currentDispute => _currentDispute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
        clientId: 0, // Sera remplacé par l'API
        providerId: providerId,
        serviceId: serviceId,
        title: title,
        description: description,
      );
      
      final createdDispute = await _disputeService.createDispute(dispute);
      _currentDispute = createdDispute;
      
      // Ajouter à la liste locale
      _disputes.add(createdDispute);
      
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

  // Récupérer les litiges de l'utilisateur
  Future<void> fetchUserDisputes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _disputes = await _disputeService.getUserDisputes();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Récupérer un litige spécifique
  Future<bool> fetchDisputeById(int disputeId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentDispute = null;
    notifyListeners();

    try {
      // Rechercher d'abord dans la liste en mémoire
      final dispute = _disputes.firstWhere(
        (d) => d.id == disputeId,
        orElse: () => _disputes.first, // Récupérer le premier si non trouvé
      );
      
      _currentDispute = dispute;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Litige non trouvé";
      notifyListeners();
      
      return false;
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
      
      // Mettre à jour le litige courant
      if (_currentDispute != null && _currentDispute!.id == disputeId) {
        final updatedEvidence = [..._currentDispute!.evidence, evidence];
        _currentDispute = Dispute(
          id: _currentDispute!.id,
          clientId: _currentDispute!.clientId,
          providerId: _currentDispute!.providerId,
          serviceId: _currentDispute!.serviceId,
          title: _currentDispute!.title,
          description: _currentDispute!.description,
          status: _currentDispute!.status,
          resolutionNote: _currentDispute!.resolutionNote,
          createdAt: _currentDispute!.createdAt,
          evidence: updatedEvidence,
          clientName: _currentDispute!.clientName,
          providerName: _currentDispute!.providerName,
          serviceName: _currentDispute!.serviceName,
        );
      }
      
      // Mettre à jour aussi dans la liste si présent
      final index = _disputes.indexWhere((d) => d.id == disputeId);
      if (index >= 0) {
        final updatedEvidence = [..._disputes[index].evidence, evidence];
        _disputes[index] = Dispute(
          id: _disputes[index].id,
          clientId: _disputes[index].clientId,
          providerId: _disputes[index].providerId,
          serviceId: _disputes[index].serviceId,
          title: _disputes[index].title,
          description: _disputes[index].description,
          status: _disputes[index].status,
          resolutionNote: _disputes[index].resolutionNote,
          createdAt: _disputes[index].createdAt,
          evidence: updatedEvidence,
          clientName: _disputes[index].clientName,
          providerName: _disputes[index].providerName,
          serviceName: _disputes[index].serviceName,
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

  // Filtrer les litiges par statut
  List<Dispute> getDisputesByStatus(String status) {
    return _disputes.where((dispute) => dispute.status == status).toList();
  }

  // Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}