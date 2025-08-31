import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/phone_verification_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/client/phone_verification_screen.dart';
import '../../screens/provider/provider_verification_screen.dart';

enum VerificationType {
  auto,    // Déterminé automatiquement selon le rôle et l'action
  phone,   // Vérification téléphone (clients)
  provider, // Vérification documents (prestataires)
  none,    // Aucune vérification requise
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

    // 1. Vérifier si l'utilisateur est connecté
    if (!authProvider.isAuthenticated || user == null) {
      await _showLoginRequiredDialog(context, actionDescription, l10n);
      return false;
    }

    // 2. Déterminer le type de vérification requis
    final actualRequiredVerification = _determineRequiredVerification(
      user.role, 
      requiredVerification, 
      actionDescription
    );

    // 3. Vérifier selon le type requis
    switch (actualRequiredVerification) {
      case VerificationType.phone:
        return await _checkPhoneVerification(context, actionDescription, l10n);
      
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

    // Actions spécifiquement prestataires
    final providerActions = [
      'créer un service', 'create service', 'criar serviço',
      'ajouter un service', 'add service', 'adicionar serviço',
      'gérer mes services', 'manage services', 'gerenciar serviços',
      'répondre à un projet', 'respond to project', 'responder projeto',
      'faire une offre', 'make offer', 'fazer oferta',
    ];

    // Actions spécifiquement clients
    final clientActions = [
      'publier un projet', 'publish project', 'publicar projeto',
      'créer un projet', 'create project', 'criar projeto',
      'ajouter un projet', 'add project', 'adicionar projeto',
      'laisser un avis', 'leave review', 'deixar avaliação',
      'ouvrir un litige', 'open dispute', 'abrir disputa',
    ];

    // Vérifier les actions prestataires
    if (providerActions.any((action) => actionLower.contains(action.toLowerCase()))) {
      return VerificationType.provider;
    }

    // Vérifier les actions clients
    if (clientActions.any((action) => actionLower.contains(action.toLowerCase()))) {
      return VerificationType.phone;
    }

    // Par défaut selon le rôle utilisateur
    return userRole == 'provider' ? VerificationType.provider : VerificationType.phone;
  }

  static Future<bool> _checkPhoneVerification(
    BuildContext context, 
    String actionDescription, 
    AppLocalizations l10n
  ) async {
    try {
      final phoneProvider = Provider.of<PhoneVerificationProvider>(context, listen: false);
      await phoneProvider.fetchVerificationStatus();

      if (!phoneProvider.isVerified) {
        await _showPhoneVerificationDialog(context, actionDescription, l10n);
        return false;
      }
      return true;
    } catch (e) {
      print('Erreur vérification téléphone: $e');
      await _showErrorDialog(context, l10n.verificationError, l10n);
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

      // Vérifier le statut de vérification prestataire
      final verificationDetails = user?.verificationDetails;
      final status = verificationDetails?['status'] ?? 'not_started';
      
      if (status != 'verified') {
        await _showProviderVerificationDialog(context, actionDescription, status, l10n);
        return false;
      }
      return true;
    } catch (e) {
      print('Erreur vérification prestataire: $e');
      await _showErrorDialog(context, l10n.verificationError, l10n);
      return false;
    }
  }

  // Dialogues
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF142FE2),
              ),
              child: Text(l10n.login),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showPhoneVerificationDialog(
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
              const Icon(Icons.phone_android, color: Colors.orange),
              const SizedBox(width: 8),
              Text(l10n.phoneVerificationRequired),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.phoneVerificationForAction(actionDescription)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.phoneVerificationSecurityNote,
                        style: TextStyle(color: Colors.orange[700], fontSize: 12),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhoneVerificationScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(l10n.verifyPhone),
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
            MaterialPageRoute(
              builder: (context) => const ProviderVerificationScreen(),
            ),
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
            MaterialPageRoute(
              builder: (context) => const ProviderVerificationScreen(),
            ),
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
            MaterialPageRoute(
              builder: (context) => const ProviderVerificationScreen(),
            ),
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
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.providerVerificationBenefits,
                          style: TextStyle(color: Colors.blue[700], fontSize: 12),
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
              Text(l10n.errorOccurred),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }
}