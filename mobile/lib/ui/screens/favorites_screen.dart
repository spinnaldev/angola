import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/project_card.dart';
import '../widgets/provider_card.dart';

import 'base_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  void _loadFavorites() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Provider.of<FavoritesProvider>(context, listen: false).loadAllFavorites();
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
    
    return BaseScreen(
      currentIndex: -1, // Pas dans la nav principale
      body: Scaffold(
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
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF142FE2),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF142FE2),
            tabs: [
              Tab(text: l10n.favoriteProjects),
              Tab(text: l10n.favoriteProviders),
            ],
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
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildProjectsTab(favoritesProvider, l10n),
                _buildProvidersTab(favoritesProvider, l10n),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProjectsTab(FavoritesProvider provider, AppLocalizations l10n) {
    if (provider.favoriteProjects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        title: l10n.noFavoriteProjects,
        subtitle: 'Parcourez les projets et ajoutez-les à vos favoris',
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
              // ✅ MAINTENANT C'EST UN VoidCallback SIMPLE
              onTap: () {
                // Navigation vers le détail du projet
                Navigator.pushNamed(
                  context,
                  '/project-detail',
                  arguments: {'projectId': project.id},
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
        subtitle: 'Explorez les prestataires et ajoutez-les à vos favoris',
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
}