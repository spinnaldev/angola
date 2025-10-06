// mobile/lib/ui/screens/favorites_screen.dart
// VERSION ADAPTÉE - Les clients voient des SERVICES favoris

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/service.dart';
import '../widgets/project_card.dart';
import '../widgets/service_image.dart';
import 'project_detail_screen.dart';
import 'service_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  
  @override
  void initState() {
    super.initState();
    
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isProviderMode = user?.role == 'provider';
    
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
                    child: Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // ✅ Affichage selon le rôle
          if (isProviderMode) {
            // Prestataires voient les projets favoris
            return _buildProjectsTab(favoritesProvider, l10n);
          } else {
            // ✅ CHANGEMENT : Clients voient les SERVICES favoris
            return _buildServicesTab(favoritesProvider, l10n);
          }
        },
      ),
    );
  }

  // ✅ Onglet PROJETS pour les prestataires (inchangé)
  Widget _buildProjectsTab(FavoritesProvider provider, AppLocalizations l10n) {
    if (provider.favoriteProjects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        title: l10n.noFavoriteProjects,
        subtitle: 'Parcourez les projets disponibles et marquez ceux qui vous intéressent comme favoris',
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

  // ✅ NOUVEAU : Onglet SERVICES pour les clients
  Widget _buildServicesTab(FavoritesProvider provider, AppLocalizations l10n) {
    if (provider.favoriteServices.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'Aucun service favori',
        subtitle: 'Explorez les services et ajoutez vos préférés pour les retrouver facilement',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFavoriteServices(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.favoriteServices.length,
        itemBuilder: (context, index) {
          final service = provider.favoriteServices[index];
          return _buildServiceCard(context, service, provider);
        },
      ),
    );
  }

  // ✅ Card pour afficher un service favori
  Widget _buildServiceCard(
    BuildContext context, 
    Service service,
    FavoritesProvider provider
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(
                serviceId: service.id,
                providerId: service.provider_id ?? 0,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du service
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: ServiceImage(
                imageUrl: service.imageUrl,
                width: double.infinity,
                height: 100,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et bouton favoris
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          service.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Bouton retirer des favoris
                      IconButton(
                        onPressed: () => _showRemoveDialog(context, service, provider),
                        icon: Icon(Icons.favorite, color: Colors.red),
                        tooltip: 'Retirer des favoris',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Prix
                  Row(
                    children: [
                      Text(
                        '${service.price} FCFA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF142FE2),
                        ),
                      ),
                      if (service.priceType != null && service.priceType!.isNotEmpty) ...[
                        Text(
                          ' / ${service.priceType}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Catégorie et note
                  Row(
                    children: [
                      // if (service.categoryName != null) ...[
                      //   Container(
                      //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      //     decoration: BoxDecoration(
                      //       color: Colors.blue[50],
                      //       borderRadius: BorderRadius.circular(4),
                      //     ),
                      //     child: Text(
                      //       service.categoryId!,
                      //       style: TextStyle(
                      //         fontSize: 12,
                      //         color: Colors.blue[700],
                      //       ),
                      //     ),
                      //   ),
                      // ],
                      const Spacer(),
                      if (service.rating != null && service.rating! > 0) ...[
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          service.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (service.reviewCount != null && service.reviewCount! > 0) ...[
                          Text(
                            ' (${service.reviewCount})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog de confirmation pour retirer des favoris
  Future<void> _showRemoveDialog(
    BuildContext context,
    Service service,
    FavoritesProvider provider
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retirer des favoris'),
        content: Text('Voulez-vous retirer "${service.title}" de vos favoris ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.toggleServiceFavorite(service.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service retiré des favoris'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  // État vide
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}