// mobile/lib/core/services/verification_guard_service.dart
// REMPLACEZ votre fichier existant par celui-ci

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/verification_result.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VerificationGuardService {
  /// Vérifier si un utilisateur peut effectuer une action
  static VerificationResult checkAccess(BuildContext context, User? user, String actionDescription) {
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return VerificationResult.blocked(
        title: l10n.loginRequired,
        message: l10n.mustBeLoggedInTo(actionDescription),
        redirectRoute: '/login',
        buttonText: l10n.login,
      );
    }

    if (user.role == 'admin') {
      return VerificationResult.allowed();
    }

    if (user.role == 'client') {
      return _checkClientAccess(context, user, actionDescription);
    } else if (user.role == 'provider') {
      return _checkProviderAccess(context, user, actionDescription);
    }

    return VerificationResult.allowed();
  }
  
  /// Vérifier l'accès pour un CLIENT (avec documents)
  static VerificationResult _checkClientAccess(BuildContext context, User user, String actionDescription) {
    final l10n = AppLocalizations.of(context)!;

    // NOUVEAU : Vérification par documents au lieu de téléphone
    if (!user.isClientVerified) {
      String title = l10n.profileVerificationRequired;
      String message = _getClientMessage(context, actionDescription, user.clientVerificationStatus ?? 'not_started');
      String buttonText = 'Vérifier mon compte';
      String redirectRoute = '/client-verification';

      if (user.clientVerificationStatus == 'pending') {
        title = l10n.verificationInProgress;
        message = l10n.verificationInProgressMessage(actionDescription);
        buttonText = l10n.viewStatus;
      } else if (user.clientVerificationStatus == 'rejected') {
        title = l10n.verificationRejected;
        message = l10n.verificationRejectedMessage(actionDescription);
        buttonText = l10n.submitNewDocuments;
      }

      return VerificationResult.blocked(
        title: title,
        message: message,
        redirectRoute: redirectRoute,
        buttonText: buttonText,
        verificationType: 'client_documents',
      );
    }

    return VerificationResult.allowed();
  }
  
  /// Vérifier l'accès pour un PRESTATAIRE (inchangé)
  static VerificationResult _checkProviderAccess(BuildContext context, User user, String actionDescription) {
    final l10n = AppLocalizations.of(context)!;

    if (!user.isProviderVerified) {
      String title = l10n.profileVerificationRequired;
      String message = _getProviderMessage(context, actionDescription, user.verificationStatus ?? 'not_started');
      String buttonText = l10n.verifyMyProfile;

      if (user.verificationStatus == 'pending') {
        title = l10n.verificationInProgress;
        message = l10n.verificationInProgressMessage(actionDescription);
        buttonText = l10n.viewStatus;
      } else if (user.verificationStatus == 'rejected') {
        title = l10n.verificationRejected;
        message = l10n.verificationRejectedMessage(actionDescription);
        buttonText = l10n.submitNewDocuments;
      }

      return VerificationResult.blocked(
        title: title,
        message: message,
        redirectRoute: '/provider-verification',
        buttonText: buttonText,
        verificationType: 'provider_documents',
      );
    }

    return VerificationResult.allowed();
  }
  
  /// Messages spécifiques pour les CLIENTS
  static String _getClientMessage(BuildContext context, String actionDescription, String status) {
    final l10n = AppLocalizations.of(context)!;
    
    if (status == 'not_started') {
      switch (actionDescription) {
        case 'créer un projet':
          return 'Pour publier un projet et recevoir des offres de prestataires, vous devez d\'abord vérifier votre compte avec vos documents d\'identité. Cela garantit la sécurité et la confiance sur notre plateforme.';
        case 'faire une demande de devis':
          return 'Pour demander un devis personnalisé, vous devez vérifier votre compte avec vos documents d\'identité.';
        case 'ouvrir un litige':
          return 'Pour ouvrir un litige et protéger vos intérêts, vous devez d\'abord vérifier votre compte.';
        case 'laisser un avis':
          return 'Pour laisser un avis sur un prestataire, vous devez vérifier votre compte afin d\'éviter les faux avis.';
        case 'démarrer une conversation':
          return 'Pour contacter un prestataire, vous devez vérifier votre compte.';
        default:
          return 'Pour utiliser cette fonctionnalité, vous devez vérifier votre compte avec vos documents d\'identité.';
      }
    }
    return 'Votre vérification est en cours. Patientez ou soumettez de nouveaux documents.';
  }
  
  /// Messages spécifiques pour les PRESTATAIRES (inchangé)
  static String _getProviderMessage(BuildContext context, String actionDescription, String status) {
    final l10n = AppLocalizations.of(context)!;
    
    if (status == 'not_started') {
      switch (actionDescription) {
        case 'créer un service':
          return l10n.verify_provider_create_service;
        case 'faire une offre':
          return l10n.verify_provider_make_offer;
        case 'ouvrir un litige':
          return l10n.verify_provider_open_dispute;
        case 'envoyer un message':
          return l10n.verify_provider_send_message;
        default:
          return l10n.verify_provider_generic;
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
    if (user.role == 'admin') return 'none';
    
    if (user.role == 'client') {
      return 'client_documents';
    } else if (user.role == 'provider') {
      return 'provider_documents';
    }
    
    return 'none';
  }
}