// lib/ui/screens/disputes/disputes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/dispute_provider.dart';
import '../../../core/services/profile_manager.dart';
import '../../../core/models/dispute.dart';
import '../../widgets/loading_indicator.dart';
import 'create_dispute_screen.dart';
import 'dispute_detail_screen.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({Key? key}) : super(key: key);

  @override
  _DisputesScreenState createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen>
    with TickerProviderStateMixin {
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

  List<Tab> _getTabs() {
    if (ProfileManager.isProviderMode()) {
      return const [
        Tab(text: 'Résumé'),
        Tab(text: 'Réclamations ouvertes'),
        Tab(text: 'En traitement'),
        Tab(text: 'Résolues'),
      ];
    } else {
      return const [
        Tab(text: 'Résumé'),
        Tab(text: 'Litiges ouverts'),
        Tab(text: 'En examen'),
        Tab(text: 'Résolus'),
      ];
    }
  }

  List<Widget> _getTabViews(DisputeProvider disputeProvider) {
    final allDisputes = disputeProvider.disputes;
    final openDisputes = disputeProvider.getDisputesByStatus('open');
    final underReviewDisputes = disputeProvider.getDisputesByStatus('under_review');
    final resolvedDisputes = [
      ...disputeProvider.getDisputesByStatus('resolved'),
      ...disputeProvider.getDisputesByStatus('closed')
    ];

    return [
      _buildStatusSummary(disputeProvider),
      _buildDisputesList(openDisputes),
      _buildDisputesList(underReviewDisputes),
      _buildDisputesList(resolvedDisputes),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: _getTabs(),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: Consumer<DisputeProvider>(
        builder: (context, disputeProvider, _) {
          if (disputeProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: _getTabViews(disputeProvider),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateDisputeScreen(),
            ),
          ).then((_) => _loadData());
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_getFabLabel()),
      ),
    );
  }

  String _getAppBarTitle() {
    return ProfileManager.isProviderMode() 
      ? 'Mes réclamations' 
      : 'Mes litiges';
  }

  String _getFabLabel() {
    return ProfileManager.isProviderMode() 
      ? 'Nouvelle réclamation' 
      : 'Nouveau litige';
  }

  Widget _buildStatusSummary(DisputeProvider disputeProvider) {
    final openCount = disputeProvider.getDisputesByStatus('open').length;
    final underReviewCount = disputeProvider.getDisputesByStatus('under_review').length;
    final resolvedCount = disputeProvider.getDisputesByStatus('resolved').length + 
                         disputeProvider.getDisputesByStatus('closed').length;
    final totalCount = disputeProvider.disputes.length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de bienvenue
            _buildWelcomeCard(),
            
            const SizedBox(height: 16),
            
            // Statistiques
            Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            
            // Cartes de statistiques
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    totalCount.toString(),
                    Colors.blue,
                    Icons.gavel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    ProfileManager.isProviderMode() ? 'Ouvertes' : 'Ouverts',
                    openCount.toString(),
                    Colors.orange,
                    Icons.hourglass_empty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'En traitement',
                    underReviewCount.toString(),
                    Colors.purple,
                    Icons.search,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    ProfileManager.isProviderMode() ? 'Résolues' : 'Résolus',
                    resolvedCount.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Litiges récents
            if (totalCount > 0) ...[
              Text(
                ProfileManager.isProviderMode() 
                  ? 'Réclamations récentes'
                  : 'Litiges récents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              ...disputeProvider.disputes.take(3).map((dispute) => 
                _buildDisputeCard(dispute, isCompact: true)),
            ] else ...[
              _buildEmptyState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      color: ProfileManager.isProviderMode() ? Colors.blue[50] : Colors.green[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ProfileManager.isProviderMode() ? Icons.report_outlined : Icons.gavel,
                  color: ProfileManager.isProviderMode() ? Colors.blue[700] : Colors.green[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  ProfileManager.isProviderMode() 
                    ? 'Centre de réclamations'
                    : 'Centre de litiges',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ProfileManager.isProviderMode() ? Colors.blue[700] : Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ProfileManager.isProviderMode()
                ? 'Gérez vos réclamations contre les clients et suivez leur traitement.'
                : 'Signalez des problèmes avec les prestataires et suivez leur résolution.',
              style: TextStyle(
                color: ProfileManager.isProviderMode() ? Colors.blue[600] : Colors.green[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputesList(List<Dispute> disputes) {
    if (disputes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: disputes.length,
        itemBuilder: (context, index) {
          final dispute = disputes[index];
          return _buildDisputeCard(dispute);
        },
      ),
    );
  }

  Widget _buildDisputeCard(Dispute dispute, {bool isCompact = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Vérification null-safety avant navigation
          final disputeId = dispute.id;
          if (disputeId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisputeDetailScreen(disputeId: disputeId), // Maintenant disputeId est int
              ),
            ).then((_) => _loadData());
          } else {
            // Gérer le cas où l'ID est null
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Impossible d\'ouvrir ce litige'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dispute.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: isCompact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(dispute.status),
                ],
              ),
              const SizedBox(height: 8),
              
              if (!isCompact) ...[
                Text(
                  dispute.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              Row(
                children: [
                  Icon(
                    ProfileManager.isProviderMode() ? Icons.person : Icons.work,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ProfileManager.isProviderMode() 
                      ? 'Client: ${dispute.clientName}'
                      : 'Prestataire: ${dispute.providerName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
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
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'open':
        color = Colors.orange;
        label = ProfileManager.isProviderMode() ? 'Ouverte' : 'Ouvert';
        break;
      case 'under_review':
        color = Colors.blue;
        label = 'En examen';
        break;
      case 'resolved':
        color = Colors.green;
        label = ProfileManager.isProviderMode() ? 'Résolue' : 'Résolu';
        break;
      case 'closed':
        color = Colors.grey;
        label = ProfileManager.isProviderMode() ? 'Fermée' : 'Fermé';
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            ProfileManager.isProviderMode() ? Icons.report_outlined : Icons.gavel,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            ProfileManager.isProviderMode() 
              ? 'Aucune réclamation'
              : 'Aucun litige',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ProfileManager.isProviderMode()
              ? 'Vous n\'avez créé aucune réclamation pour le moment.'
              : 'Vous n\'avez signalé aucun problème pour le moment.',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}