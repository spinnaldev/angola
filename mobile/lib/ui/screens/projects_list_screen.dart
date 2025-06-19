// mobile/lib/ui/screens/projects_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/client_project.dart';
import '../../core/models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../widgets/project_card.dart';
import '../common/bottom_navigation.dart';
import './base_screen.dart';
import 'project_detail_screen.dart';
import 'post_project_screen.dart';

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

class _ProjectsListScreenState extends State<ProjectsListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<ClientProject> _projects = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  
  // Filtres
  Category? _selectedCategory;
  String _selectedBudget = '';
  String _selectedUrgency = '';
  bool _remoteOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialData() async {
    await _loadCategories();
    await _loadProjects(refresh: true);
  }

  Future<void> _loadCategories() async {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.fetchCategories();
      setState(() {
        _categories = categoryProvider.categories;
        if (widget.categoryId != null) {
          _selectedCategory = _categories.firstWhere(
            (cat) => cat.id == widget.categoryId,
            orElse: () => _categories.first,
          );
        }
      });
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
    }
  }

  Future<void> _loadProjects({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
        _projects.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Construire les paramètres de filtrage
      final filters = <String, dynamic>{
        'page': _currentPage,
        'page_size': 10,
      };
      
      if (_selectedCategory != null) {
        filters['category'] = _selectedCategory!.id;
      }
      if (_selectedBudget.isNotEmpty) {
        filters['budget_range'] = _selectedBudget;
      }
      if (_selectedUrgency.isNotEmpty) {
        filters['urgency'] = _selectedUrgency;
      }
      if (_remoteOnly) {
        filters['remote_only'] = true;
      }
      if (_searchQuery.isNotEmpty) {
        filters['search'] = _searchQuery;
      }
      
      final result = await apiService.getProjects(filters);
      
      setState(() {
        if (refresh) {
          _projects = result['projects'];
        } else {
          _projects.addAll(result['projects']);
        }
        _hasMore = result['hasMore'];
        _currentPage++;
      });
      
    } catch (e) {
      print('Erreur lors du chargement des projets: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des projets: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadProjects();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isProvider = user?.role == 'provider';

    return BaseScreen(
      currentIndex: 0,
      body: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            widget.categoryName ?? 'Projets disponibles',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            IconButton(
              onPressed: _showFilters,
              icon: const Icon(Icons.filter_list),
            ),
            if (!isProvider)
              IconButton(
                onPressed: () => _navigateToPostProject(context),
                icon: const Icon(Icons.add),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                _buildSearchBar(),
                // if (isProvider) _buildTabBar(),
              ],
            ),
          ),
        ),
        body: isProvider ? _buildProviderView() : _buildClientView(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher des projets...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onSubmitted: (value) {
          setState(() {
            _searchQuery = value;
          });
          _loadProjects(refresh: true);
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Tous les projets'),
        // Tab(text: 'Mes favoris'),
      ],
      labelColor: const Color(0xFF142FE2),
      unselectedLabelColor: Colors.grey,
      indicatorColor: const Color(0xFF142FE2),
    );
  }

  Widget _buildProviderView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProjectsList(),
        // _buildFavoriteProjects(),
      ],
    );
  }

  Widget _buildClientView() {
    return _buildProjectsList();
  }

  Widget _buildProjectsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_projects.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadProjects(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _projects.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ProjectCard(
              project: _projects[index],
              onTap: () => _navigateToProjectDetail(_projects[index]),
              onFavoriteToggle: (project) => _toggleFavorite(project),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteProjects() {
    // TODO: Implémenter la liste des projets favoris
    return const Center(
      child: Text('Projets favoris - À implémenter'),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun projet trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres de recherche',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142FE2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser les filtres'),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersModal(),
    );
  }

  Widget _buildFiltersModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterSection(
                        'Catégorie',
                        DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Toutes les catégories'),
                          items: [
                            const DropdownMenuItem<Category>(
                              value: null,
                              child: Text('Toutes les catégories'),
                            ),
                            ..._categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category.name),
                              );
                            }),
                          ],
                          onChanged: (Category? value) {
                            setModalState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFilterSection(
                        'Budget',
                        DropdownButtonFormField<String>(
                          value: _selectedBudget.isEmpty ? null : _selectedBudget,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Tous les budgets'),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Tous les budgets')),
                            DropdownMenuItem(value: 'moins_500', child: Text('Moins de 500 €')),
                            DropdownMenuItem(value: '500_1000', child: Text('500 à 1000 €')),
                            DropdownMenuItem(value: '1000_10000', child: Text('1000 à 10 000 €')),
                            DropdownMenuItem(value: '10000_plus', child: Text('10 000 € et plus')),
                            DropdownMenuItem(value: 'sur_devis', child: Text('Sur devis')),
                          ],
                          onChanged: (String? value) {
                            setModalState(() {
                              _selectedBudget = value ?? '';
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFilterSection(
                        'Urgence',
                        DropdownButtonFormField<String>(
                          value: _selectedUrgency.isEmpty ? null : _selectedUrgency,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Toutes les urgences'),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Toutes les urgences')),
                            DropdownMenuItem(value: 'low', child: Text('Pas urgent')),
                            DropdownMenuItem(value: 'medium', child: Text('Modérément urgent')),
                            DropdownMenuItem(value: 'high', child: Text('Urgent')),
                            DropdownMenuItem(value: 'very_high', child: Text('Très urgent')),
                          ],
                          onChanged: (String? value) {
                            setModalState(() {
                              _selectedUrgency = value ?? '';
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Télétravail uniquement'),
                        value: _remoteOnly,
                        onChanged: (bool? value) {
                          setModalState(() {
                            _remoteOnly = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Les variables sont déjà mises à jour via setModalState
                      });
                      Navigator.pop(context);
                      _loadProjects(refresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF142FE2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Appliquer les filtres'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedBudget = '';
      _selectedUrgency = '';
      _remoteOnly = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadProjects(refresh: true);
  }

  void _navigateToProjectDetail(ClientProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    ).then((result) {
      if (result == true) {
        _loadProjects(refresh: true);
      }
    });
  }

  void _navigateToPostProject(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostProjectScreen()),
    ).then((result) {
      if (result == true) {
        _loadProjects(refresh: true);
      }
    });
  }

  Future<void> _toggleFavorite(ClientProject project) async {
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
      
      _loadProjects(refresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  void dispose() {
    // _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}