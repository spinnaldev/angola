// MODIFICATIONS CLÉS POUR AFFICHER LES PRESTATAIRES FAVORIS
// 
// Ligne 74-78 : Logique d'affichage changée
// - Clients voient maintenant les PRESTATAIRES favoris (pas les services)
// - Prestataires voient toujours les PROJETS favoris (inchangé)
//
// Ligne 150-279 : Nouvel onglet _buildProvidersTab() pour afficher les prestataires
// - Remplace l'ancien _buildServicesTab()
// - Affiche les informations du prestataire (nom, note, services, etc.)
// - Navigation vers ProviderDetailScreen

// mobile/lib/ui/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/provider_model.dart';
import '../widgets/project_card.dart';
import 'project_detail_screen.dart';
import 'provider_detail_screen.dart'; // ✅ AJOUTÉ

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

          // ✅ CHANGEMENT : Affichage selon le rôle
          if (isProviderMode) {
            // Prestataires voient les projets favoris (inchangé)
            return _buildProjectsTab(favoritesProvider, l10n);
          } else {
            // ✅ MODIFIÉ : Clients voient les PRESTATAIRES favoris (pas les services)
            return _buildProvidersTab(favoritesProvider, l10n);
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

  // ✅ NOUVEAU : Onglet PRESTATAIRES pour les clients
  Widget _buildProvidersTab(FavoritesProvider provider, AppLocalizations l10n) {
    if (provider.favoriteProviders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'Aucun prestataire favori',
        subtitle: 'Explorez les prestataires et ajoutez vos préférés pour les retrouver facilement',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFavoriteProviders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.favoriteProviders.length,
        itemBuilder: (context, index) {
          final favoriteProvider = provider.favoriteProviders[index];
          return _buildProviderCard(context, favoriteProvider, provider);
        },
      ),
    );
  }

  // ✅ Card pour afficher un prestataire favori
  Widget _buildProviderCard(
    BuildContext context, 
    ProviderModel favoriteProvider,
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
              builder: (context) => ProviderDetailScreen(
                providerId: favoriteProvider.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar du prestataire
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFF142FE2).withOpacity(0.1),
                backgroundImage: favoriteProvider.profileImageUrl.isNotEmpty
                    ? NetworkImage(favoriteProvider.profileImageUrl)
                    : null,
                child: favoriteProvider.profileImageUrl.isEmpty
                    ? Text(
                        favoriteProvider.name.isNotEmpty
                            ? favoriteProvider.name.substring(0, 1).toUpperCase()
                            : "P",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF142FE2),
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Informations du prestataire
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et badge vérifié
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            favoriteProvider.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (favoriteProvider.isVerified)
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF142FE2),
                            size: 20,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Type d'entreprise ou bio
                    if (favoriteProvider.businessType != null && 
                        favoriteProvider.businessType!.isNotEmpty)
                      Text(
                        favoriteProvider.businessType!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Note et nombre d'avis
                    Row(
                      children: [
                        if (favoriteProvider.rating != null && favoriteProvider.rating! > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF142FE2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  favoriteProvider.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (favoriteProvider.reviewCount != null && 
                              favoriteProvider.reviewCount! > 0)
                            Text(
                              '(${favoriteProvider.reviewCount} avis)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                        
                        const Spacer(),
                        
                        // Nombre de services si disponible
                        // if (favoriteProvider.servicesCount != null && 
                        //     favoriteProvider.servicesCount! > 0)
                        //   Container(
                        //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        //     decoration: BoxDecoration(
                        //       color: Colors.grey[100],
                        //       borderRadius: BorderRadius.circular(12),
                        //     ),
                        //     child: Row(
                        //       children: [
                        //         Icon(Icons.work_outline, size: 14, color: Colors.grey[700]),
                        //         const SizedBox(width: 4),
                        //         Text(
                        //           '${favoriteProvider.servicesCount} services',
                        //           style: TextStyle(
                        //             fontSize: 12,
                        //             color: Colors.grey[700],
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Bouton retirer des favoris
              IconButton(
                onPressed: () => _showRemoveDialog(context, favoriteProvider, provider),
                icon: const Icon(Icons.favorite, color: Colors.red),
                tooltip: 'Retirer des favoris',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog de confirmation pour retirer des favoris
  Future<void> _showRemoveDialog(
    BuildContext context,
    ProviderModel favoriteProvider,
    FavoritesProvider provider
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retirer des favoris'),
        content: Text('Voulez-vous retirer "${favoriteProvider.name}" de vos prestataires favoris ?'),
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
      await provider.toggleProviderFavorite(favoriteProvider.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prestataire retiré des favoris'),
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