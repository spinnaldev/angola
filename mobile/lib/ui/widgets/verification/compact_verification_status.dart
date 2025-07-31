
import 'package:flutter/material.dart';
import 'package:teyago/core/models/user.dart';

class CompactVerificationStatus extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;

  const CompactVerificationStatus({
    Key? key,
    required this.user,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final verificationInfo = user.verificationInfo;
    
    if (verificationInfo.isVerified) {
      return const SizedBox.shrink(); // Masquer si vérifié
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: verificationInfo.statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: verificationInfo.statusColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              verificationInfo.statusIcon,
              color: verificationInfo.statusColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vérification ${verificationInfo.type == 'phone' ? 'téléphone' : 'profil'} requise',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: verificationInfo.statusColor,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Complétez votre vérification pour accéder à toutes les fonctionnalités',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: verificationInfo.statusColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}