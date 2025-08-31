
import 'package:flutter/material.dart';
import 'protected_action_handler.dart';

class ProtectedFloatingActionButton extends StatelessWidget {
  final String actionDescription;
  final VoidCallback onPressed;
  final Widget child;
  final String? tooltip;
  final Color? backgroundColor;
  final VerificationType requiredVerification;

  const ProtectedFloatingActionButton({
    Key? key,
    required this.actionDescription,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
    this.requiredVerification = VerificationType.auto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final canProceed = await ProtectedActionHandler.checkAndHandleVerification(
          context: context,
          actionDescription: actionDescription,
          requiredVerification: requiredVerification,
        );
        if (canProceed) {
          onPressed();
        }
      },
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}