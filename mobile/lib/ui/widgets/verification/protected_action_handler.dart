// lib/ui/widgets/verification/protected_action_handler.dart - Version corrigée
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:teyago/ui/screens/client/phone_verification_screen.dart';
import 'package:teyago/ui/screens/provider/provider_verification_screen.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/phone_verification_provider.dart';
import '../../screens/auth/login_screen.dart';

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
        return true; // Aucune vérification requise
      
      default:
        return true;
    }
  }

  static VerificationType _determineRequiredVerification(
    String userRole, 
    VerificationType requestedType, 
    String actionDescription
  ) {
    // Si un type spécifique est demandé, l'utiliser
    if (requestedType != VerificationType.auto) {
      return requestedType;
    }

    // Actions nécessitant vérification prestataire
    final providerActions = [
      'créer un service',
      'create service',
      'criar serviço',
      'répondre à un projet',
      'make offer',
      'fazer oferta',
      'voir le profil prestataire',
      'view provider profile',
      'ver perfil prestador',
    ];

    // Actions nécessitant vérification téléphone
    final phoneActions = [
      'publier un projet',
      'publish project',
      'publicar projeto',
      'ouvrir un litige',
      'open dispute',
      'abrir disputa',
      'laisser un avis',
      'leave review',
      'deixar avaliação',
    ];

    final actionLower = actionDescription.toLowerCase();

    // Si c'est une action prestataire ET que l'utilisateur est prestataire
    if (userRole == 'provider' && providerActions.any((action) => actionLower.contains(action.toLowerCase()))) {
      return VerificationType.provider;
    }

    // Si c'est une action nécessitant téléphone
    if (phoneActions.any((action) => actionLower.contains(action.toLowerCase()))) {
      return VerificationType.phone;
    }

    // Par défaut selon le rôle
    return userRole == 'provider' ? VerificationType.provider : VerificationType.phone;
  }

  static Future<bool> _checkPhoneVerification(
    BuildContext context, 
    String actionDescription, 
    AppLocalizations l10n
  ) async {
    final phoneProvider = Provider.of<PhoneVerificationProvider>(context, listen: false);
    await phoneProvider.fetchVerificationStatus();

    if (!phoneProvider.isVerified) {
      await _showPhoneVerificationDialog(context, actionDescription, l10n);
      return false;
    }

    return true;
  }

  static Future<bool> _checkProviderVerification(
    BuildContext context, 
    String actionDescription, 
    AppLocalizations l10n
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // Vérifier le statut de vérification prestataire
    final verificationStatus = user?.verificationDetails?['status'] ?? 'not_started';
    
    if (verificationStatus != 'verified') {
      await _showProviderVerificationDialog(
        context, 
        actionDescription, 
        verificationStatus, 
        l10n
      );
      return false;
    }

    return true;
  }

  // ============================================================================
  // DIALOGUES D'ERREUR LOCALISÉS
  // ============================================================================

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
                foregroundColor: Colors.white,
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.phoneVerificationSecurityNote,
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
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
    // Messages selon le statut
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
              builder: (context) => const ProviderVerificationScreen(viewOnly: true),
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
              builder: (context) => const ProviderVerificationScreen(resubmit: true),
            ),
          );
        };
        break;
      
      default:
        title = l10n.verificationServiceNotInitialized; // NOUVELLE TRADUCTION
        message = l10n.verificationServiceNotInitializedMessage; // NOUVELLE TRADUCTION
        buttonText = l10n.tryAgain;
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
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonText),
              ),
          ],
        );
      },
    );
  }
}

// Énumération des types de vérification
enum VerificationType {
  auto,    // Déterminé automatiquement
  phone,   // Vérification téléphone
  provider, // Vérification prestataire
  none,    // Aucune vérification
}