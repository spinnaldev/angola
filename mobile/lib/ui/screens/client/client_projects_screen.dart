// lib/ui/screens/client/client_projects_screen.dart - Version corrigée

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:teyago/ui/widgets/verification/protected_action_button.dart';
import 'package:teyago/ui/widgets/verification/protected_floating_action_button.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/models/client_project.dart';
import '../../widgets/loading_indicator.dart';
import '../project_detail_screen.dart';
import '../post_project_screen.dart';

class ClientProjectsScreen extends StatefulWidget {
  const ClientProjectsScreen({Key? key}) : super(key: key);

  @override
  _ClientProjectsScreenState createState() => _ClientProjectsScreenState();
}

class _ClientProjectsScreenState extends State<ClientProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialLoading = true; // Nouvel état pour le chargement initial
  bool _hasInitialized = false; // Pour éviter les multiples chargements

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // On appelle le chargement après que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    // Afficher le chargement seulement si c'est le premier chargement
    if (_isInitialLoading) {
      setState(() {
        _isInitialLoading = true;
      });
    }

    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    
    try {
      print('Début du chargement des projets utilisateur...'); // Debug
      await projectProvider.fetchUserProjects();
      print('Projets chargés avec succès: ${projectProvider.userProjects.length}'); // Debug
      
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des projets: $e');
      
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
        
        // Si l'erreur indique un problème d'authentification
        if (e.toString().contains('401') || 
            e.toString().contains('Unauthorized') || 
            e.toString().contains('Non autorisé') ||
            e.toString().contains('Session expirée')) {
          
          // Afficher un dialog pour se reconnecter
          _showAuthenticationDialog();
        } else {
          // Afficher l'erreur générale
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.loadingError(e.toString())),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: l10n.retryAction,
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
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.sessionExpired),
          ],
        ),
        content: Text(l10n.sessionExpiredMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retourner à l'écran précédent
            },
            child: Text(l10n.cancel),
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
            child: Text(l10n.reconnect),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProjects),
        elevation: 0,
        backgroundColor: const Color(0xFF142FE2),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.allProjects),
            Tab(text: l10n.openProjects),
            Tab(text: l10n.inProgressProjects),
            Tab(text: l10n.completedProjects),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _isInitialLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Chargement de vos projets...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Consumer<ProjectProvider>(
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
    floatingActionButton: _isInitialLoading 
          ? null // Ne pas afficher le FAB pendant le chargement initial
          : ProtectedFloatingActionButton(
              actionDescription: l10n.addProjectTooltip,
              onPressed: _navigateToAddProject,
              child: const Icon(Icons.add),
              backgroundColor: const Color(0xFF142FE2),
            ),
    );
  }

  void _navigateToAddProject() async {
    final l10n = AppLocalizations.of(context)!;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostProjectScreen(),
      ),
    );

    // Si un projet a été créé avec succès, recharger la liste
    if (result == true) {
      _loadData();
      // Optionnel: afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.projectCreatedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildProjectsList(List<ClientProject> projects) {
    final l10n = AppLocalizations.of(context)!;
    
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
              l10n.noProjectsInCategory,
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
      color: const Color(0xFF142FE2),
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
    final l10n = AppLocalizations.of(context)!;
    
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
                Flexible(
                  child: Text(
                    project.location,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Statistiques
            Row(
              children: [
                _buildStatItem(Icons.visibility, l10n.viewsCount(project.viewsCount)),
                const SizedBox(width: 16),
                _buildStatItem(Icons.local_offer, l10n.offersCount(project.offersCount)),
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
                    label: Text(l10n.view),
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
                      label: Text(l10n.close),
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
                      label: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = Colors.green;
        label = l10n.statusOpen;
        break;
      case 'in_progress':
        color = Colors.blue;
        label = l10n.statusInProgress;
        break;
      case 'completed':
        color = Colors.purple;
        label = l10n.statusCompleted;
        break;
      case 'closed':
        color = Colors.grey;
        label = l10n.statusClosed;
        break;
      case 'paused':
        color = Colors.orange;
        label = l10n.statusPaused;
        break;
      case 'cancelled':
        color = Colors.red;
        label = l10n.statusCancelled;
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
    final l10n = AppLocalizations.of(context)!;
    
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
            l10n.noProjectsYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createFirstProject,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ProtectedActionButton(
            actionDescription: l10n.addProjectTooltip,
            onPressed: _navigateToAddProject,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142FE2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add),
                const SizedBox(width: 8),
                Text(l10n.createProject),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context)!;
    
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
            l10n.errorLoading,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
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
        builder: (context) => ProjectDetailScreen(projectId: project.id),
      ),
    );
  }

  void _closeProject(ClientProject project) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await _showConfirmDialog(
      l10n.closeProject,
      l10n.closeProjectConfirm,
    );

    if (confirmed) {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF142FE2),
          ),
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
          SnackBar(
            content: Text(l10n.projectClosedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorMessage(projectProvider.errorMessage ?? 'Unknown error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteProject(ClientProject project) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await _showConfirmDialog(
      l10n.deleteProject,
      l10n.deleteProjectConfirm,
    );

    if (confirmed) {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF142FE2),
          ),
        ),
      );

      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      final success = await projectProvider.deleteProject(project.id);

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.projectDeletedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorMessage(projectProvider.errorMessage ?? 'Unknown error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final l10n = AppLocalizations.of(context)!;
    
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}