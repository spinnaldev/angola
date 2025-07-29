// lib/ui/screens/provider/my_offers_screen.dart - NAVIGATION AVEC OBJET PROJET COMPLET
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:teyago/ui/screens/project_detail_screen.dart';
import '../../../core/models/project_offer.dart';
import '../../../core/models/client_project.dart'; // AJOUT
import '../../../providers/offers_provider.dart';
import '../../../providers/project_provider.dart'; // AJOUT
import '../../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({Key? key}) : super(key: key);

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Charger les offres au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OffersProvider>().fetchMyOffers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myOffers),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Consumer<OffersProvider>(
            builder: (context, offersProvider, child) {
              return TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF142FE2),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF142FE2),
                tabs: [
                  Tab(text: '${l10n.allOffers} (${offersProvider.offers.length})'),
                  Tab(text: '${l10n.pendingOffers} (${offersProvider.pendingOffers.length})'),
                  Tab(text: '${l10n.acceptedOffers} (${offersProvider.acceptedOffers.length})'),
                  Tab(text: '${l10n.rejectedOffers} (${offersProvider.rejectedOffers.length})'),
                ],
              );
            },
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<OffersProvider>(
        builder: (context, offersProvider, child) {
          if (offersProvider.isLoading) {
            return const LoadingWidget();
          }

          if (offersProvider.errorMessage != null) {
            return CustomErrorWidget(
              message: offersProvider.errorMessage!,
              onRetry: () => offersProvider.fetchMyOffers(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOffersList(offersProvider.offers, l10n),
              _buildOffersList(offersProvider.pendingOffers, l10n),
              _buildOffersList(offersProvider.acceptedOffers, l10n),
              _buildOffersList(offersProvider.rejectedOffers, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOffersList(List<ProjectOffer> offers, AppLocalizations l10n) {
    if (offers.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<OffersProvider>().fetchMyOffers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return _buildOfferCard(offer, l10n);
        },
      ),
    );
  }

  Widget _buildOfferCard(ProjectOffer offer, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(offer.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    offer.projectTitle ?? l10n.projectUntitled,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildStatusBadge(offer.status, l10n),
              ],
            ),
          ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prix et délai
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.attach_money,
                        title: l10n.proposedPrice,
                        value: '${offer.proposedPrice?.toStringAsFixed(0) ?? 'N/A'} AOA',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.schedule,
                        title: l10n.deliveryTime,
                        value: '${offer.deliveryTime ?? 'N/A'} ${l10n.days}',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Message (extrait)
                if (offer.message?.isNotEmpty == true) ...[
                  Text(
                    '${l10n.message}:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.message!.length > 100 
                        ? '${offer.message!.substring(0, 100)}...'
                        : offer.message!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Options incluses
                _buildOptionsRow(offer, l10n),

                const SizedBox(height: 16),

                // Date et actions
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(offer.createdAt, l10n),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _buildActionButtons(offer, l10n),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsRow(ProjectOffer offer, AppLocalizations l10n) {
    final options = <String>[];
    
    if (offer.includesMaterials == true) options.add(l10n.materialsIncluded);
    if (offer.travelCostsIncluded == true) options.add(l10n.travelCostsIncluded);
    if (offer.warrantyPeriod != null && offer.warrantyPeriod! > 0) {
      options.add('${l10n.warranty} ${offer.warrantyPeriod} ${l10n.months}');
    }

    if (options.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.map((option) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF142FE2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          option,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildActionButtons(ProjectOffer offer, AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Voir le projet avec chargement
        Consumer<ProjectProvider>(
          builder: (context, projectProvider, child) {
            final isLoadingProject = projectProvider.isLoading;
            
            return InkWell(
              onTap: isLoadingProject ? null : () => _viewProject(offer, l10n),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isLoadingProject ? Colors.grey : const Color(0xFF142FE2),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoadingProject) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      l10n.viewProject,
                      style: TextStyle(
                        color: isLoadingProject ? Colors.grey : const Color(0xFF142FE2),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        const SizedBox(width: 8),
        
        // Retirer l'offre (si en attente)
        if (offer.status == 'pending') ...[
          InkWell(
            onTap: () => _showWithdrawDialog(offer, l10n),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.withdrawOffer,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noOffersFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.yourSubmittedOffers,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(l10n.backButton),
          ),
        ],
      ),
    );
  }

  // ✅ CORRECTION COMPLÈTE : Récupérer l'objet projet complet avant navigation
  Future<void> _viewProject(ProjectOffer offer, AppLocalizations l10n) async {
    if (offer.projectId == null) {
      _showErrorSnackBar('ID du projet manquant', l10n);
      return;
    }

    try {
      // Afficher un indicateur de chargement
      _showLoadingSnackBar('Chargement du projet...', l10n);

      // Récupérer l'objet projet complet via le ProjectProvider
      final projectProvider = context.read<ProjectProvider>();
      
      // Option 1: Si vous avez une méthode pour récupérer un projet par ID
      final project = await projectProvider.getProjectById(offer.projectId!);
      
      if (!mounted) return;
      
      // Masquer le loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (project != null) {
        // Navigation avec l'objet projet complet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(projectId: project.id),
          ),
        );
      } else {
        _showErrorSnackBar('Projet non trouvé', l10n);
      }
    } catch (e) {
      if (!mounted) return;
      
      // Masquer le loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      
      _showErrorSnackBar('Impossible de charger le projet: ${e.toString()}', l10n);
      
    }
  }

  // ✅ Créer un objet projet minimal si l'API échoue
  ClientProject? _createFallbackProject(ProjectOffer offer) {
    if (offer.projectId == null) return null;
    
    return ClientProject(
      id: offer.projectId!,
      title: offer.projectTitle ?? 'Projet sans titre',
      description: offer.projectDescription ?? 'Description non disponible',
      clientName: 'Client', // Valeur par défaut
      categoryName: 'Catégorie inconnue',
      budgetRange: 'budget_unknown',
      budgetDisplay: 'Budget à discuter',
      location: 'Localisation non spécifiée',
      remotePossible: false,
      urgency: 'medium',
      status: 'open', // Supposer que c'est ouvert si on peut faire une offre
      contactViaPlatform: true,
      showEmail: false,
      showPhone: false,
      requiredSkills: [],
      offersCount: 1, // Au moins notre offre
      viewsCount: 0,
      createdAt: offer.createdAt ?? DateTime.now(),
      timeSincePosted: 'Récemment',
      isFavorited: false,
      hasUserOffered: true, // Nous avons fait une offre
    );
  }

  void _showLoadingSnackBar(String message, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: Duration(seconds: 30), // Long pour permettre le chargement
        backgroundColor: const Color(0xFF142FE2),
      ),
    );
  }

  void _showWithdrawDialog(ProjectOffer offer, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.withdrawOfferTitle),
        content: Text(l10n.withdrawOfferConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _withdrawOffer(offer, l10n);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.withdraw),
          ),
        ],
      ),
    );
  }

  Future<void> _withdrawOffer(ProjectOffer offer, AppLocalizations l10n) async {
    if (offer.id == null) {
      _showErrorSnackBar(l10n.missingOfferId, l10n);
      return;
    }

    try {
      final success = await context.read<OffersProvider>().withdrawOffer(offer.id!);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.offerWithdrawnSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorMessage = context.read<OffersProvider>().errorMessage;
        _showErrorSnackBar(errorMessage ?? 'Erreur inconnue', l10n);
      }
    } catch (e) {
      if (!mounted) return;
      
      // Fallback: marquer localement comme retiré
      context.read<OffersProvider>().updateOfferStatus(offer.id!, 'withdrawn');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.offerWithdrawnSuccess} (local)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.error}: $message'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.grey;
      default:
        return const Color(0xFF142FE2);
    }
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'accepted':
        return l10n.accepted;
      case 'rejected':
        return l10n.rejected;
      case 'withdrawn':
        return l10n.withdrawn;
      default:
        return l10n.unknown;
    }
  }

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return l10n.daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return l10n.hoursAgo(difference.inHours);
    } else {
      return l10n.justNow;
    }
  }
}