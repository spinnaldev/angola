
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teyago/ui/widgets/verification/protected_action_handler.dart';
import 'package:teyago/ui/widgets/verification/verification_required_dialog.dart';
import '../../../providers/auth_provider.dart';
class ProtectedActionButton extends StatelessWidget {
  final String actionDescription;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enabled;
  final VerificationType requiredVerification;

  const ProtectedActionButton({
    Key? key,
    required this.actionDescription,
    required this.onPressed,
    required this.child,
    this.style,
    this.enabled = true,
    this.requiredVerification = VerificationType.auto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: enabled ? () async {
        final canProceed = await ProtectedActionHandler.checkAndHandleVerification(
          context: context,
          actionDescription: actionDescription,
          requiredVerification: requiredVerification,
        );
        if (canProceed) {
          onPressed();
        }
      } : null,
      child: child,
    );
  }
}