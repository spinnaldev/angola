
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teyago/core/models/verification_result.dart';
import 'package:teyago/providers/auth_provider.dart';
import 'package:teyago/ui/widgets/verification/verification_required_dialog.dart';

class VerificationGuard extends StatelessWidget {
  final Widget child;
  final String actionDescription;
  final bool showDialogOnBlock;

  const VerificationGuard({
    Key? key,
    required this.child,
    required this.actionDescription,
    this.showDialogOnBlock = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final result = authProvider.getVerificationResult(actionDescription);
        
        if (result.canAccess) {
          return child;
        } else {
          // Afficher le dialog automatiquement si demandé
          if (showDialogOnBlock) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              VerificationRequiredDialog.show(context, result);
            });
          }
          
          // Retourner une page de blocage
          return _buildBlockedPage(context, result);
        }
      },
    );
  }

  Widget _buildBlockedPage(BuildContext context, VerificationResult result) {
    return Scaffold(
      appBar: AppBar(
        title: Text(result.title ?? 'Accès restreint'),
        backgroundColor: result.iconColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: result.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  result.icon,
                  size: 64,
                  color: result.iconColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                result.title ?? 'Accès restreint',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                result.message ?? 'Vous n\'avez pas accès à cette fonctionnalité.',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (result.redirectRoute != null) {
                      Navigator.pushReplacementNamed(context, result.redirectRoute!);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: result.iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    result.buttonText ?? 'Vérifier mon compte',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}