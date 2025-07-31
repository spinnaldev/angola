
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/verification_result.dart';

class VerificationGuardService {
  
  /// Vérifier si un utilisateur peut effectuer une action
  static VerificationResult checkAccess(User? user, String actionDescription) {
    if (user == null) {
      return VerificationResult.blocked(
        title: 'Connexion requise',
        message: 'Vous devez être connecté pour $actionDescription.',
        redirectRoute: '/login',
        buttonText: 'Se connecter',
      );
    }
    
    // Les admins passent toujours
    if (user.role == 'admin') {
      return VerificationResult.allowed();
    }
    
    // Vérifications spécifiques par rôle
    if (user.role == 'client') {
      return _checkClientAccess(user, actionDescription);
    } else if (user.role == 'provider') {
      return _checkProviderAccess(user, actionDescription);
    }
    
    return VerificationResult.allowed();
  }
  
  /// Vérifier l'accès pour un client
  static VerificationResult _checkClientAccess(User user, String actionDescription) {
    if (!user.isPhoneVerified) {
      return VerificationResult.blocked(
        title: 'Vérification téléphone requise',
        message: _getClientMessage(actionDescription),
        redirectRoute: '/phone-verification',
        buttonText: 'Vérifier mon téléphone',
        verificationType: 'phone',
      );
    }
    
    return VerificationResult.allowed();
  }
  
  /// Vérifier l'accès pour un prestataire
  static VerificationResult _checkProviderAccess(User user, String actionDescription) {
    if (!user.isProviderVerified) {
      String title = 'Vérification profil requise';
      String message = _getProviderMessage(actionDescription, user.verificationStatus ?? 'not_started');
      String buttonText = 'Vérifier mon profil';
      
      // Message différent selon le statut
      if (user.verificationStatus == 'pending') {
        title = 'Vérification en cours';
        message = 'Votre demande de vérification est en cours d\'examen. Vous ne pouvez pas encore $actionDescription.';
        buttonText = 'Voir le statut';
      } else if (user.verificationStatus == 'rejected') {
        title = 'Vérification rejetée';
        message = 'Votre demande de vérification a été rejetée. Veuillez soumettre de nouveaux documents pour $actionDescription.';
        buttonText = 'Soumettre de nouveaux documents';
      }
      
      return VerificationResult.blocked(
        title: title,
        message: message,
        redirectRoute: '/provider-verification',
        buttonText: buttonText,
        verificationType: 'documents',
      );
    }
    
    return VerificationResult.allowed();
  }
  
  /// Messages spécifiques pour les clients
  static String _getClientMessage(String actionDescription) {
    switch (actionDescription) {
      case 'créer un projet':
        return 'Pour publier un projet et recevoir des offres de prestataires, vous devez d\'abord vérifier votre numéro de téléphone. Cela garantit la sécurité et la confiance sur notre plateforme.';
      case 'faire une demande de devis':
        return 'Pour demander un devis personnalisé, vous devez vérifier votre numéro de téléphone. Cette étape nous permet de vous protéger contre les demandes frauduleuses.';
      case 'ouvrir un litige':
        return 'Pour ouvrir un litige et protéger vos intérêts, vous devez d\'abord vérifier votre numéro de téléphone.';
      case 'laisser un avis':
        return 'Pour laisser un avis sur un prestataire, vous devez vérifier votre numéro de téléphone afin d\'éviter les faux avis.';
      case 'démarrer une conversation':
        return 'Pour contacter un prestataire, vous devez vérifier votre numéro de téléphone.';
      default:
        return 'Pour utiliser cette fonctionnalité, vous devez vérifier votre numéro de téléphone.';
    }
  }
  
  /// Messages spécifiques pour les prestataires
  static String _getProviderMessage(String actionDescription, String status) {
    if (status == 'not_started') {
      switch (actionDescription) {
        case 'créer un service':
          return 'Pour proposer vos services et recevoir des clients, vous devez d\'abord vérifier votre profil prestataire. Envoyez-nous vos documents d\'identité pour garantir la confiance de vos futurs clients.';
        case 'faire une offre':
          return 'Pour répondre aux projets clients, vous devez vérifier votre profil prestataire. Cette vérification rassure les clients sur votre identité.';
        case 'ouvrir un litige':
          return 'Pour ouvrir un litige, vous devez d\'abord être un prestataire vérifié sur notre plateforme.';
        case 'envoyer un message':
          return 'Pour contacter des clients, vous devez vérifier votre profil prestataire.';
        default:
          return 'Pour utiliser cette fonctionnalité prestataire, vous devez vérifier votre profil avec vos documents d\'identité.';
      }
    }
    return 'Votre vérification est en cours. Patientez ou soumettez de nouveaux documents.';
  }
  
  /// Vérifier rapidement si un utilisateur peut effectuer des actions
  static bool canPerformActions(User? user) {
    if (user == null) return false;
    if (user.role == 'admin') return true;
    
    return user.canPerformActions;
  }
  
  /// Obtenir le type de vérification requis pour un utilisateur
  static String getRequiredVerificationType(User? user) {
    if (user == null) return 'login';
    return user.requiredVerificationType;
  }
}