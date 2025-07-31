
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teyago/ui/widgets/verification/verification_required_dialog.dart';
import '../../../providers/auth_provider.dart';

class ProtectedActionButton extends StatelessWidget {
  final String actionDescription;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enabled;

  const ProtectedActionButton({
    Key? key,
    required this.actionDescription,
    required this.onPressed,
    required this.child,
    this.style,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return ElevatedButton(
          style: style,
          onPressed: enabled ? () => _handlePress(context, authProvider) : null,
          child: child,
        );
      },
    );
  }

  void _handlePress(BuildContext context, AuthProvider authProvider) {
    if (authProvider.canPerformAction(actionDescription)) {
      onPressed();
    } else {
      final result = authProvider.getVerificationResult(actionDescription);
      VerificationRequiredDialog.show(context, result);
    }
  }
}