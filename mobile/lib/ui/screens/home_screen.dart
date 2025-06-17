// mobile/lib/ui/screens/home_screen.dart - Version améliorée avec design original
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user.dart';
import '../../core/models/client_project.dart';
import '../../core/models/category.dart';
import '../../core/models/service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/services/api_service.dart';
import '../common/bottom_navigation.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<ClientProject> _recentProjects = [];
  List<Service> _recentServices = [];
  List<Category> _categories = [];
  bool _isLoadingProjects = false;
  bool _isLoadingServices = false;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadRecentProjects(),
      _loadRecentServices(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadRecentProjects() async {
    setState(() {
      _isLoadingProjects = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.getProjects({'page_size': 5});
      setState(() {
        _recentProjects = result['projects'] ?? [];
      });
    } catch (e) {
      print('Erreur lors du chargement des projets: $e');
      // En cas d'erreur (401 ou autre), utiliser des données mock
      setState(() {
        _recentProjects = _getMockProjects();
      });
    } finally {
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _loadRecentServices() async {
    setState(() {
      _isLoadingServices = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final services = await apiService.getRecentServices();
      setState(() {
        _recentServices = services;
      });
    } catch (e) {
      print('Erreur lors du chargement des services: $e');
      setState(() {
        _recentServices = _getMockServices();
      });
    } finally {
      setState(() {
        _isLoadingServices = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.fetchCategories();
      setState(() {
        _categories = categoryProvider.categories;
      });
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
      setState(() {
        _categories = Category.getDefaultCategories();
      });
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
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
          child: CustomScrollView(
            slivers: [
              _buildCustomAppBar(),
              SliverToBoxAdapter(child: _buildSearchBar()),
              // SliverToBoxAdapter(child: _buildTabBar()),
              SliverToBoxAdapter(child: _buildMainCard()),
              SliverToBoxAdapter(child: _buildContentSection()),
              SliverToBoxAdapter(child: _buildCategoriesSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          child: Row(
            children: [
              // Logo TeyGO
              Image.asset(
                'assets/images/logo.png',
                height: 40,
                width: 80,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'LOGO',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Actions de droite
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un service...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onSubmitted: (value) {
          _performSearch(value);
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF142FE2),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF142FE2),
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          // Tab(text: 'Accueil'),
          // Tab(text: 'Meilleurs'),
          // Tab(text: 'Récents'),
          // Tab(text: 'Proximité'),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [const Color(0xFF142FE2), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getMainCardTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getMainCardSubtitle(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getMainCardAction(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF142FE2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_getMainCardButtonText()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMainCardTitle() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) {
      return 'Découvrez TeyGO';
    }
    return user.role == 'client' 
        ? 'Trouvez les meilleurs prestataires'
        : 'Découvrez les nouveaux projets';
  }

  String _getMainCardSubtitle() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) {
      return 'La plateforme qui connecte clients et prestataires de services';
    }
    return user.role == 'client'
        ? 'Réservez facilement des services de qualité'
        : 'Trouvez des missions adaptées à vos compétences';
  }

  String _getMainCardButtonText() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) {
      return 'Explorer';
    }
    return user.role == 'client' ? 'Explorer' : 'Voir les projets';
  }

  VoidCallback _getMainCardAction() {
    return () {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null || user.role == 'client') {
        Navigator.pushNamed(context, '/explore');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProjectsListScreen()),
        );
      }
    };
  }

  Widget _buildContentSection() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    
    if (user?.role == 'client') {
      return _buildServicesSection();
      
    } else {
      return _buildProjectsSection();
    }
  }

  Widget _buildProjectsSection() {
    return Padding(
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
                child: const Text(
                  'Voir tout',
                  style: TextStyle(color: const Color(0xFF142FE2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingProjects) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_recentProjects.isEmpty) ...[
            _buildEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Aucun projet disponible',
              subtitle: 'Les nouveaux projets apparaîtront ici',
              buttonText: 'Explorer tous les projets',
              onButtonPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProjectsListScreen()),
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentProjects.length.clamp(0, 3),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProjectCard(
                    project: _recentProjects[index],
                    onTap: () => _navigateToProjectDetail(_recentProjects[index]),
                    onFavoriteToggle: (project) => _toggleProjectFavorite(project),
                  ),
                );
              },
            ),
          ],
        ],
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
          // const SizedBox(height: 24),
          // const Text(
          //   'Annonces récentes',
          //   style: TextStyle(
          //     fontSize: 18,
          //     fontWeight: FontWeight.bold,
          //     color: Colors.black87,
          //   ),
          // ),
          // const SizedBox(height: 16),
          // _buildEmptyState(
          //   icon: Icons.campaign_outlined,
          //   title: 'Aucune annonce récente',
          //   subtitle: 'Les nouvelles annonces apparaîtront ici',
          //   buttonText: 'Voir toutes les annonces',
          //   onButtonPressed: () => Navigator.pushNamed(context, '/explore'),
          // ),
        ],
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
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
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

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explorer par catégorie',
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
            const Text('Aucune catégorie disponible'),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCategory(category),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF142FE2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category.icon),
                  color: const Color(0xFF142FE2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.role == 'client') {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PostProjectScreen()),
        ),
        backgroundColor: const Color(0xFF142FE2),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau projet'),
      );
    }
    return null;
  }

  // Méthodes utilitaires
  IconData _getCategoryIcon(String? iconName) {
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

  // Méthodes de navigation
  void _navigateToProjectDetail(ClientProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }

  void _navigateToServiceDetail(Service service) {
    // Navigation vers le détail du service (à implémenter)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Détail du service - À implémenter')),
    );
  }

  void _navigateToCategory(Category category) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
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
      // Navigation vers les services de cette catégorie - rediriger vers Explorer
      Navigator.pushNamed(context, '/explore');
    }
  }

  // Actions
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.role == 'provider') {
      // Rechercher des projets
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProjectsListScreen(),
        ),
      );
    } else {
      // Rechercher des services - rediriger vers l'onglet Explorer
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
      
      _loadRecentProjects();
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
        requiredSkills: [],
        offersCount: 12,
        viewsCount: 45,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        timeSincePosted: 'Il y a 6 heures',
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
    // _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}