
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
  
  /// Vérifier l'accès pour un client
  static VerificationResult _checkClientAccess(BuildContext context, User user, String actionDescription) {
    final l10n = AppLocalizations.of(context)!;

    if (!user.isPhoneVerified) {
      return VerificationResult.blocked(
        title: l10n.phoneVerificationRequired,
        message: _getClientMessage(context, actionDescription),
        redirectRoute: '/phone-verification',
        buttonText: l10n.verifyMyPhone,
        verificationType: 'phone',
      );
    }

    return VerificationResult.allowed();
  }
  
  /// Vérifier l'accès pour un prestataire
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
        verificationType: 'documents',
      );
    }

    return VerificationResult.allowed();
  }
  
  /// Messages spécifiques pour les clients
  static String _getClientMessage(BuildContext context, String actionDescription) {
    final l10n = AppLocalizations.of(context)!;
    // switch (actionDescription) {
    //   case 'créer un projet':
    //     return 'Pour publier un projet et recevoir des offres de prestataires, vous devez d\'abord vérifier votre numéro de téléphone. Cela garantit la sécurité et la confiance sur notre plateforme.';
    //   case 'faire une demande de devis':
    //     return 'Pour demander un devis personnalisé, vous devez vérifier votre numéro de téléphone. Cette étape nous permet de vous protéger contre les demandes frauduleuses.';
    //   case 'ouvrir un litige':
    //     return 'Pour ouvrir un litige et protéger vos intérêts, vous devez d\'abord vérifier votre numéro de téléphone.';
    //   case 'laisser un avis':
    //     return 'Pour laisser un avis sur un prestataire, vous devez vérifier votre numéro de téléphone afin d\'éviter les faux avis.';
    //   case 'démarrer une conversation':
    //     return 'Pour contacter un prestataire, vous devez vérifier votre numéro de téléphone.';
    //   default:
    //     return 'Pour utiliser cette fonctionnalité, vous devez vérifier votre numéro de téléphone.';
    // }
    switch (actionDescription) {
      case 'créer un projet':
        return l10n.verify_phone_create_project;
      case 'faire une demande de devis':
        return l10n.verify_phone_request_quote;
      case 'ouvrir un litige':
        return l10n.verify_phone_open_dispute;
      case 'laisser un avis':
        return l10n.verify_phone_leave_review;
      case 'démarrer une conversation':
        return l10n.verify_phone_start_conversation;
      default:
        return l10n.verify_phone_generic;
    }
  }
  
  /// Messages spécifiques pour les prestataires
  static String _getProviderMessage(BuildContext context, String actionDescription, String status) {
    final l10n = AppLocalizations.of(context)!;
    if (status == 'not_started') {
      // switch (actionDescription) {
      //   case 'créer un service':
      //     return 'Pour proposer vos services et recevoir des clients, vous devez d\'abord vérifier votre profil prestataire. Envoyez-nous vos documents d\'identité pour garantir la confiance de vos futurs clients.';
      //   case 'faire une offre':
      //     return 'Pour répondre aux projets clients, vous devez vérifier votre profil prestataire. Cette vérification rassure les clients sur votre identité.';
      //   case 'ouvrir un litige':
      //     return 'Pour ouvrir un litige, vous devez d\'abord être un prestataire vérifié sur notre plateforme.';
      //   case 'envoyer un message':
      //     return 'Pour contacter des clients, vous devez vérifier votre profil prestataire.';
      //   default:
      //     return 'Pour utiliser cette fonctionnalité prestataire, vous devez vérifier votre profil avec vos documents d\'identité.';
      // }
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
    return user.requiredVerificationType;
  }
}