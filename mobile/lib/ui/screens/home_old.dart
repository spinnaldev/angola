
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user.dart';
import '../../core/models/client_project.dart';
import '../../core/models/category.dart';
import '../../core/models/service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/services/api_service.dart';
import '../widgets/project_card.dart';
import '../widgets/service_card.dart';
import './base_screen.dart';
import 'projects_list_screen.dart';
import 'project_detail_screen.dart';
import 'post_project_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<ClientProject> _recentProjects = [];
  List<Service> _recentServices = [];
  List<Category> _categories = [];
  bool _isLoadingProjects = false;
  bool _isLoadingServices = false;
  bool _isLoadingCategories = false;
  bool _isLoadingStats = false;
  
  // Statistiques prestataire
  Map<String, dynamic>? _providerStats;
  List<ClientProject> _nearbyProjects = [];
  List<ClientProject> _specialtyProjects = [];
  List<ClientProject> _highBudgetProjects = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user?.role == 'provider') {
      await Future.wait([
        _loadProviderStats(),
        _loadNearbyProjects(),
        _loadSpecialtyProjects(),
        _loadHighBudgetProjects(),
        _loadCategories(),
      ]);
    } else {
      // Pour les clients ou utilisateurs non connectés
      await Future.wait([
        _loadRecentProjects(),
        _loadRecentServices(),
        _loadCategories(),
      ]);
    }
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

  Future<void> _loadNearbyProjects() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.getProjects({
        'nearby': true,
        'page_size': 5,
      });
      if (mounted) {
        setState(() {
          _nearbyProjects = result['projects'] ?? [];
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des projets proches: $e');
      if (mounted) {
        setState(() {
          _nearbyProjects = _getMockNearbyProjects();
        });
      }
    }
  }

  Future<void> _loadSpecialtyProjects() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.getProjects({
        'matching_specialty': true,
        'page_size': 5,
      });
      if (mounted) {
        setState(() {
          _specialtyProjects = result['projects'] ?? [];
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des projets spécialisés: $e');
      if (mounted) {
        setState(() {
          _specialtyProjects = _getMockSpecialtyProjects();
        });
      }
    }
  }

  Future<void> _loadHighBudgetProjects() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.getProjects({
        'high_budget': true,
        'page_size': 5,
      });
      if (mounted) {
        setState(() {
          _highBudgetProjects = result['projects'] ?? [];
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des projets bien rémunérés: $e');
      if (mounted) {
        setState(() {
          _highBudgetProjects = _getMockHighBudgetProjects();
        });
      }
    }
  }

  Future<void> _loadRecentProjects() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProjects = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.getProjects({'page_size': 5});
      if (mounted) {
        setState(() {
          _recentProjects = result['projects'] ?? [];
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des projets: $e');
      if (mounted) {
        setState(() {
          _recentProjects = _getMockProjects();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProjects = false;
        });
      }
    }
  }

  Future<void> _loadRecentServices() async {
    if (!mounted) return;
    setState(() {
      _isLoadingServices = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final services = await apiService.getRecentServices();
      if (mounted) {
        setState(() {
          _recentServices = services;
        });
      }
    } catch (e) {
      print('Error in getRecentServices: $e');
      if (mounted) {
        setState(() {
          _recentServices = _getMockServices();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categoryProvider.categories;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
      if (mounted) {
        setState(() {
          _categories = Category.getDefaultCategories();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      currentIndex: 0,
      body: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              
              // Si pas connecté, afficher la version client
              if (user?.role == 'provider') {
                return _buildProviderHome(user);
              } else {
                return _buildClientHome(user);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProviderHome(User? user) {
    return CustomScrollView(
      slivers: [
        _buildOriginalHeader(),
        SliverToBoxAdapter(child: _buildProviderStats()),
        SliverToBoxAdapter(child: _buildSearchBar()),
        SliverToBoxAdapter(child: _buildProviderProjectsSection()),
        SliverToBoxAdapter(child: _buildCategoriesSection()),
      ],
    );
  }

  Widget _buildClientHome(User? user) {
    return CustomScrollView(
      slivers: [
        _buildOriginalHeader(),
        SliverToBoxAdapter(child: _buildSearchBar()),
        SliverToBoxAdapter(child: _buildProjectsSection()),
        SliverToBoxAdapter(child: _buildServicesSection()),
        SliverToBoxAdapter(child: _buildCategoriesSection()),
      ],
    );
  }

  Widget _buildOriginalHeader() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          child: Row(
            children: [
              // Logo original
              Image.asset(
                'assets/images/logo.png',
                height: 40,
                width: 80,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 40,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF142FE2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'ANGOLA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Actions de droite originales
              Row(
                children: [
                  _buildHeaderIcon(Icons.location_on, () {
                    // Action localisation
                  }),
                  const SizedBox(width: 12),
                  _buildHeaderIcon(Icons.notifications_outlined, () {
                    // Action notifications
                  }),
                  const SizedBox(width: 12),
                  _buildHeaderIcon(Icons.person_outline, () {
                    Navigator.pushNamed(context, '/profile');
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProviderStats() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_providerStats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142FE2), Color.fromARGB(255, 58, 80, 221)],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques d\'activité',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Prestations ce mois',
                  '${_providerStats!['prestations_completed_this_month'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'En cours',
                  '${_providerStats!['prestations_in_progress'] ?? 0}',
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Messages non lus',
                  '${_providerStats!['unread_messages'] ?? 0}',
                  Icons.mail,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Note moyenne',
                  '${_providerStats!['avg_rating']?.toStringAsFixed(1) ?? '0.0'}',
                  Icons.star,
                  Colors.yellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
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
        ],
      ),
    );
  }

  Widget _buildProviderProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Demandes clients',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildProjectFilter('Projets proches', _nearbyProjects, Icons.location_on),
        _buildProjectFilter('Ma spécialité', _specialtyProjects, Icons.work),
        _buildProjectFilter('Bien rémunérés', _highBudgetProjects, Icons.attach_money),
      ],
    );
  }

  // ✅ CORRECTION : Affichage en liste verticale pour prestataires
  Widget _buildProjectFilter(String title, List<ClientProject> projects, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF142FE2), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProjectsListScreen(),
                    ),
                  ),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (projects.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Text(
                    'Aucun projet pour le moment',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            // ✅ AFFICHAGE EN LISTE VERTICALE comme pour les clients
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projects.length.clamp(0, 3), // Limiter à 3 projets
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProjectCard(
                      project: projects[index],
                      onTap: () => _navigateToProjectDetail(projects[index]),
                      onFavoriteToggle: (project) => _toggleProjectFavorite(project),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildProjectsSection() {
    return Container(
      // AJOUT : Container avec background blanc
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Projets récents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProjectsListScreen()),
                  ),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingProjects) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_recentProjects.isEmpty) ...[
              _buildEmptyState(
                icon: Icons.work_outline,
                title: 'Aucun projet disponible',
                subtitle: 'Les nouveaux projets apparaîtront ici',
                buttonText: 'Explorer tous les projets',
                onButtonPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProjectsListScreen()),
                ),
              ),
            ] else ...[
              // Container blanc pour la liste des projets
              Container(
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentProjects.length.clamp(0, 3),
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ProjectCard(
                        project: _recentProjects[index],
                        onTap: () => _navigateToProjectDetail(_recentProjects[index]),
                        onFavoriteToggle: (project) => _toggleProjectFavorite(project),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meilleures prestations de la semaine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingServices) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_recentServices.isEmpty) ...[
            _buildEmptyState(
              icon: Icons.work_outline,
              title: 'Aucune prestation populaire pour le moment',
              subtitle: 'Les meilleures prestations apparaîtront ici',
              buttonText: 'Explorer les services',
              onButtonPressed: () => Navigator.pushNamed(context, '/explore'),
            ),
          ] else ...[
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recentServices.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  return Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 16),
                    child: ServiceCard(
                      service: _recentServices[index],
                      onTap: () => _navigateToServiceDetail(_recentServices[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catégories populaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingCategories) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_categories.isEmpty) ...[
            _buildEmptyState(
              icon: Icons.category_outlined,
              title: 'Aucune catégorie disponible',
              subtitle: 'Les catégories apparaîtront ici',
              buttonText: 'Actualiser',
              onButtonPressed: _loadCategories,
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _categories.length.clamp(0, 6),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(category);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () => _navigateToCategory(category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category.icon ?? ''),
              size: 32,
              color: const Color(0xFF142FE2),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onButtonPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142FE2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'construction':
        return Icons.construction;
      case 'design':
        return Icons.palette;
      case 'technology':
        return Icons.computer;
      case 'beauty':
        return Icons.spa;
      case 'transport':
        return Icons.local_shipping;
      case 'health':
        return Icons.health_and_safety;
      default:
        return Icons.work_outline;
    }
  }

  void _navigateToProjectDetail(ClientProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }

  void _navigateToServiceDetail(Service service) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Détail du service - À implémenter')),
    );
  }

  void _navigateToCategory(Category category) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user?.role == 'provider') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectsListScreen(
            categoryId: category.id,
            categoryName: category.name,
          ),
        ),
      );
    } else {
      Navigator.pushNamed(context, '/explore');
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user?.role == 'provider') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProjectsListScreen(),
        ),
      );
    } else {
      Navigator.pushNamed(context, '/explore');
    }
  }

  Future<void> _toggleProjectFavorite(ClientProject project) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.toggleProjectFavorite(project.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            project.isFavorited ?? false 
                ? 'Projet retiré des favoris' 
                : 'Projet ajouté aux favoris'
          ),
        ),
      );
      
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  // Données mock pour les cas d'erreur
  List<ClientProject> _getMockProjects() {
    return [
      ClientProject(
        id: 1,
        title: 'Création d\'un site web e-commerce',
        description: 'Recherche développeur pour créer un site e-commerce complet.',
        clientName: 'Client anonyme',
        categoryName: 'Développement web',
        budgetRange: '1000_10000',
        budgetDisplay: '3000€ - 8000€',
        location: 'Paris',
        remotePossible: true,
        urgency: 'medium',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: ['React', 'Node.js', 'MongoDB'],
        offersCount: 12,
        viewsCount: 45,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        timeSincePosted: 'Il y a 6 heures',
        isFavorited: false,
        hasUserOffered: false,
      ),
    ];
  }

  List<ClientProject> _getMockNearbyProjects() {
    return [
      ClientProject(
        id: 2,
        title: 'Réparation plomberie urgente',
        description: 'Fuite d\'eau dans la cuisine, intervention rapide souhaitée.',
        clientName: 'Marie L.',
        categoryName: 'Plomberie',
        budgetRange: '100_500',
        budgetDisplay: '150€ - 300€',
        location: 'Cotonou, Littoral',
        remotePossible: false,
        urgency: 'high',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: ['Plomberie'],
        offersCount: 3,
        viewsCount: 15,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        timeSincePosted: 'Il y a 2 heures',
        isFavorited: false,
        hasUserOffered: false,
      ),
    ];
  }

  List<ClientProject> _getMockSpecialtyProjects() {
    return [
      ClientProject(
        id: 3,
        title: 'Application mobile React Native',
        description: 'Développement d\'une application de livraison pour Android et iOS.',
        clientName: 'StartupTech',
        categoryName: 'Développement mobile',
        budgetRange: '5000_20000',
        budgetDisplay: '8000€ - 15000€',
        location: 'Remote',
        remotePossible: true,
        urgency: 'medium',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: ['React Native', 'JavaScript', 'API REST'],
        offersCount: 8,
        viewsCount: 32,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        timeSincePosted: 'Il y a 8 heures',
        isFavorited: false,
        hasUserOffered: false,
      ),
    ];
  }

  List<ClientProject> _getMockHighBudgetProjects() {
    return [
      ClientProject(
        id: 4,
        title: 'Refonte complète site corporate',
        description: 'Refonte complète du site web d\'une grande entreprise avec CMS personnalisé.',
        clientName: 'Enterprise Corp',
        categoryName: 'Développement web',
        budgetRange: '20000_50000',
        budgetDisplay: '25000€ - 40000€',
        location: 'Paris',
        remotePossible: true,
        urgency: 'low',
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: ['PHP', 'Laravel', 'Vue.js', 'MySQL'],
        offersCount: 15,
        viewsCount: 67,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        timeSincePosted: 'Il y a 1 jour',
        isFavorited: false,
        hasUserOffered: false,
      ),
    ];
  }

  List<Service> _getMockServices() {
    return [
      Service(
        id: 1,
        title: 'Développement site web',
        description: 'Création de sites web modernes et responsives.',
        imageUrl: '',
        rating: 4.8,
        reviewCount: 25,
        provider_id: 1,
        businessType: 'Freelance',
        price: 1500.0,
        priceType: 'fixed',
        subcategoryId: 1,
        categoryId: 1,
        isAvailable: true,
        galleryImages: [],
        options: [],
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}