import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../widgets/project_card.dart';
import '../widgets/provider_card.dart';
import 'project_detail_screen.dart';
import 'provider_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTabs();
      _loadFavorites();
    });
  }

  void _initializeTabs() {
    // Déterminer le nombre d'onglets selon le rôle de l'utilisateur
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final isProviderMode = user?.role == 'provider'; // ✅ Utiliser le rôle réel
    
    if (isProviderMode) {
      // Prestataires voient seulement les projets favoris
      _tabController = TabController(length: 1, vsync: this);
    } else {
      // Clients voient seulement les prestataires favoris  
      _tabController = TabController(length: 1, vsync: this);
    }
  }

  void _loadFavorites() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Provider.of<FavoritesProvider>(context, listen: false).loadAllFavorites();
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isProviderMode = user?.role == 'provider'; // ✅ Utiliser le rôle réel
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myFavorites),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favoritesProvider.error.isNotEmpty) {
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
                    favoritesProvider.error,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFavorites,
                    child: Text(l10n.retry), // ✅ TRADUCTION
                  ),
                ],
              ),
            );
          }

          // ✅ Affichage selon le rôle réel de l'utilisateur
          if (isProviderMode) {
            // Prestataires voient les projets favoris
            return _buildProjectsTab(favoritesProvider, l10n);
          } else {
            // Clients voient les prestataires favoris
            return _buildProvidersTab(favoritesProvider, l10n);
          }
        },
      ),
    );
  }

  Widget _buildProjectsTab(FavoritesProvider provider, AppLocalizations l10n) {
    if (provider.favoriteProjects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        title: l10n.noFavoriteProjects,
        subtitle: 'Parcourez les projets disponibles et marquez ceux qui vous intéressent comme favoris pour les retrouver facilement', // ✅ MESSAGE PLUS DESCRIPTIF
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFavoriteProjects(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.favoriteProjects.length,
        itemBuilder: (context, index) {
          final project = provider.favoriteProjects[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ProjectCard(
              project: project,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectDetailScreen(
                      projectId: project.id,
                    ),
                  ),
                );
              },
              onFavoriteToggle: () {
                provider.toggleProjectFavorite(project.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProvidersTab(FavoritesProvider provider, AppLocalizations l10n) {
    if (provider.favoriteProviders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: l10n.noFavoriteProviders,
        subtitle: 'Explorez les prestataires de services et ajoutez vos favoris pour les retrouver rapidement', // ✅ MESSAGE PLUS DESCRIPTIF
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFavoriteProviders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.favoriteProviders.length,
        itemBuilder: (context, index) {
          final providerModel = provider.favoriteProviders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ProviderCard(
              provider: providerModel,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProviderDetailScreen(
                      providerId: providerModel.id,
                    ),
                  ),
                );
              },
              onFavoriteToggle: () {
                provider.toggleProviderFavorite(providerModel.id);
              },
            ),
          );
        },
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}