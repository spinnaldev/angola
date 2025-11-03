// lib/ui/screens/disputes/dispute_detail_screen.dart - CORRECTION DU SCROLL

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/dispute_provider.dart';
import '../../../core/models/dispute.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/dispute_comment_form.dart';
import 'add_evidence_screen.dart';
import '../../../core/services/api_service.dart';

class DisputeDetailScreen extends StatefulWidget {
  final int disputeId;

  const DisputeDetailScreen({
    Key? key,
    required this.disputeId,
  }) : super(key: key);

  @override
  _DisputeDetailScreenState createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadDispute();
  }

  Future<void> _loadDispute() async {
    setState(() => _isRefreshing = true);
    try {
      await Provider.of<DisputeProvider>(context, listen: false)
          .fetchDisputeById(widget.disputeId);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.disputeDetail),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isRefreshing 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _loadDispute,
            tooltip: l10n.refreshDispute,
          ),
        ],
      ),
      body: Consumer<DisputeProvider>(
        builder: (context, disputeProvider, _) {
          if (disputeProvider.isLoading && !_isRefreshing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingIndicator(),
                  SizedBox(height: 16),
                  Text(
                    l10n.loadingDispute,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final dispute = disputeProvider.currentDispute;
          if (dispute == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    l10n.disputeNotFound,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadDispute,
                    icon: Icon(Icons.refresh),
                    label: Text(l10n.refreshDispute),
                  ),
                ],
              ),
            );
          }

          // ✅ SOLUTION : Utiliser Column au lieu de bottomSheet
          return Column(
            children: [
              // ✅ MODIFICATION : Contenu principal dans Expanded
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadDispute,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Carte d'information d'état
                        _buildStatusCard(dispute, l10n),
                        
                        const SizedBox(height: 16),
                        
                        // En-tête avec titre et statut
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dispute.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    l10n.disputeId(dispute.id.toString()),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            _buildStatusChip(dispute.status, l10n),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Infos sur le litige
                        _buildInfoCard([
                          _InfoItem(l10n.clientLabel, dispute.clientName, Icons.person),
                          _InfoItem(l10n.providerLabel, dispute.providerName, Icons.business),
                          if (dispute.serviceName != null)
                            _InfoItem(l10n.serviceLabel, dispute.serviceName!, Icons.work),
                          _InfoItem(
                            l10n.creationDate,
                            l10n.disputeCreatedOn( 
                              DateFormat('dd/MM/yyyy à HH:mm').format(dispute.createdAt)),
                            Icons.calendar_today,
                          ),
                        ]),
                        
                        const SizedBox(height: 20),

                        // Description du litige
                        Text(
                          l10n.problemDescription,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            dispute.description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Note de résolution (si résolue)
                        if (dispute.status == 'resolved' &&
                            dispute.resolutionNote != null) ...[
                          Text(
                            l10n.proposedSolution,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[700],
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      l10n.proposedSolution,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  dispute.resolutionNote!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Section des preuves
                        _buildEvidenceSection(dispute, l10n),
                        
                        // ✅ CORRECTION : Espacement plus important pour éviter le chevauchement
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              
              // ✅ MODIFICATION : Formulaire de commentaire en bas fixe (non-scrollable)
              _buildBottomCommentSection(dispute, l10n),
            ],
          );
        },
      ),
    );
  }

  // ✅ NOUVELLE MÉTHODE : Section commentaire en bas
  Widget _buildBottomCommentSection(Dispute dispute, AppLocalizations l10n) {
    if (dispute.status == 'closed' || dispute.status == 'resolved') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.disputeClosedInfo,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return DisputeCommentForm(
      disputeId: widget.disputeId,
      onCommentAdded: _loadDispute,
    );
  }

  Widget _buildStatusCard(Dispute dispute, AppLocalizations l10n) {
    Color backgroundColor;
    Color textColor;
    String statusMessage;
    IconData statusIcon;

    switch (dispute.status) {
      case 'open':
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[800]!;
        statusMessage = l10n.disputeOpenMessage;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'under_review':
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[800]!;
        statusMessage = l10n.disputeUnderReviewMessage;
        statusIcon = Icons.search;
        break;
      case 'resolved':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
        statusMessage = l10n.disputeResolvedMessage;
        statusIcon = Icons.check_circle;
        break;
      case 'closed':
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        statusMessage = l10n.disputeClosedMessage;
        statusIcon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        statusMessage = l10n.disputeUnknownMessage;
        statusIcon = Icons.help;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: textColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              statusMessage,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: items.map((item) => _buildInfoRow(item)).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(Dispute dispute, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.evidenceAndTestimonies,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (dispute.status == 'open' || dispute.status == 'under_review')
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddEvidenceScreen(disputeId: dispute.id!),
                    ),
                  ).then((_) => _loadDispute());
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addEvidence),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
        
        if (dispute.status == 'open' || dispute.status == 'under_review')
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 8, bottom: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            // child: Row(
            //   children: [
            //     Icon(
            //       Icons.info_outline,
            //       color: Colors.blue[700],
            //       size: 16,
            //     ),
            //     SizedBox(width: 8),
            //     Expanded(
            //       child: Text(
            //         "Vous pouvez ajouter des preuves avec fichiers ou des commentaires textuels",
            //         style: TextStyle(
            //           color: Colors.blue[800],
            //           fontSize: 12,
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
          )
        else
          SizedBox(height: 8),

        if (dispute.evidence.isEmpty)
          _buildEmptyEvidenceState(l10n)
        else
          _buildEvidenceList(dispute.evidence, l10n),
      ],
    );
  }

  Widget _buildEmptyEvidenceState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noEvidenceAdded,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceList(List<dynamic> evidence, AppLocalizations l10n) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: evidence.length,
      itemBuilder: (context, index) {
        final evidenceItem = evidence[index];
        return _buildEvidenceCard(evidenceItem, l10n);
      },
    );
  }

  Widget _buildEvidenceCard(dynamic evidence, AppLocalizations l10n) {
    // Vérification plus robuste du type de contenu
    final bool hasFile = evidence.hasFile == true || 
                        (evidence.fileUrl != null && evidence.fileUrl.toString().isNotEmpty);
    
    final bool isImage = hasFile && evidence.fileUrl != null && (
      evidence.fileUrl.endsWith('.jpg') ||
      evidence.fileUrl.endsWith('.jpeg') ||
      evidence.fileUrl.endsWith('.png')
    );
    
    // Déterminer l'icône selon le type
    IconData leadingIcon;
    Color leadingColor;
    
    if (evidence.isComment == true || !hasFile) {
      leadingIcon = Icons.comment;
      leadingColor = Colors.blue;
    } else if (isImage) {
      leadingIcon = Icons.image;
      leadingColor = Colors.green;
    } else {
      leadingIcon = Icons.insert_drive_file;
      leadingColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: leadingColor.withOpacity(0.1),
              child: Icon(
                leadingIcon,
                color: leadingColor,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    evidence.userName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: leadingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasFile ? (isImage ? 'Image' : 'Document') : 'Commentaire',
                    style: TextStyle(
                      fontSize: 10,
                      color: leadingColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              l10n.evidenceOn(
                DateFormat('dd/MM/yyyy à HH:mm').format(evidence.createdAt)
              ),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          
          // Affichage de la description toujours présent
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                evidence.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // Affichage du fichier seulement s'il existe
          if (hasFile && evidence.fileUrl != null) ...[
            if (isImage)
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.network(_getFullUrl(evidence.fileUrl!)),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.closeImage ?? 'Fermer'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(evidence.fileUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              InkWell(
                onTap: () {
                  // Télécharger ou ouvrir le fichier
                },
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.attachedFile,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              evidence.fileUrl!.split('/').last,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.download,
                        color: Colors.blue[700],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
  String _getFullUrl(String path) {
    if (path.startsWith('http')) return path;
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    final baseUrl = apiService.baseUrl.replaceAll('/api', ''); // Enlève /api
    
    return '$baseUrl$path';
  }

  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String label;

    switch (status) {
      case 'open':
        backgroundColor = Colors.orange[100]!;
        borderColor = Colors.orange[300]!;
        textColor = Colors.orange[800]!;
        label = l10n.disputeStatusOpen;
        break;
      case 'under_review':
        backgroundColor = Colors.blue[100]!;
        borderColor = Colors.blue[300]!;
        textColor = Colors.blue[800]!;
        label = l10n.disputeStatusUnderReview;
        break;
      case 'resolved':
        backgroundColor = Colors.green[100]!;
        borderColor = Colors.green[300]!;
        textColor = Colors.green[800]!;
        label = l10n.disputeStatusResolved;
        break;
      case 'closed':
        backgroundColor = Colors.grey[100]!;
        borderColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        label = l10n.disputeStatusClosed;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        borderColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        label = l10n.disputeStatusUnknown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;

  _InfoItem(this.label, this.value, this.icon);
}