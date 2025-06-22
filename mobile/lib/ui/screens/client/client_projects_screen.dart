// lib/ui/screens/client/client_projects_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/models/client_project.dart';
import '../../widgets/loading_indicator.dart';
import '../project_detail_screen.dart';
import '../post_project_screen.dart'; // Import pour la page d'ajout de projet

class ClientProjectsScreen extends StatefulWidget {
  const ClientProjectsScreen({Key? key}) : super(key: key);

  @override
  _ClientProjectsScreenState createState() => _ClientProjectsScreenState();
}

class _ClientProjectsScreenState extends State<ClientProjectsScreen>
    with SingleTickerProviderStateMixin {
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
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    
    try {
      await projectProvider.fetchUserProjects();
    } catch (e) {
      print('Erreur lors du chargement des projets: $e');
      
      // Si l'erreur indique un problème d'authentification
      if (e.toString().contains('401') || 
          e.toString().contains('Unauthorized') || 
          e.toString().contains('Session expirée')) {
        
        // Afficher un dialog pour se reconnecter
        if (mounted) {
          _showAuthenticationDialog();
        }
      } else {
        // Afficher l'erreur générale
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: _loadData,
              ),
            ),
          );
        }
      }
    }
  }

  void _showAuthenticationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Session expirée'),
          ],
        ),
        content: const Text(
          'Votre session a expiré. Veuillez vous reconnecter pour accéder à vos projets.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retourner à l'écran précédent
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Déconnecter l'utilisateur
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              
              // Rediriger vers la page de connexion
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142FE2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Se reconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes projets'),
        elevation: 0,
        backgroundColor: const Color(0xFF142FE2),
        foregroundColor: Colors.white,
        actions: [
          // Bouton + pour ajouter un nouveau projet
          IconButton(
            onPressed: _navigateToAddProject,
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un projet',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Ouverts'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminés'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, _) {
          if (projectProvider.isLoadingUserProjects) {
            return const Center(child: LoadingIndicator());
          }

          if (projectProvider.errorMessage != null) {
            return _buildErrorState(projectProvider.errorMessage!);
          }

          final projects = projectProvider.userProjects;

          if (projects.isEmpty) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProjectsList(projects), // Tous
              _buildProjectsList(projects
                  .where((p) => p.status == 'open')
                  .toList()), // Ouverts
              _buildProjectsList(projects
                  .where((p) => p.status == 'in_progress')
                  .toList()), // En cours
              _buildProjectsList(projects
                  .where((p) => p.status == 'completed' || p.status == 'closed')
                  .toList()), // Terminés
            ],
          );
        },
      ),
      // Bouton flottant alternatif (optionnel)
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProject,
        backgroundColor: const Color(0xFF142FE2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un projet',
      ),
    );
  }

  void _navigateToAddProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostProjectScreen(),
      ),
    );

    // Si un projet a été créé avec succès, recharger la liste
    if (result == true) {
      _loadData();
    }
  }

  Widget _buildProjectsList(List<ClientProject> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun projet dans cette catégorie',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return _buildProjectCard(project);
        },
      ),
    );
  }

  Widget _buildProjectCard(ClientProject project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et statut
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(project.status),
              ],
            ),
            const SizedBox(height: 12),

            // Description (tronquée)
            Text(
              project.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Informations du projet
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  project.categoryName,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  project.location,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Statistiques
            Row(
              children: [
                _buildStatItem(Icons.visibility, '${project.viewsCount} vues'),
                const SizedBox(width: 16),
                _buildStatItem(
                    Icons.local_offer, '${project.offersCount} offres'),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy').format(project.createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewProject(project),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Voir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF142FE2),
                      side: const BorderSide(color: Color(0xFF142FE2)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (project.status == 'open')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _closeProject(project),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Clôturer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (project.status != 'open') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteProject(project),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Supprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = Colors.green;
        label = 'Ouvert';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'En cours';
        break;
      case 'completed':
        color = Colors.purple;
        label = 'Terminé';
        break;
      case 'closed':
        color = Colors.grey;
        label = 'Clôturé';
        break;
      case 'paused':
        color = Colors.orange;
        label = 'En pause';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Vous n\'avez pas encore de projets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier projet pour commencer',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddProject,
            icon: const Icon(Icons.add),
            label: const Text('Créer un projet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142FE2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142FE2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewProject(ClientProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }

  void _closeProject(ClientProject project) async {
    final confirmed = await _showConfirmDialog(
      'Clôturer le projet',
      'Êtes-vous sûr de vouloir clôturer ce projet ? Les prestataires ne pourront plus soumettre d\'offres.',
    );

    if (confirmed) {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      final success =
          await projectProvider.updateProjectStatus(project.id, 'closed');

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projet clôturé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${projectProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteProject(ClientProject project) async {
    final confirmed = await _showConfirmDialog(
      'Supprimer le projet',
      'Êtes-vous sûr de vouloir supprimer ce projet ? Cette action est irréversible.',
    );

    if (confirmed) {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      final success = await projectProvider.deleteProject(project.id);

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projet supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${projectProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}