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

class _ReviewsScreenState extends State<ReviewsScreen> {
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  void _loadReviews() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reviewsProvider = Provider.of<ReviewsProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      print('❌ Utilisateur non authentifié');
      return;
    }
    
    final user = authProvider.currentUser!;
    final userRole = user.role;
    
    // ✅ DEBUG - Afficher les infos de l'utilisateur
    print('=== REVIEWS SCREEN DEBUG ===');
    print('User role (backend): $userRole');
    print('ProfileManager.isProviderMode(): ${ProfileManager.isProviderMode()}');
    print('AuthProvider.isAuthenticated: ${authProvider.isAuthenticated}');
    print('User ID: ${user.id}');
    print('=== END DEBUG ===');
    
    // ✅ LOGIQUE SIMPLIFIÉE - Charger selon le rôle réel de l'utilisateur
    if (userRole == 'provider') {
      // Prestataire : charger SEULEMENT les avis reçus
      print('🔵 Chargement avis reçus pour prestataire');
      reviewsProvider.loadReviewsReceived();
    } else {
      // Client (ou autre) : charger SEULEMENT les avis donnés
      print('🔴 Chargement avis donnés pour client');
      reviewsProvider.loadReviewsGiven();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    
    // ✅ Vérification utilisateur connecté
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.myReviews),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: _buildLoginRequired(l10n),
      );
    }

    final user = authProvider.currentUser!;
    final isProvider = user.role == 'provider';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isProvider ? l10n.reviewsReceived : l10n.myReviews), // ✅ TRADUCTION
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Consumer<ReviewsProvider>(
        builder: (context, reviewsProvider, child) {
          // ✅ Affichage selon le rôle - SIMPLE ET DIRECT
          if (isProvider) {
            return _buildProviderReviews(reviewsProvider, l10n);
          } else {
            return _buildClientReviews(reviewsProvider, l10n);
          }
        },
      ),
    );
  }

  /// Affichage pour PRESTATAIRES - Avis reçus uniquement
  Widget _buildProviderReviews(ReviewsProvider provider, AppLocalizations l10n) {
    if (provider.isLoadingReceived) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error.isNotEmpty && !provider.error.contains('You are not a provider')) {
      return _buildErrorState(provider.error, l10n);
    }

    if (provider.reviewsReceived.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_border,
        title: l10n.noReviewsReceived, // ✅ TRADUCTION
        subtitle: l10n.noReviewsReceivedSubtitle, // ✅ TRADUCTION
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadReviewsReceived(),
      child: Column(
        children: [
          // Statistiques prestataire
          _buildStatsCard(
            title: l10n.reviewsReceivedTitle, // ✅ TRADUCTION
            count: provider.reviewsReceived.length,
            averageRating: provider.averageRatingReceived,
            color: Colors.green,
            l10n: l10n, // Passer l10n pour les traductions internes
          ),
          
          // Liste des avis reçus
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

  /// Affichage pour CLIENTS - Avis donnés uniquement
  Widget _buildClientReviews(ReviewsProvider provider, AppLocalizations l10n) {
    if (provider.isLoadingGiven) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error.isNotEmpty) {
      return _buildErrorState(provider.error, l10n);
    }

    if (provider.reviewsGiven.isEmpty) {
      return _buildEmptyState(
        icon: Icons.rate_review,
        title: l10n.noReviewsGiven, // ✅ TRADUCTION
        subtitle: l10n.noReviewsGivenSubtitle, // ✅ TRADUCTION
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadReviewsGiven(),
      child: Column(
        children: [
          // Statistiques client
          _buildStatsCard(
            title: l10n.reviewsGivenTitle, // ✅ TRADUCTION
            count: provider.reviewsGiven.length,
            averageRating: provider.averageRatingGiven,
            color: Colors.blue,
            l10n: l10n, // Passer l10n pour les traductions internes
          ),
          
          // Liste des avis donnés
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

  Widget _buildErrorState(String error, AppLocalizations l10n) {
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
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Connexion requise', // Note: Ajouter à l10n si nécessaire
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
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
    required AppLocalizations l10n, // ✅ AJOUT du paramètre l10n
  }) {
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
            child: const Icon(
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
                  '$count ${l10n.reviews}', // ✅ TRADUCTION
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
                l10n.averageRating, // ✅ TRADUCTION
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
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