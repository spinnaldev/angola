
import 'package:flutter/material.dart';

import '../../../core/models/verification_result.dart';

class VerificationRequiredDialog extends StatelessWidget {
  final VerificationResult verificationResult;

  const VerificationRequiredDialog({
    Key? key,
    required this.verificationResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête coloré
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: verificationResult.iconColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: verificationResult.iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      verificationResult.icon,
                      color: verificationResult.iconColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    verificationResult.title ?? 'Vérification requise',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Contenu
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    verificationResult.message ?? 'Vous devez vérifier votre compte.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Message de sécurité
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: verificationResult.iconColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: verificationResult.iconColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: verificationResult.iconColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getSecurityMessage(),
                            style: TextStyle(
                              fontSize: 12,
                              color: verificationResult.iconColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (verificationResult.redirectRoute != null) {
                          Navigator.pushNamed(context, verificationResult.redirectRoute!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: verificationResult.iconColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        verificationResult.buttonText ?? 'Vérifier',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSecurityMessage() {
    switch (verificationResult.verificationType) {
      case 'phone':
        return 'La vérification téléphone protège contre les faux comptes';
      case 'documents':
        return 'La vérification documents garantit l\'identité des prestataires';
      default:
        return 'La vérification renforce la sécurité de la plateforme';
    }
  }

  static Future<void> show(
    BuildContext context,
    VerificationResult verificationResult,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationRequiredDialog(
        verificationResult: verificationResult,
      ),
    );
  }
}
