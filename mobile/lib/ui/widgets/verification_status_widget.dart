
import 'package:flutter/material.dart';
import '../../../core/models/user.dart';
import '../../../core/models/verification_info.dart';

class VerificationStatusBadge extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;
  final bool showLabel;
  final double iconSize;
  final EdgeInsets padding;

  const VerificationStatusBadge({
    Key? key,
    required this.user,
    this.onTap,
    this.showLabel = true,
    this.iconSize = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final verificationInfo = user.verificationInfo;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: verificationInfo.statusColor.withOpacity(0.1),
          border: Border.all(color: verificationInfo.statusColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              verificationInfo.statusIcon,
              color: verificationInfo.statusColor,
              size: iconSize,
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                verificationInfo.statusTitle,
                style: TextStyle(
                  color: verificationInfo.statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
