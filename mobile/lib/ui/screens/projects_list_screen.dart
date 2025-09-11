// lib/ui/screens/projects_list_screen.dart - Version complète avec traductions
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/models/client_project.dart';
import '../../core/models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../widgets/project_card.dart';
import './base_screen.dart';
import 'project_detail_screen.dart';
import 'search_results_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;

  const ProjectsListScreen({
    Key? key,
    this.categoryId,
    this.categoryName,
  }) : super(key: key);

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<ClientProject> _projects = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;

  // Statistiques prestataire
  Map<String, dynamic>? _providerStats;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadProviderStats(),
      _loadProjects(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadProviderStats() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final stats = await apiService.getProviderStats();
      if (mounted) {
        setState(() {
          _providerStats = stats;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      // Statistiques mock en cas d'erreur
      if (mounted) {
        setState(() {
          _providerStats = {
            'prestations_completed_this_month': 8,
            'prestations_in_progress': 3,
            'unread_messages': 5,
            'total_earnings_this_month': 2400.0,
            'avg_rating': 4.7,
            'total_reviews': 24,
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.getProjects({
        if (widget.categoryId != null) 'category': widget.categoryId,
        'page': _currentPage,
        'page_size': 10,
      });

      if (mounted) {
        setState(() {
          _projects = result['projects'] ?? _getMockProjects();
          _hasMore = result['hasMore'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des projets: $e');
      if (mounted) {
        setState(() {
          _projects = _getMockProjects();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categoryProvider.categories;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreProjects();
    }
  }

  Future<void> _loadMoreProjects() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.getProjects({
        if (widget.categoryId != null) 'category': widget.categoryId,
        'page': _currentPage,
        'page_size': 10,
      });

      if (mounted) {
        setState(() {
          _projects.addAll(result['projects'] ?? []);
          _hasMore = result['hasMore'] ?? false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPage--;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshProjects() async {
    setState(() {
      _currentPage = 1;
      _projects.clear();
    });
    await _loadProjects();
  }

  void _performSearch(String query) {
    final searchQuery = query.trim();

    if (searchQuery.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            query: searchQuery,
            type: 'projects', // Recherche de projets
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un terme de recherche'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      currentIndex: 1, // Projets sélectionné
      appBar: AppBar(
        title: Text(l10n.availableProjects),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProjects,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Carte promotionnelle pour les projets
            // SliverToBoxAdapter(
            //   child: _buildProjectsPromoCard(),
            // ),

            // // Statistiques prestataire
            // SliverToBoxAdapter(
            //   child: _buildProviderStatsSection(),
            // ),

            // Barre de recherche
            SliverToBoxAdapter(
              child: _buildSearchSection(),
            ),

            // Liste des projets
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (_projects.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _projects.length) {
                        return _isLoadingMore
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ProjectCard(
                          project: _projects[index],
                          onTap: () =>
                              _navigateToProjectDetail(_projects[index]),
                              onFavoriteToggle: () => _toggleProjectFavorite(_projects[index]),
                          // onFavoriteToggle: (project) =>
                          //     _toggleProjectFavorite(project),
                        ),
                      );
                    },
                    childCount: _projects.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
            ],

            // Espacement en bas
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte promotionnelle pour les projets
  Widget _buildProjectsPromoCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5), // Violet
            Color(0xFF7C3AED), // Violet plus foncé
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.findBestProjects,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.growBusinessQualityClients,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Action pour explorer ou filtrer
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.explore,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section des statistiques prestataire
  Widget _buildProviderStatsSection() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingStats) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 120,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_providerStats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yourStatistics,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.completedServices,
                  '${_providerStats!['prestations_completed_this_month'] ?? 0}',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.inProgress,
                  '${_providerStats!['prestations_in_progress'] ?? 0}',
                  Colors.orange,
                  Icons.work,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.messages,
                  '${_providerStats!['unread_messages'] ?? 0}',
                  Colors.blue,
                  Icons.message,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.monthlyEarnings,
                  '${_providerStats!['total_earnings_this_month']?.toStringAsFixed(0) ?? 0}AOA',
                  Colors.purple,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.averageRating,
                  '${_providerStats!['avg_rating']?.toStringAsFixed(1) ?? 0}/5',
                  Colors.amber,
                  Icons.star,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.reviews,
                  '${_providerStats!['total_reviews'] ?? 0}',
                  Colors.teal,
                  Icons.rate_review,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Section de recherche
  Widget _buildSearchSection() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.searchProjects,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchProjectsPlaceholder,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4F46E5)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onSubmitted: _performSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.work_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noProjectsAvailable,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.comeBackLaterForNewProjects,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToProjectDetail(ClientProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(projectId: project.id),
      ),
    );
  }

  Future<void> _toggleProjectFavorite(ClientProject project) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.toggleProjectFavorite(project.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(project.isFavorited ?? false
                ? l10n.projectRemovedFromFavorites
                : l10n.projectAddedToFavorites),
          ),
        );

        _refreshProjects();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}$e')),
        );
      }
    }
  }

  // Données mock pour les tests
  List<ClientProject> _getMockProjects() {
    return [
      ClientProject(
        id: 1,
        title: 'Développement application mobile',
        description:
            'Création d\'une application mobile cross-platform pour service de livraison.',
        clientName: 'TechStart SARL',
        categoryName: 'Développement mobile',
        budgetRange: '5000_15000',
        budgetDisplay: '8000AOA - 12000AOA',
        location: 'Remote',
        remotePossible: true,
        urgency: 'medium',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: ['React Native', 'Node.js', 'MongoDB'],
        offersCount: 12,
        viewsCount: 78,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        timeSincePosted: 'Il y a 4 heures',
        isFavorited: false,
        hasUserOffered: false,
      ),
      ClientProject(
        id: 2,
        title: 'Site web e-commerce',
        description:
            'Création d\'un site e-commerce pour vente de produits artisanaux.',
        clientName: 'Artisan Shop',
        categoryName: 'Développement web',
        budgetRange: '2000_8000',
        budgetDisplay: '3000AOA - 6000AOA',
        location: 'Paris',
        remotePossible: true,
        urgency: 'low',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: ['PHP', 'Laravel', 'Vue.js'],
        offersCount: 8,
        viewsCount: 45,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        timeSincePosted: 'Il y a 12 heures',
        isFavorited: false,
        hasUserOffered: false,
      ),
    ];
  }
}
