import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ AJOUT
import 'package:teyago/ui/widgets/verification/protected_floating_action_button.dart';
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

  // ✅ Méthode pour obtenir les onglets traduits
  List<Tab> _getTabs(AppLocalizations l10n) {
    if (ProfileManager.isProviderMode()) {
      return [
        Tab(text: l10n.summary),
        Tab(text: l10n.openComplaints),
        Tab(text: l10n.inProcessing),
        Tab(text: l10n.resolvedComplaints),
      ];
    } else {
      return [
        Tab(text: l10n.summary),
        Tab(text: l10n.openDisputes),
        Tab(text: l10n.underReview),
        Tab(text: l10n.resolvedDisputes),
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
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_getAppBarTitle(l10n)), // ✅ PASSER l10n
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: _getTabs(l10n), // ✅ PASSER l10n
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
      
      floatingActionButton : ProtectedFloatingActionButton(
        actionDescription: l10n.newComplaint,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateDisputeScreen(),
            ),
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.white,
      )
      
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => const CreateDisputeScreen(),
      //       ),
      //     ).then((_) => _loadData());
      //   },
      //   backgroundColor: Theme.of(context).primaryColor,
      //   foregroundColor: Colors.white,
      //   icon: const Icon(Icons.add),
      //   label: Text(_getFabLabel(l10n)), // ✅ PASSER l10n
      // ),
    );
  }

  // ✅ Méthodes utilitaires avec traduction
  String _getAppBarTitle(AppLocalizations l10n) {
    return ProfileManager.isProviderMode() 
      ? l10n.myComplaints
      : l10n.myDisputes;
  }

  String _getFabLabel(AppLocalizations l10n) {
    return ProfileManager.isProviderMode() 
      ? l10n.newComplaint
      : l10n.newDispute;
  }

  Widget _buildStatusSummary(DisputeProvider disputeProvider) {
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT
    
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
            _buildWelcomeCard(l10n), // ✅ PASSER l10n
            
            const SizedBox(height: 16),
            
            // Statistiques
            Text(
              l10n.statistics, // ✅ TRADUIT
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
                    l10n.total, // ✅ TRADUIT
                    totalCount.toString(),
                    Colors.blue,
                    Icons.gavel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    ProfileManager.isProviderMode() 
                      ? l10n.openFeminine // ✅ "Ouvertes" (féminin pour réclamations)
                      : l10n.openMasculine, // ✅ "Ouverts" (masculin pour litiges)
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
                    l10n.inProcessing, // ✅ TRADUIT
                    underReviewCount.toString(),
                    Colors.purple,
                    Icons.search,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    ProfileManager.isProviderMode() 
                      ? l10n.resolvedFeminine // ✅ "Résolues" (féminin)
                      : l10n.resolvedMasculine, // ✅ "Résolus" (masculin)
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
                  ? l10n.recentComplaints // ✅ TRADUIT
                  : l10n.recentDisputes, // ✅ TRADUIT
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
              _buildEmptyState(l10n), // ✅ PASSER l10n
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
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
                Expanded( // ✅ AJOUT pour éviter overflow
                  child: Text(
                    ProfileManager.isProviderMode() 
                      ? l10n.complaintsCenter // ✅ TRADUIT
                      : l10n.disputesCenter, // ✅ TRADUIT
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ProfileManager.isProviderMode() ? Colors.blue[700] : Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ProfileManager.isProviderMode()
                ? l10n.manageComplaintsDescription // ✅ TRADUIT
                : l10n.reportProblemsDescription, // ✅ TRADUIT
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
              maxLines: 1, // ✅ AJOUT pour éviter overflow
              overflow: TextOverflow.ellipsis, // ✅ AJOUT
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputesList(List<Dispute> disputes) {
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT

    if (disputes.isEmpty) {
      return _buildEmptyState(l10n); // ✅ PASSER l10n
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
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT

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
                builder: (context) => DisputeDetailScreen(disputeId: disputeId),
              ),
            ).then((_) => _loadData());
          } else {
            // Gérer le cas où l'ID est null
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.cannotOpenDispute), // ✅ TRADUIT
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
                  _buildStatusChip(dispute.status, l10n), // ✅ PASSER l10n
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
                  Expanded( // ✅ AJOUT pour éviter overflow
                    child: Text(
                      ProfileManager.isProviderMode() 
                        ? '${l10n.client}: ${dispute.clientName}' // ✅ TRADUIT
                        : '${l10n.provider}: ${dispute.providerName}', // ✅ TRADUIT
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis, // ✅ AJOUT
                    ),
                  ),
                  const SizedBox(width: 8), // ✅ AJOUT d'espace
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

  Widget _buildStatusChip(String status, AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
    Color color;
    String label;
    
    switch (status) {
      case 'open':
        color = Colors.orange;
        label = ProfileManager.isProviderMode() 
          ? l10n.openFeminine // ✅ "Ouverte" (féminin)
          : l10n.openMasculine; // ✅ "Ouvert" (masculin)
        break;
      case 'under_review':
        color = Colors.blue;
        label = l10n.underReview; // ✅ TRADUIT
        break;
      case 'resolved':
        color = Colors.green;
        label = ProfileManager.isProviderMode() 
          ? l10n.resolvedFeminine // ✅ "Résolue" (féminin)
          : l10n.resolvedMasculine; // ✅ "Résolu" (masculin)
        break;
      case 'closed':
        color = Colors.grey;
        label = ProfileManager.isProviderMode() 
          ? l10n.closedFeminine // ✅ "Fermée" (féminin)
          : l10n.closedMasculine; // ✅ "Fermé" (masculin)
        break;
      default:
        color = Colors.grey;
        label = l10n.unknown; // ✅ TRADUIT
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

  Widget _buildEmptyState(AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
    return Center(
      child: Padding( // ✅ AJOUT de padding pour éviter les problèmes d'espace
        padding: const EdgeInsets.all(32),
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
                ? l10n.noComplaints // ✅ TRADUIT
                : l10n.noDisputes, // ✅ TRADUIT
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center, // ✅ AJOUT
            ),
            const SizedBox(height: 8),
            Text(
              ProfileManager.isProviderMode()
                ? l10n.noComplaintsDescription // ✅ TRADUIT
                : l10n.noDisputesDescription, // ✅ TRADUIT
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}