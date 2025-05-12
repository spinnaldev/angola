// TODO Implement this library.
// lib/ui/screens/disputes/dispute_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/dispute_provider.dart';
import '../../../core/models/dispute.dart';
import '../../widgets/loading_indicator.dart';
import 'add_evidence_screen.dart';

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
  @override
  void initState() {
    super.initState();
    _loadDispute();
  }

  Future<void> _loadDispute() async {
    await Provider.of<DisputeProvider>(context, listen: false)
        .fetchDisputeById(widget.disputeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du litige'),
        elevation: 0,
      ),
      body: Consumer<DisputeProvider>(
        builder: (context, disputeProvider, _) {
          if (disputeProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          final dispute = disputeProvider.currentDispute;
          if (dispute == null) {
            return const Center(
              child: Text('Litige non trouvé'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadDispute,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec titre et statut
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dispute.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(dispute.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Infos sur le litige
                  _buildInfoSection('Client', dispute.clientName),
                  _buildInfoSection('Prestataire', dispute.providerName),
                  if (dispute.serviceName != null)
                    _buildInfoSection('Service', dispute.serviceName!),
                  _buildInfoSection(
                    'Date de création',
                    DateFormat('dd/MM/yyyy à HH:mm').format(dispute.createdAt),
                  ),
                  const Divider(height: 32),

                  // Description du litige
                  const Text(
                    'Description du problème',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
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
                    const Text(
                      'Solution proposée',
                      style: TextStyle(
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
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[100]!),
                      ),
                      child: Text(
                        dispute.resolutionNote!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Liste des preuves
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Preuves et témoignages',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (dispute.status == 'open' ||
                          dispute.status == 'under_review')
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
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter une preuve'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (dispute.evidence.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aucune preuve ajoutée',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dispute.evidence.length,
                      itemBuilder: (context, index) {
                        final evidence = dispute.evidence[index];
                        final bool isImage =
                            evidence.fileUrl.endsWith('.jpg') ||
                                evidence.fileUrl.endsWith('.jpeg') ||
                                evidence.fileUrl.endsWith('.png');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  child: Text(
                                    evidence.userName.isNotEmpty
                                        ? evidence.userName[0].toUpperCase()
                                        : 'U',
                                  ),
                                ),
                                title: Text(evidence.userName),
                                subtitle: Text(
                                  DateFormat('dd/MM/yyyy à HH:mm')
                                      .format(evidence.createdAt),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(evidence.description),
                              ),
                              const SizedBox(height: 8),
                              if (isImage)
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(evidence.fileUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                InkWell(
                                  onTap: () {
                                    // Ouvrir le fichier (à implémenter)
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.insert_drive_file,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            evidence.fileUrl.split('/').last,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.download,
                                            color: Colors.blue),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label : ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = Colors.orange;
        label = 'Ouvert';
        break;
      case 'under_review':
        color = Colors.blue;
        label = 'En examen';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Résolu';
        break;
      case 'closed':
        color = Colors.grey;
        label = 'Fermé';
        break;
      default:
        color = Colors.grey;
        label = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
