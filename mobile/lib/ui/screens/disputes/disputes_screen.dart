// lib/ui/screens/disputes/disputes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/dispute_provider.dart';
import '../../../core/models/dispute.dart';
import '../../widgets/loading_indicator.dart';
import 'dispute_detail_screen.dart';
import 'create_dispute_screen.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({Key? key}) : super(key: key);

  @override
  _DisputesScreenState createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    await Provider.of<DisputeProvider>(context, listen: false).fetchUserDisputes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Litiges'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF142FE2),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF142FE2),
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Ouverts'),
            Tab(text: 'En examen'),
            Tab(text: 'Résolus'),
          ],
        ),
      ),
      body: Consumer<DisputeProvider>(
        builder: (context, disputeProvider, _) {
          if (disputeProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }
          
          final allDisputes = disputeProvider.disputes;
          final openDisputes = disputeProvider.getDisputesByStatus('open');
          final underReviewDisputes = disputeProvider.getDisputesByStatus('under_review');
          final resolvedDisputes = [...disputeProvider.getDisputesByStatus('resolved'), ...disputeProvider.getDisputesByStatus('closed')];
          
          return TabBarView(
            controller: _tabController,
            children: [
              // Onglet Tous
              _buildDisputesList(allDisputes),
              
              // Onglet Ouverts
              _buildDisputesList(openDisputes),
              
              // Onglet En examen
              _buildDisputesList(underReviewDisputes),
              
              // Onglet Résolus
              _buildDisputesList(resolvedDisputes),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateDisputeScreen(),
            ),
          ).then((_) => _loadData());
        },
        backgroundColor: const Color(0xFF142FE2),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildDisputesList(List<Dispute> disputes) {
    if (disputes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gavel,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun litige',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: disputes.length,
        itemBuilder: (context, index) {
          final dispute = disputes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisputeDetailScreen(disputeId: dispute.id!),
                  ),
                ).then((_) => _loadData());
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dispute.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusChip(dispute.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prestataire: ${dispute.providerName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Preuves: ${dispute.evidence.length}',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(dispute.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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