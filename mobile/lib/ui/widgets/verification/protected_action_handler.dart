import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/client_verification_provider.dart';  // CHANGÉ
import '../../screens/auth/login_screen.dart';
import '../../screens/verification/client_verification_screen.dart';  // CHANGÉ
import '../../screens/provider/provider_verification_screen.dart';

enum VerificationType {
  auto,
  client,    // CHANGÉ de 'phone' à 'client'
  provider,
  none,
}

class ProtectedActionHandler {
  static Future<bool> checkAndHandleVerification({
    required BuildContext context,
    required String actionDescription,
    VerificationType requiredVerification = VerificationType.auto,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // 1. Vérifier connexion
    if (!authProvider.isAuthenticated || user == null) {
      await _showLoginRequiredDialog(context, actionDescription, l10n);
      return false;
    }

    // 2. Déterminer type de vérification
    final actualRequiredVerification = _determineRequiredVerification(
      user.role, 
      requiredVerification, 
      actionDescription
    );

    // 3. Vérifier
    switch (actualRequiredVerification) {
      case VerificationType.client:  // CHANGÉ
        return await _checkClientVerification(context, actionDescription, l10n);
      
      case VerificationType.provider:
        return await _checkProviderVerification(context, actionDescription, l10n);
      
      case VerificationType.none:
        return true;
      
      default:
        return true;
    }
  }

  static VerificationType _determineRequiredVerification(
    String userRole, 
    VerificationType requestedType, 
    String actionDescription
  ) {
    if (requestedType != VerificationType.auto) {
      return requestedType;
    }

    final actionLower = actionDescription.toLowerCase();

    final providerActions = [
      'créer un service', 'create service', 'criar serviço',
      'ajouter un service', 'add service', 'adicionar serviço',
      'gérer mes services', 'manage services', 'gerenciar serviços',
      'répondre à un projet', 'respond to project', 'responder projeto',
      'faire une offre', 'make offer', 'fazer oferta',
    ];

    final clientActions = [
      'publier un projet', 'publish project', 'publicar projeto',
      'créer un projet', 'create project', 'criar projeto',
      'ajouter un projet', 'add project', 'adicionar projeto',
      'laisser un avis', 'leave review', 'deixar avaliação',
      'ouvrir un litige', 'open dispute', 'abrir disputa',
    ];

    if (providerActions.any((action) => actionLower.contains(action.toLowerCase()))) {
      return VerificationType.provider;
    }

    if (clientActions.any((action) => actionLower.contains(action.toLowerCase()))) {
      return VerificationType.client;  // CHANGÉ
    }

    return userRole == 'provider' ? VerificationType.provider : VerificationType.client;  // CHANGÉ
  }

  // NOUVELLE MÉTHODE pour les clients
  static Future<bool> _checkClientVerification(
    BuildContext context, 
    String actionDescription, 
    AppLocalizations l10n
  ) async {
    try {
      final clientProvider = Provider.of<ClientVerificationProvider>(context, listen: false);
      await clientProvider.fetchVerificationStatus();

      if (!clientProvider.isVerified) {
        await _showClientVerificationDialog(context, actionDescription, l10n, clientProvider);
        return false;
      }
      return true;
    } catch (e) {
      print('Erreur vérification client: $e');
      await _showErrorDialog(context, 'Erreur de vérification', l10n);
      return false;
    }
  }

  static Future<bool> _checkProviderVerification(
    BuildContext context, 
    String actionDescription, 
    AppLocalizations l10n
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      final verificationDetails = user?.verificationDetails;
      final status = verificationDetails?['status'] ?? 'not_started';
      
      if (status != 'verified') {
        await _showProviderVerificationDialog(context, actionDescription, status, l10n);
        return false;
      }
      return true;
    } catch (e) {
      print('Erreur vérification prestataire: $e');
      await _showErrorDialog(context, 'Erreur de vérification', l10n);
      return false;
    }
  }

  // NOUVEAU DIALOG pour les clients
  static Future<void> _showClientVerificationDialog(
    BuildContext context, 
    String actionDescription, 
    AppLocalizations l10n,
    ClientVerificationProvider clientProvider,
  ) async {
    String title;
    String message;
    String buttonText;

    if (clientProvider.isPending) {
      title = l10n.verificationInProgress;
      message = l10n.verificationInProgressCannotYet(actionDescription);
      buttonText = l10n.viewStatus;
    } else if (clientProvider.isRejected) {
      title = l10n.verificationRejected;
      message = l10n.verificationRejectedResubmit(actionDescription);
      buttonText = l10n.submitNewDocuments;
    } else {
      title = l10n.clientVerificationRequired;
      message = l10n.clientVerificationForAction(actionDescription);
      buttonText = l10n.verifyMyAccount;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.verificationSecurityNote,
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/client-verification');  // CHANGÉ
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showLoginRequiredDialog(
    BuildContext context, 
    String actionDescription, 
    AppLocalizations l10n
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.login, color: Colors.blue),
              const SizedBox(width: 8),
              Text(l10n.loginRequired),
            ],
          ),
          content: Text(l10n.mustBeLoggedInTo(actionDescription)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF142FE2)),
              child: Text(l10n.login),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showProviderVerificationDialog(
    BuildContext context, 
    String actionDescription, 
    String currentStatus,
    AppLocalizations l10n
  ) async {
    String title;
    String message;
    String buttonText;
    IconData icon;
    Color color;
    VoidCallback? onPressed;

    switch (currentStatus) {
      case 'not_started':
        title = l10n.providerVerificationRequired;
        message = l10n.providerVerificationForAction(actionDescription);
        buttonText = l10n.startVerification;
        icon = Icons.verified_user;
        color = Colors.blue;
        onPressed = () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProviderVerificationScreen()),
          );
        };
        break;
      
      case 'pending':
        title = l10n.verificationInProgress;
        message = l10n.verificationInProgressMessage(actionDescription);
        buttonText = l10n.viewStatus;
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        onPressed = () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProviderVerificationScreen()),
          );
        };
        break;
      
      case 'rejected':
        title = l10n.verificationRejected;
        message = l10n.verificationRejectedMessage(actionDescription);
        buttonText = l10n.submitNewDocuments;
        icon = Icons.error_outline;
        color = Colors.red;
        onPressed = () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProviderVerificationScreen()),
          );
        };
        break;
      
      default:
        title = l10n.verificationServiceNotInitialized;
        message = l10n.verificationServiceNotInitializedMessage;
        buttonText = l10n.contactSupport;
        icon = Icons.warning;
        color = Colors.grey;
        onPressed = () => Navigator.of(context).pop();
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              if (currentStatus == 'not_started') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.providerVerificationBenefits,
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            if (onPressed != null)
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: Text(buttonText),
              ),
          ],
        );
      },
    );
  }

  static Future<void> _showErrorDialog(
    BuildContext context, 
    String message, 
    AppLocalizations l10n
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Erreur'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}