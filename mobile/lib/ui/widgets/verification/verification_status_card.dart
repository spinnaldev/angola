// mobile/lib/ui/widgets/verification/verification_status_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/models/user.dart';
import '../../../core/models/verification_info.dart';

class VerificationStatusCard extends StatefulWidget {
  final User user;
  final VoidCallback? onVerifyPressed;
  final bool showExpanded;
  final EdgeInsets padding;

  const VerificationStatusCard({
    Key? key,
    required this.user,
    this.onVerifyPressed,
    this.showExpanded = false,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  State<VerificationStatusCard> createState() => _VerificationStatusCardState();
}

class _VerificationStatusCardState extends State<VerificationStatusCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.showExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final verificationInfo = widget.user.verificationInfo;
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: Colors.white, // BACKGROUND BLANC FORCÉ
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: Colors.white, // DOUBLE ASSURANCE BACKGROUND BLANC
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: verificationInfo.statusColor.withOpacity(0.1),
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
                        _getStatusTitle(l10n, verificationInfo),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        verificationInfo.type == 'phone' 
                            ? l10n.phoneVerification
                            : l10n.profileVerification,
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
                    child: Text(
                      'VÉRIFIÉ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Bouton pour étendre/réduire
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
            
            if (_expanded) ...[
              const SizedBox(height: 16),
              
              // Description détaillée
              Text(
                _getStatusDescription(l10n, verificationInfo),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              
              // Informations supplémentaires selon le type
              if (verificationInfo.type == 'phone' && verificationInfo.phoneNumber != null) ...[
                const SizedBox(height: 12),
                _buildPhoneInfo(l10n, verificationInfo),
              ],
              
              if (verificationInfo.type == 'documents') ...[
                const SizedBox(height: 12),
                _buildDocumentInfo(l10n, verificationInfo),
              ],
              
              // Bouton d'action si nécessaire
              if (!verificationInfo.isVerified || verificationInfo.status == 'rejected') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onVerifyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: verificationInfo.statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _getActionButtonText(l10n, verificationInfo),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              
              // Dates si disponibles
              if (verificationInfo.submittedAt != null || verificationInfo.verifiedAt != null) ...[
                const SizedBox(height: 12),
                _buildDateInfo(verificationInfo),
              ],
            ] else ...[
              // Version compacte
              const SizedBox(height: 8),
              Text(
                _getStatusDescription(l10n, verificationInfo),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Bouton d'action compact si nécessaire
              if (!verificationInfo.isVerified && verificationInfo.status != 'pending') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: widget.onVerifyPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: verificationInfo.statusColor,
                      side: BorderSide(color: verificationInfo.statusColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _getActionButtonText(l10n, verificationInfo),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  String _getStatusTitle(AppLocalizations l10n, VerificationInfo info) {
    switch (info.status) {
      case 'verified':
        return info.type == 'phone' ? l10n.phoneVerified : l10n.profileVerified;
      case 'pending':
        return l10n.verificationInProgress;
      case 'rejected':
        return l10n.verificationRejected;
      default:
        return info.type == 'phone' ? l10n.phoneNotVerified : l10n.profileNotVerified;
    }
  }
  
  String _getStatusDescription(AppLocalizations l10n, VerificationInfo info) {
    switch (info.status) {
      case 'verified':
        return info.type == 'phone' 
            ? l10n.phoneVerifiedDescription
            : l10n.profileVerifiedDescription;
      case 'pending':
        return l10n.verificationPendingDescription;
      case 'rejected':
        return '${l10n.verificationRejectedDescription} ${info.rejectionReason ?? ""}';
      default:
        return info.type == 'phone'
            ? l10n.phoneVerificationDescription
            : l10n.profileVerificationDescription;
    }
  }
  
  String _getActionButtonText(AppLocalizations l10n, VerificationInfo info) {
    switch (info.status) {
      case 'rejected':
        return l10n.submitNewDocuments;
      case 'pending':
        return l10n.viewStatus;
      default:
        return info.type == 'phone' ? l10n.verifyMyPhone : l10n.verifyMyProfile;
    }
  }
  
  Widget _buildPhoneInfo(AppLocalizations l10n, VerificationInfo info) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.phoneNumber,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.phoneNumber ?? 'Non renseigné',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentInfo(AppLocalizations l10n, VerificationInfo info) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                l10n.accountType,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            info.isBusiness == true ? l10n.business : l10n.individual,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
          if (info.documentType != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.credit_card, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  l10n.documentType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              info.documentType == 'id_card' 
                  ? l10n.idCard
                  : l10n.passport,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
          
          // Raison de rejet si applicable
          if (info.status == 'rejected' && info.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        l10n.rejectionReason,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.rejectionReason!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDateInfo(VerificationInfo info) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
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
            if (info.submittedAt != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 14,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 12),
            ],
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
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

// Widget badge simple pour affichage dans les listes
class VerificationBadge extends StatelessWidget {
  final User user;
  final double size;
  final bool showLabel;

  const VerificationBadge({
    Key? key,
    required this.user,
    this.size = 16,
    this.showLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final verificationInfo = user.verificationInfo;
    
    if (!verificationInfo.isVerified) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified,
          color: verificationInfo.statusColor,
          size: size,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            'Vérifié',
            style: TextStyle(
              color: verificationInfo.statusColor,
              fontSize: size * 0.75,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// Widget d'alerte pour actions bloquées
class VerificationAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const VerificationAlertDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // BACKGROUND BLANC FORCÉ
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPressed();
          },
          child: Text(buttonText),
        ),
      ],
    );
  }
}