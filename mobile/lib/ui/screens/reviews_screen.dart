import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/reviews_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../widgets/review_card.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({Key? key}) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController; // Nullable car pas toujours nécessaire

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTabs();
      _loadReviews();
    });
  }

  void _initializeTabs() {
    // ✅ CORRIGÉ - Créer TabController SEULEMENT pour prestataires
    final isProvider = ProfileManager.isProviderMode();
    
    if (isProvider) {
      // Prestataires ont 2 onglets : Avis donnés + Avis reçus
      _tabController = TabController(length: 2, vsync: this);
    }
    // Pour les clients : pas de TabController (un seul contenu)
  }

  void _loadReviews() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Provider.of<ReviewsProvider>(context, listen: false).loadAllReviews();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isProvider = ProfileManager.isProviderMode();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myReviews),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        // ✅ CORRIGÉ - TabBar seulement pour prestataires
        bottom: isProvider && _tabController != null ? TabBar(
          controller: _tabController!,
          labelColor: const Color(0xFF142FE2),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF142FE2),
          tabs: [
            Tab(text: l10n.reviewsGiven),
            Tab(text: l10n.reviewsReceived),
          ],
        ) : null,
      ),
      body: Consumer<ReviewsProvider>(
        builder: (context, reviewsProvider, child) {
          if (reviewsProvider.isLoadingGiven || reviewsProvider.isLoadingReceived) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reviewsProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    reviewsProvider.error,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReviews,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          // ✅ CORRIGÉ - Affichage selon le rôle avec TabController approprié
          if (isProvider && _tabController != null) {
            // Prestataires voient TabBarView avec 2 onglets
            return TabBarView(
              controller: _tabController!,
              children: [
                _buildReviewsGivenTab(reviewsProvider, l10n),
                _buildReviewsReceivedTab(reviewsProvider, l10n),
              ],
            );
          } else {
            // Clients voient directement les avis donnés (sans TabBarView)
            return _buildReviewsGivenTab(reviewsProvider, l10n);
          }
        },
      ),
    );
  }

  Widget _buildReviewsGivenTab(ReviewsProvider provider, AppLocalizations l10n) {
    if (provider.reviewsGiven.isEmpty) {
      return _buildEmptyState(
        icon: Icons.rate_review,
        title: l10n.noReviewsGiven,
        subtitle: l10n.noReviewsGivenSubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadReviewsGiven(),
      child: Column(
        children: [
          // Statistiques
          _buildStatsCard(
            title: l10n.reviewsGivenTitle,
            count: provider.reviewsGiven.length,
            averageRating: provider.averageRatingGiven,
            color: Colors.blue,
          ),
          
          // Liste des avis
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.reviewsGiven.length,
              itemBuilder: (context, index) {
                final review = provider.reviewsGiven[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ReviewCard(
                    review: review,
                    showProvider: true, // Afficher le prestataire évalué
                    showClient: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsReceivedTab(ReviewsProvider provider, AppLocalizations l10n) {
    if (provider.reviewsReceived.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_border,
        title: l10n.noReviewsReceived,
        subtitle: l10n.noReviewsReceivedSubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadReviewsReceived(),
      child: Column(
        children: [
          // Statistiques
          _buildStatsCard(
            title: l10n.reviewsReceivedTitle,
            count: provider.reviewsReceived.length,
            averageRating: provider.averageRatingReceived,
            color: Colors.green,
          ),
          
          // Liste des avis
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.reviewsReceived.length,
              itemBuilder: (context, index) {
                final review = provider.reviewsReceived[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ReviewCard(
                    review: review,
                    showProvider: false,
                    showClient: true, // Afficher le client qui a donné l'avis
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required int count,
    required double averageRating,
    required Color color,
  }) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.star,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ${l10n.reviewsCount}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.averageRating,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
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