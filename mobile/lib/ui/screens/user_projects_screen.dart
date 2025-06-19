// lib/ui/screens/user_projects_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/client_project.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/project_card.dart';
import 'project_detail_screen.dart';
import 'post_project_screen.dart';

class UserProjectsScreen extends StatefulWidget {
  const UserProjectsScreen({Key? key}) : super(key: key);

  @override
  State<UserProjectsScreen> createState() => _UserProjectsScreenState();
}

class _UserProjectsScreenState extends State<UserProjectsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProjects();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProjects() async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    await projectProvider.fetchUserProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes projets',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF142FE2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PostProjectScreen(),
                ),
              );
              if (result == true) {
                _loadUserProjects();
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          if (projectProvider.isLoadingUserProjects) {
            return const Center(child: CircularProgressIndicator());
          }

          if (projectProvider.errorMessage != null) {
            return _buildErrorState(projectProvider.errorMessage!);
          }

          return Column(
            children: [
              _buildStatsHeader(projectProvider),
              _buildTabBar(),
              Expanded(
                child: _buildTabBarView(projectProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(ProjectProvider projectProvider) {
    final stats = projectProvider.getUserProjectStats();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142FE2).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total',
                '${stats['total_projects']}',
                Icons.folder,
              ),
              _buildStatItem(
                'Ouverts',
                '${stats['open_projects']}',
                Icons.folder_open,
              ),
              _buildStatItem(
                'En cours',
                '${stats['in_progress_projects']}',
                Icons.schedule,
              ),
              _buildStatItem(
                'Terminés',
                '${stats['completed_projects']}',
                Icons.check_circle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${stats['total_offers']} offres reçues au total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF142FE2),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF142FE2),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Tous'),
          Tab(text: 'Ouverts'),
          Tab(text: 'En cours'),
          Tab(text: 'Terminés'),
        ],
      ),
    );
  }

  Widget _buildTabBarView(ProjectProvider projectProvider) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProjectsList(projectProvider.userProjects, 'all'),
        _buildProjectsList(
          projectProvider.userProjects
              .where((p) => p.status == 'open')
              .toList(),
          'open',
        ),
        _buildProjectsList(
          projectProvider.userProjects
              .where((p) => p.status == 'in_progress')
              .toList(),
          'in_progress',
        ),
        _buildProjectsList(
          projectProvider.userProjects
              .where((p) => p.status == 'completed')
              .toList(),
          'completed',
        ),
      ],
    );
  }

  Widget _buildProjectsList(List<ClientProject> projects, String filter) {
    if (projects.isEmpty) {
      return _buildEmptyState(filter);
    }

    return RefreshIndicator(
      onRefresh: _loadUserProjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildProjectCard(project),
          );
        },
      ),
    );
  }

  Widget _buildProjectCard(ClientProject project) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToProjectDetail(project),
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
                      project.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildStatusChip(project.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF142FE2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      project.categoryName,
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  Text(
                    project.location,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.euro, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    project.budgetDisplay,
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.mail, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${project.offersCount} offres',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${project.viewsCount} vues',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    project.timeSincePosted ?? 'Récemment',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  _buildProjectActions(project),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'open':
        color = Colors.green;
        text = 'Ouvert';
        icon = Icons.folder_open;
        break;
      case 'in_progress':
        color = Colors.orange;
        text = 'En cours';
        icon = Icons.schedule;
        break;
      case 'completed':
        color = Colors.blue;
        text = 'Terminé';
        icon = Icons.check_circle;
        break;
      case 'closed':
        color = Colors.grey;
        text = 'Fermé';
        icon = Icons.folder;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectActions(ClientProject project) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleProjectAction(project, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 18),
              SizedBox(width: 8),
              Text('Voir les détails'),
            ],
          ),
        ),
        if (project.status == 'open') ...[
          const PopupMenuItem(
            value: 'pause',
            child: Row(
              children: [
                Icon(Icons.pause, size: 18),
                SizedBox(width: 8),
                Text('Mettre en pause'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'close',
            child: Row(
              children: [
                Icon(Icons.close, size: 18),
                SizedBox(width: 8),
                Text('Fermer'),
              ],
            ),
          ),
        ],
        if (project.status == 'in_progress')
          const PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 18),
                SizedBox(width: 8),
                Text('Marquer terminé'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Supprimer', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Icon(
        Icons.more_vert,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case 'open':
        title = 'Aucun projet ouvert';
        subtitle = 'Créez un nouveau projet pour commencer';
        icon = Icons.folder_open;
        break;
      case 'in_progress':
        title = 'Aucun projet en cours';
        subtitle = 'Vos projets actifs apparaîtront ici';
        icon = Icons.schedule;
        break;
      case 'completed':
        title = 'Aucun projet terminé';
        subtitle = 'Vos projets finalisés apparaîtront ici';
        icon = Icons.check_circle;
        break;
      default:
        title = 'Aucun projet créé';
        subtitle = 'Commencez par créer votre premier projet';
        icon = Icons.folder;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (filter == 'all' || filter == 'open') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostProjectScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadUserProjects();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer un projet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142FE2),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              onPressed: _loadUserProjects,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF142FE2),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProjectDetail(ClientProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }

  void _handleProjectAction(ClientProject project, String action) async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);

    switch (action) {
      case 'view':
        _navigateToProjectDetail(project);
        break;

      case 'pause':
        await _updateProjectStatus(project, 'paused');
        break;

      case 'close':
        await _showConfirmDialog(
          'Fermer le projet',
          'Êtes-vous sûr de vouloir fermer ce projet ? Cette action est irréversible.',
          () => _updateProjectStatus(project, 'closed'),
        );
        break;

      case 'complete':
        await _updateProjectStatus(project, 'completed');
        break;

      case 'delete':
        await _showConfirmDialog(
          'Supprimer le projet',
          'Êtes-vous sûr de vouloir supprimer ce projet ? Cette action est irréversible.',
          () => _deleteProject(project),
        );
        break;
    }
  }

  Future<void> _updateProjectStatus(
      ClientProject project, String newStatus) async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);

    final success =
        await projectProvider.updateProjectStatus(project.id, newStatus);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut du projet mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour du statut'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProject(ClientProject project) async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);

    final success = await projectProvider.deleteProject(project.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Projet supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression du projet'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showConfirmDialog(
      String title, String content, VoidCallback onConfirm) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Confirmer'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }
}
