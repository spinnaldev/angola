
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teyago/providers/auth_provider.dart';
import 'package:teyago/ui/widgets/verification/verification_required_dialog.dart';

class ProtectedFloatingActionButton extends StatelessWidget {
  final String actionDescription;
  final VoidCallback onPressed;
  final Widget child;
  final String? tooltip;
  final Color? backgroundColor;

  const ProtectedFloatingActionButton({
    Key? key,
    required this.actionDescription,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return FloatingActionButton(
          onPressed: () => _handlePress(context, authProvider),
          tooltip: tooltip,
          backgroundColor: backgroundColor,
          child: child,
        );
      },
    );
  }

  void _handlePress(BuildContext context, AuthProvider authProvider) {
    if (authProvider.canPerformAction(context , actionDescription)) {
      onPressed();
    } else {
      final result = authProvider.getVerificationResult(context , actionDescription);
      VerificationRequiredDialog.show(context, result);
    }
  }
}