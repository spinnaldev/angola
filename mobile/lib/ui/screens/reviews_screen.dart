import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/reviews_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../widgets/review_card.dart';
import 'base_screen.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({Key? key}) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    // Ajuster le nombre d'onglets selon le type d'utilisateur
    final isProvider = ProfileManager.isProviderMode();
    _tabController = TabController(length: isProvider ? 2 : 1, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  void _loadReviews() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Provider.of<ReviewsProvider>(context, listen: false).loadAllReviews();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isProvider = ProfileManager.isProviderMode();
    
    return BaseScreen(
      currentIndex: -1, // Pas dans la nav principale
      body: Scaffold(
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
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF142FE2),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF142FE2),
            tabs: [
              Tab(text: l10n.reviewsGiven),
              if (isProvider) Tab(text: l10n.reviewsReceived),
            ],
          ),
        ),
        body: Consumer<ReviewsProvider>(
          builder: (context, reviewsProvider, child) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildReviewsGivenTab(reviewsProvider, l10n),
                if (isProvider) _buildReviewsReceivedTab(reviewsProvider, l10n),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReviewsGivenTab(ReviewsProvider provider, AppLocalizations l10n) {
    if (provider.isLoadingGiven) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error.isNotEmpty) {
      return _buildErrorState(provider.error);
    }

    if (provider.reviewsGiven.isEmpty) {
      return _buildEmptyState(
        icon: Icons.rate_review_outlined,
        title: l10n.noReviewsGiven,
        subtitle: 'Vous n\'avez encore donné aucun avis',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadReviewsGiven(),
      child: Column(
        children: [
          // Statistiques
          _buildStatsCard(
            title: 'Avis donnés',
            count: provider.reviewsGiven.length,
            averageRating: provider.averageRatingGiven,
            color: const Color(0xFF142FE2),
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
    if (provider.isLoadingReceived) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error.isNotEmpty) {
      return _buildErrorState(provider.error);
    }

    if (provider.reviewsReceived.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_border,
        title: l10n.noReviewsReceived,
        subtitle: 'Vous n\'avez encore reçu aucun avis',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadReviewsReceived(),
      child: Column(
        children: [
          // Statistiques
          _buildStatsCard(
            title: 'Avis reçus',
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
                    showClient: true, // Afficher le client qui a évalué
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.star,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$count avis',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
    );
  }

  Widget _buildErrorState(String error) {
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
            error,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReviews,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}