
import 'package:flutter/material.dart';
import 'package:teyago/core/models/user.dart';
import 'package:teyago/core/models/verification_info.dart';

class VerificationStatusCard extends StatelessWidget {
  final User user;
  final VoidCallback? onVerifyPressed;
  final bool expanded;

  const VerificationStatusCard({
    Key? key,
    required this.user,
    this.onVerifyPressed,
    this.expanded = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final verificationInfo = user.verificationInfo;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: verificationInfo.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: verificationInfo.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    verificationInfo.statusIcon,
                    color: verificationInfo.statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verificationInfo.statusTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        verificationInfo.type == 'phone' 
                            ? 'Vérification téléphone' 
                            : 'Vérification documents',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (verificationInfo.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VÉRIFIÉ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (expanded) ...[
              const SizedBox(height: 12),
              
              // Description
              Text(
                verificationInfo.statusDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              
              // Informations supplémentaires selon le statut
              if (verificationInfo.type == 'phone' && verificationInfo.phoneNumber != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        verificationInfo.phoneNumber!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (verificationInfo.type == 'documents') ...[
                const SizedBox(height: 8),
                _buildDocumentInfo(verificationInfo),
              ],
              
              // Bouton d'action
              if (onVerifyPressed != null && 
                  (verificationInfo.status == 'not_started' || 
                   verificationInfo.status == 'rejected')) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onVerifyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: verificationInfo.statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      verificationInfo.actionButtonText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              
              // Dates
              if (verificationInfo.submittedAt != null || verificationInfo.verifiedAt != null) ...[
                const SizedBox(height: 8),
                _buildDateInfo(verificationInfo),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDocumentInfo(VerificationInfo info) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                info.isBusiness == true ? 'Entreprise' : 'Particulier',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          if (info.documentType != null) ...[
            const SizedBox(height: 4),
            Text(
              info.documentType == 'id_card' 
                  ? 'Carte d\'identité' 
                  : 'Passeport',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDateInfo(VerificationInfo info) {
    return Row(
      children: [
        if (info.submittedAt != null) ...[
          Icon(Icons.upload, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            'Soumis le ${_formatDate(info.submittedAt!)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
        if (info.verifiedAt != null) ...[
          if (info.submittedAt != null) const SizedBox(width: 12),
          Icon(Icons.check_circle, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            'Vérifié le ${_formatDate(info.verifiedAt!)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}