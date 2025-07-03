
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../core/models/user.dart';
// import '../../core/models/client_project.dart';
// import '../../core/models/category.dart';
// import '../../core/models/service.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/category_provider.dart';
// import '../../core/services/api_service.dart';
// import '../widgets/project_card.dart';
// import '../widgets/service_card.dart';
// import './base_screen.dart';
// import 'projects_list_screen.dart';
// import 'project_detail_screen.dart';
// import 'post_project_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final TextEditingController _searchController = TextEditingController();
  
//   List<ClientProject> _recentProjects = [];
//   List<Service> _recentServices = [];
//   List<Category> _categories = [];
//   bool _isLoadingProjects = false;
//   bool _isLoadingServices = false;
//   bool _isLoadingCategories = false;
//   bool _isLoadingStats = false;
  
//   // Statistiques prestataire
//   Map<String, dynamic>? _providerStats;
//   List<ClientProject> _nearbyProjects = [];
//   List<ClientProject> _specialtyProjects = [];
//   List<ClientProject> _highBudgetProjects = [];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadData();
//     });
//   }

//   Future<void> _loadData() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final user = authProvider.currentUser;

//     if (user?.role == 'provider') {
//       await Future.wait([
//         _loadProviderStats(),
//         _loadNearbyProjects(),
//         _loadSpecialtyProjects(),
//         _loadHighBudgetProjects(),
//         _loadCategories(),
//       ]);
//     } else {
//       // Pour les clients ou utilisateurs non connectés
//       await Future.wait([
//         _loadRecentProjects(),
//         _loadRecentServices(),
//         _loadCategories(),
//       ]);
//     }
//   }

//   Future<void> _loadProviderStats() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoadingStats = true;
//     });

//     try {
//       final apiService = Provider.of<ApiService>(context, listen: false);
//       final stats = await apiService.getProviderStats();
//       if (mounted) {
//         setState(() {
//           _providerStats = stats;
//         });
//       }
//     } catch (e) {
//       print('Erreur lors du chargement des statistiques: $e');
//       // Statistiques mock en cas d'erreur
//       if (mounted) {
//         setState(() {
//           _providerStats = {
//             'prestations_completed_this_month': 8,
//             'prestations_in_progress': 3,
//             'unread_messages': 5,
//             'total_earnings_this_month': 2400.0,
//             'avg_rating': 4.7,
//             'total_reviews': 24,
//           };
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingStats = false;
//         });
//       }
//     }
//   }

//   Future<void> _loadNearbyProjects() async {
//     try {
//       final apiService = Provider.of<ApiService>(context, listen: false);
//       final result = await apiService.getProjects({
//         'nearby': true,
//         'page_size': 5,
//       });
//       if (mounted) {
//         setState(() {
//           _nearbyProjects = result['projects'] ?? [];
//         });
//       }
//     } catch (e) {
//       print('Erreur lors du chargement des projets proches: $e');
//       if (mounted) {
//         setState(() {
//           _nearbyProjects = _getMockNearbyProjects();
//         });
//       }
//     }
//   }

//   Future<void> _loadSpecialtyProjects() async {
//     try {
//       final apiService = Provider.of<ApiService>(context, listen: false);
//       final result = await apiService.getProjects({
//         'matching_specialty': true,
//         'page_size': 5,
//       });
//       if (mounted) {
//         setState(() {
//           _specialtyProjects = result['projects'] ?? [];
//         });
//       }
//     } catch (e) {
//       print('Erreur lors du chargement des projets spécialisés: $e');
//       if (mounted) {
//         setState(() {
//           _specialtyProjects = _getMockSpecialtyProjects();
//         });
//       }
//     }
//   }

//   Future<void> _loadHighBudgetProjects() async {
//     try {
//       final apiService = Provider.of<ApiService>(context, listen: false);
//       final result = await apiService.getProjects({
//         'high_budget': true,
//         'page_size': 5,
//       });
//       if (mounted) {
//         setState(() {
//           _highBudgetProjects = result['projects'] ?? [];
//         });
//       }
//     } catch (e) {
//       print('Erreur lors du chargement des projets bien rémunérés: $e');
//       if (mounted) {
//         setState(() {
//           _highBudgetProjects = _getMockHighBudgetProjects();
//         });
//       }
//     }
//   }

//   Future<void> _loadRecentProjects() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoadingProjects = true;
//     });

//     try {
//       final apiService = Provider.of<ApiService>(context, listen: false);
//       final result = await apiService.getProjects({'page_size': 5});
//       if (mounted) {
//         setState(() {
//           _recentProjects = result['projects'] ?? [];
//         });
//       }
//     } catch (e) {
//       print('Erreur lors du chargement des projets: $e');
//       if (mounted) {
//         setState(() {
//           _recentProjects = _getMockProjects();
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingProjects = false;
//         });
//       }
//     }
//   }

//   Future<void> _loadRecentServices() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoadingServices = true;
//     });

//     try {
//       final apiService = Provider.of<ApiService>(context, listen: false);
//       final services = await apiService.getRecentServices();
//       if (mounted) {
//         setState(() {
//           _recentServices = services;
//         });
//       }
//     } catch (e) {
//       print('Error in getRecentServices: $e');
//       if (mounted) {
//         setState(() {
//           _recentServices = _getMockServices();
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingServices = false;
//         });
//       }
//     }
//   }

//   Future<void> _loadCategories() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoadingCategories = true;
//     });

//     try {
//       final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
//       await categoryProvider.fetchCategories();
//       if (mounted) {
//         setState(() {
//           _categories = categoryProvider.categories;
//         });
//       }
//     } catch (e) {
//       print('Erreur lors du chargement des catégories: $e');
//       if (mounted) {
//         setState(() {
//           _categories = Category.getDefaultCategories();
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingCategories = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BaseScreen(
//       currentIndex: 0,
//       body: Scaffold(
//         backgroundColor: Colors.white,
//         body: RefreshIndicator(
//           onRefresh: _loadData,
//           child: Consumer<AuthProvider>(
//             builder: (context, authProvider, child) {
//               final user = authProvider.currentUser;
              
//               // Si pas connecté, afficher la version client
//               if (user?.role == 'provider') {
//                 return _buildProviderHome(user);
//               } else {
//                 return _buildClientHome(user);
//               }
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildProviderHome(User? user) {
//     return CustomScrollView(
//       slivers: [
//         _buildOriginalHeader(),
//         SliverToBoxAdapter(child: _buildProviderStats()),
//         SliverToBoxAdapter(child: _buildSearchBar()),
//         SliverToBoxAdapter(child: _buildProviderProjectsSection()),
//         SliverToBoxAdapter(child: _buildCategoriesSection()),
//       ],
//     );
//   }

//   Widget _buildClientHome(User? user) {
//     return CustomScrollView(
//       slivers: [
//         _buildOriginalHeader(),
//         SliverToBoxAdapter(child: _buildSearchBar()),
//         SliverToBoxAdapter(child: _buildProjectsSection()),
//         SliverToBoxAdapter(child: _buildServicesSection()),
//         SliverToBoxAdapter(child: _buildCategoriesSection()),
//       ],
//     );
//   }

//   Widget _buildOriginalHeader() {
//     return SliverAppBar(
//       expandedHeight: 100,
//       floating: false,
//       pinned: true,
//       backgroundColor: Colors.white,
//       elevation: 0,
//       flexibleSpace: FlexibleSpaceBar(
//         background: Container(
//           padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
//           child: Row(
//             children: [
//               // Logo original
//               Image.asset(
//                 'assets/images/logo.png',
//                 height: 40,
//                 width: 80,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 40,
//                   width: 80,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF142FE2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Center(
//                     child: Text(
//                       'ANGOLA',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               // Actions de droite originales
//               Row(
//                 children: [
//                   _buildHeaderIcon(Icons.location_on, () {
//                     // Action localisation
//                   }),
//                   const SizedBox(width: 12),
//                   _buildHeaderIcon(Icons.notifications_outlined, () {
//                     // Action notifications
//                   }),
//                   const SizedBox(width: 12),
//                   _buildHeaderIcon(Icons.person_outline, () {
//                     Navigator.pushNamed(context, '/profile');
//                   }),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: Colors.grey[100],
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(
//           icon,
//           size: 20,
//           color: Colors.black87,
//         ),
//       ),
//     );
//   }

//   Widget _buildProviderStats() {
//     if (_isLoadingStats) {
//       return Container(
//         padding: const EdgeInsets.all(16),
//         child: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_providerStats == null) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF142FE2), Color.fromARGB(255, 58, 80, 221)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF142FE2).withOpacity(0.3),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Statistiques d\'activité',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildStatCard(
//                   'Prestations ce mois',
//                   '${_providerStats!['prestations_completed_this_month'] ?? 0}',
//                   Icons.check_circle,
//                   Colors.green,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildStatCard(
//                   'En cours',
//                   '${_providerStats!['prestations_in_progress'] ?? 0}',
//                   Icons.hourglass_empty,
//                   Colors.orange,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildStatCard(
//                   'Messages non lus',
//                   '${_providerStats!['unread_messages'] ?? 0}',
//                   Icons.mail,
//                   Colors.red,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildStatCard(
//                   'Note moyenne',
//                   '${_providerStats!['avg_rating']?.toStringAsFixed(1) ?? '0.0'}',
//                   Icons.star,
//                   Colors.yellow,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color, size: 20),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProviderProjectsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Padding(
//           padding: EdgeInsets.symmetric(horizontal: 16),
//           child: Text(
//             'Demandes clients',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         _buildProjectFilter('Projets proches', _nearbyProjects, Icons.location_on),
//         _buildProjectFilter('Ma spécialité', _specialtyProjects, Icons.work),
//         _buildProjectFilter('Bien rémunérés', _highBudgetProjects, Icons.attach_money),
//       ],
//     );
//   }

//   // ✅ CORRECTION : Affichage en liste verticale pour prestataires
//   Widget _buildProjectFilter(String title, List<ClientProject> projects, IconData icon) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 Icon(icon, color: const Color(0xFF142FE2), size: 20),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const Spacer(),
//                 TextButton(
//                   onPressed: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const ProjectsListScreen(),
//                     ),
//                   ),
//                   child: const Text('Voir tout'),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
//           if (projects.isEmpty)
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 16),
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.info_outline, color: Colors.grey[400]),
//                   const SizedBox(width: 12),
//                   Text(
//                     'Aucun projet pour le moment',
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           else
//             // ✅ AFFICHAGE EN LISTE VERTICALE comme pour les clients
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: projects.length.clamp(0, 3), // Limiter à 3 projets
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 12),
//                     child: ProjectCard(
//                       project: projects[index],
//                       onTap: () => _navigateToProjectDetail(projects[index]),
//                       onFavoriteToggle: (project) => _toggleProjectFavorite(project),
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           hintText: 'Rechercher...',
//           prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
//           filled: true,
//           fillColor: Colors.grey[100],
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         ),
//         onSubmitted: _performSearch,
//       ),
//     );
//   }

//   Widget _buildProjectsSection() {
//     return Container(
//       // AJOUT : Container avec background blanc
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Projets récents',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const ProjectsListScreen()),
//                   ),
//                   child: const Text('Voir tout'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             if (_isLoadingProjects) ...[
//               const Center(child: CircularProgressIndicator()),
//             ] else if (_recentProjects.isEmpty) ...[
//               _buildEmptyState(
//                 icon: Icons.work_outline,
//                 title: 'Aucun projet disponible',
//                 subtitle: 'Les nouveaux projets apparaîtront ici',
//                 buttonText: 'Explorer tous les projets',
//                 onButtonPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const ProjectsListScreen()),
//                 ),
//               ),
//             ] else ...[
//               // Container blanc pour la liste des projets
//               Container(
//                 color: Colors.white,
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: _recentProjects.length.clamp(0, 3),
//                   itemBuilder: (context, index) {
//                     return Container(
//                       margin: const EdgeInsets.only(bottom: 12),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.grey.withOpacity(0.1),
//                             spreadRadius: 1,
//                             blurRadius: 3,
//                             offset: const Offset(0, 1),
//                           ),
//                         ],
//                       ),
//                       child: ProjectCard(
//                         project: _recentProjects[index],
//                         onTap: () => _navigateToProjectDetail(_recentProjects[index]),
//                         onFavoriteToggle: (project) => _toggleProjectFavorite(project),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildServicesSection() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Meilleures prestations de la semaine',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 16),
//           if (_isLoadingServices) ...[
//             const Center(child: CircularProgressIndicator()),
//           ] else if (_recentServices.isEmpty) ...[
//             _buildEmptyState(
//               icon: Icons.work_outline,
//               title: 'Aucune prestation populaire pour le moment',
//               subtitle: 'Les meilleures prestations apparaîtront ici',
//               buttonText: 'Explorer les services',
//               onButtonPressed: () => Navigator.pushNamed(context, '/explore'),
//             ),
//           ] else ...[
//             SizedBox(
//               height: 280,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: _recentServices.length.clamp(0, 5),
//                 itemBuilder: (context, index) {
//                   return Container(
//                     width: 250,
//                     margin: const EdgeInsets.only(right: 16),
//                     child: ServiceCard(
//                       service: _recentServices[index],
//                       onTap: () => _navigateToServiceDetail(_recentServices[index]),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildCategoriesSection() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Catégories populaires',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 16),
//           if (_isLoadingCategories) ...[
//             const Center(child: CircularProgressIndicator()),
//           ] else if (_categories.isEmpty) ...[
//             _buildEmptyState(
//               icon: Icons.category_outlined,
//               title: 'Aucune catégorie disponible',
//               subtitle: 'Les catégories apparaîtront ici',
//               buttonText: 'Actualiser',
//               onButtonPressed: _loadCategories,
//             ),
//           ] else ...[
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 childAspectRatio: 1.5,
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//               ),
//               itemCount: _categories.length.clamp(0, 6),
//               itemBuilder: (context, index) {
//                 final category = _categories[index];
//                 return _buildCategoryCard(category);
//               },
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildCategoryCard(Category category) {
//     return GestureDetector(
//       onTap: () => _navigateToCategory(category),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _getCategoryIcon(category.icon ?? ''),
//               size: 32,
//               color: const Color(0xFF142FE2),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               category.name,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required String buttonText,
//     required VoidCallback onButtonPressed,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Column(
//         children: [
//           Icon(
//             icon,
//             size: 48,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[600],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             subtitle,
//             style: TextStyle(
//               color: Colors.grey[500],
//               fontSize: 14,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: onButtonPressed,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF142FE2),
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Text(buttonText),
//           ),
//         ],
//       ),
//     );
//   }

//   IconData _getCategoryIcon(String iconName) {
//     switch (iconName) {
//       case 'construction':
//         return Icons.construction;
//       case 'design':
//         return Icons.palette;
//       case 'technology':
//         return Icons.computer;
//       case 'beauty':
//         return Icons.spa;
//       case 'transport':
//         return Icons.local_shipping;
//       case 'health':
//         return Icons.health_and_safety;
//       default:
//         return Icons.work_outline;
//     }
//   }

//   void _navigateToProjectDetail(ClientProject project) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ProjectDetailScreen(project: project),
//       ),
//     );
//   }

//   void _navigateToServiceDetail(Service service) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Détail du service - À implémenter')),
//     );
//   }

//   void _navigateToCategory(Category category) {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final user = authProvider.currentUser;
    
//     if (user?.role == 'provider') {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ProjectsListScreen(
//             categoryId: category.id,
//             categoryName: category.name,
//           ),
//         ),
//       );
//     } else {
//       Navigator.pushNamed(context, '/explore');
//     }
//   }

//   void _performSearch(String query) {
//     if (query.trim().isEmpty) return;
    
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final user = authProvider.currentUser;
    
//     if (user?.role == 'provider') {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => const ProjectsListScreen(),
//         ),
//       );
//     } else {
//       Navigator.pushNamed(context, '/explore');
//     }
//   }

//   Future<void> _toggleProjectFavorite(ClientProject project) async {
//     try {
//       final apiService = Provider.of<ApiService>(context, listen: false);
//       await apiService.toggleProjectFavorite(project.id);
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             project.isFavorited ?? false 
//                 ? 'Projet retiré des favoris' 
//                 : 'Projet ajouté aux favoris'
//           ),
//         ),
//       );
      
//       _loadData();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur: $e')),
//       );
//     }
//   }

//   // Données mock pour les cas d'erreur
//   List<ClientProject> _getMockProjects() {
//     return [
//       ClientProject(
//         id: 1,
//         title: 'Création d\'un site web e-commerce',
//         description: 'Recherche développeur pour créer un site e-commerce complet.',
//         clientName: 'Client anonyme',
//         categoryName: 'Développement web',
//         budgetRange: '1000_10000',
//         budgetDisplay: '3000€ - 8000€',
//         location: 'Paris',
//         remotePossible: true,
//         urgency: 'medium',
//         status: 'open',
//         contactViaPlatform: true,
//         showEmail: false,
//         showPhone: false,
//         requiredSkills: ['React', 'Node.js', 'MongoDB'],
//         offersCount: 12,
//         viewsCount: 45,
//         createdAt: DateTime.now().subtract(const Duration(hours: 6)),
//         timeSincePosted: 'Il y a 6 heures',
//         isFavorited: false,
//         hasUserOffered: false,
//       ),
//     ];
//   }

//   List<ClientProject> _getMockNearbyProjects() {
//     return [
//       ClientProject(
//         id: 2,
//         title: 'Réparation plomberie urgente',
//         description: 'Fuite d\'eau dans la cuisine, intervention rapide souhaitée.',
//         clientName: 'Marie L.',
//         categoryName: 'Plomberie',
//         budgetRange: '100_500',
//         budgetDisplay: '150€ - 300€',
//         location: 'Cotonou, Littoral',
//         remotePossible: false,
//         urgency: 'high',
//         status: 'open',
//         contactViaPlatform: true,
//         showEmail: false,
//         showPhone: false,
//         requiredSkills: ['  '],
//         offersCount: 3,
//         viewsCount: 15,
//         createdAt: DateTime.now().subtract(const Duration(hours: 2)),
//         timeSincePosted: 'Il y a 2 heures',
//         isFavorited: false,
//         hasUserOffered: false,
//       ),
//     ];
//   }

//   List<ClientProject> _getMockSpecialtyProjects() {
//     return [
//       ClientProject(
//         id: 3,
//         title: 'Application mobile React Native',
//         description: 'Développement d\'une application de livraison pour Android et iOS.',
//         clientName: 'StartupTech',
//         categoryName: 'Développement mobile',
//         budgetRange: '5000_20000',
//         budgetDisplay: '8000€ - 15000€',
//         location: 'Remote',
//         remotePossible: true,
//         urgency: 'medium',
//         status: 'open',
//         contactViaPlatform: true,
//         showEmail: false,
//         showPhone: false,
//         requiredSkills: ['React Native', 'JavaScript', 'API REST'],
//         offersCount: 8,
//         viewsCount: 32,
//         createdAt: DateTime.now().subtract(const Duration(hours: 8)),
//         timeSincePosted: 'Il y a 8 heures',
//         isFavorited: false,
//         hasUserOffered: false,
//       ),
//     ];
//   }

//   List<ClientProject> _getMockHighBudgetProjects() {
//     return [
//       ClientProject(
//         id: 4,
//         title: 'Refonte complète site corporate',
//         description: 'Refonte complète du site web d\'une grande entreprise avec CMS personnalisé.',
//         clientName: 'Enterprise Corp',
//         categoryName: 'Développement web',
//         budgetRange: '20000_50000',
//         budgetDisplay: '25000€ - 40000€',
//         location: 'Paris',
//         remotePossible: true,
//         urgency: 'low',
//         status: 'open',
//         contactViaPlatform: true,
//         showEmail: false,
//         showPhone: false,
//         requiredSkills: ['PHP', 'Laravel', 'Vue.js', 'MySQL'],
//         offersCount: 15,
//         viewsCount: 67,
//         createdAt: DateTime.now().subtract(const Duration(days: 1)),
//         timeSincePosted: 'Il y a 1 jour',
//         isFavorited: false,
//         hasUserOffered: false,
//       ),
//     ];
//   }

//   List<Service> _getMockServices() {
//     return [
//       Service(
//         id: 1,
//         title: 'Développement site web',
//         description: 'Création de sites web modernes et responsives.',
//         imageUrl: '',
//         rating: 4.8,
//         reviewCount: 25,
//         provider_id: 1,
//         businessType: 'Freelance',
//         price: 1500.0,
//         priceType: 'fixed',
//         subcategoryId: 1,
//         categoryId: 1,
//         isAvailable: true,
//         galleryImages: [],
//         options: [],
//       ),
//     ];
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
// }












// ========================================================================2 =====================================================================
//=========================================================================222 ===================================================================
// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:w3_loc/core/models/conversation.dart';
import 'package:w3_loc/providers/messaging_provider.dart';
import 'package:w3_loc/ui/screens/messaging/conversation_detail_screen.dart';
import '../../core/models/review.dart';
import '../../providers/category_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/category.dart';
import '../../core/models/service.dart';
import '../../core/services/profile_manager.dart';
import '../../core/services/api_service.dart';
import '../screens/service_list_screen.dart';
import '../screens/service_detail_screen.dart';
import '../widgets/map_filter_screen.dart';
import 'dart:math' as math;
import 'base_screen.dart';
import '../../providers/location_provider.dart';
import '../../providers/provider_list_provider.dart';
import '../../providers/review_provider.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/client_project.dart';
import '../screens/project_detail_screen.dart';
import '../screens/messaging/messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<Service> _recentServices = [];
  List<Service> _nearbyServices = [];
  List<Service> _topRatedServices = [];
  Map<String, dynamic>? _providerStats;
  bool _showMapView = false;
  bool _isLoading = true;
  bool _isLoadingStats = false;

  List<Map<String, dynamic>> _recentProjects = [];
  List<Map<String, dynamic>> _recentQuoteRequests = [];
  bool _isLoadingProjects = false;
  bool _isLoadingQuotes = false;

  final math.Random random = math.Random();

  final List<String> serviceNames = [
    'Rénovation d\'intérieur',
    'Plomberie urgente',
    'Installation électrique',
    'Peinture de façade',
    'Ménage à domicile',
    'Jardinage & Entretien',
    'Construction',
    'Coiffure à domicile',
    'Massage',
    'Réparation automobile',
    'Expertise comptable',
    'Coaching sportif',
  ];

  @override
  void initState() {
    super.initState();
    //pour détecter les changements d'état de l'app
    WidgetsBinding.instance.addObserver(this);

    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  // Méthode appelée quand l'état de l'application change
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // L'application revient au premier plan - recharger les données
        print('Application resumed - Reloading data...');
        _loadData();
        break;
      case AppLifecycleState.paused:
        // L'application passe en arrière-plan
        print('Application paused');
        break;
      case AppLifecycleState.inactive:
        // L'application devient inactive (ex: appel entrant)
        print('Application inactive');
        break;
      case AppLifecycleState.detached:
        // L'application va être fermée
        print('Application detached');
        break;
      case AppLifecycleState.hidden:
        // L'application est cachée (nouveau dans Flutter 3.13+)
        print('Application hidden');
        break;
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    print('Loading all data...');

    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les données communes
      await _loadCommonData();

      // Charger les statistiques si l'utilisateur est un prestataire
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && ProfileManager.isProviderMode()) {
        await Future.wait([
          _loadProviderStats(),
          _loadProviderRecentProjects(),
          _loadProviderQuoteRequests(),
        ]);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Charger les vrais projets récents du prestataire
  Future<void> _loadProviderRecentProjects() async {
    setState(() {
      _isLoadingProjects = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Utiliser la nouvelle méthode de ton ApiService
      final response = await apiService.getProviderRecentProjects();

      if (response['results'] != null) {
        setState(() {
          _recentProjects =
              List<Map<String, dynamic>>.from(response['results']);
        });
      } else {
        setState(() {
          _recentProjects = [];
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des projets récents: $e');
      setState(() {
        _recentProjects = [];
      });
    } finally {
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  // Charger les vraies demandes de devis
  Future<void> _loadProviderQuoteRequests() async {
    setState(() {
      _isLoadingQuotes = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Utiliser la nouvelle méthode de ton ApiService
      final response = await apiService.getProviderQuoteRequests();

      if (response['results'] != null) {
        setState(() {
          _recentQuoteRequests =
              List<Map<String, dynamic>>.from(response['results']);
        });
      } else {
        setState(() {
          _recentQuoteRequests = [];
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des demandes de devis: $e');
      setState(() {
        _recentQuoteRequests = [];
      });
    } finally {
      setState(() {
        _isLoadingQuotes = false;
      });
    }
  }

  /// Navigation vers le détail du projet
  void _navigateToProjectDetail(Map<String, dynamic> projectData) {
    try {
      // Créer un objet ClientProject à partir des données du projet
      final project = ClientProject.fromJson(projectData);

      // Navigation vers ProjectDetailScreen avec l'objet ClientProject
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailScreen(project: project),
        ),
      );
    } catch (e) {
      print('Erreur lors de la navigation vers le détail du projet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'ouverture du projet'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Navigation vers les messages/chat
  void _navigateToChat(Map<String, dynamic> project) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour envoyer un message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Navigation vers MessagesScreen ou ConversationScreen selon votre implémentation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesScreen(
              // Vous pouvez passer des paramètres ici si nécessaire
              // Par exemple : initialClientId: project['client_id']
              ),
        ),
      );
    } catch (e) {
      print('Erreur lors de la navigation vers les messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'ouverture des messages'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Correction de la méthode de formatage du budget
  String _formatBudget(dynamic budget) {
    if (budget == null) return 'Budget à discuter';

    // Si c'est déjà une string formatée (budget_display), l'utiliser directement
    if (budget is String) {
      return budget.isNotEmpty ? budget : 'Budget à discuter';
    }

    // Si c'est un nombre, le formater
    if (budget is num) {
      return '${budget.toStringAsFixed(0)} €';
    }

    return 'Budget à discuter';
  }

  void _startConversationWithProjectOwner(Map<String, dynamic> project) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider =
        Provider.of<MessagingProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    // Vérifier l'authentification
    if (!authProvider.isAuthenticated || currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour contacter le client'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérifier que l'utilisateur est un prestataire
    if (currentUser.role != 'provider') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seuls les prestataires peuvent contacter les clients'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Ouverture de la conversation...'),
          ],
        ),
      ),
    );

    try {
      // Obtenir l'ID du projet
      final projectId = _parseId(project['id']);
      if (projectId == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: ID du projet introuvable'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Créer le message initial avec contexte du projet
      final projectTitle = project['title'] ?? 'ce projet';
      final initialMessage =
          'Bonjour, je suis intéressé(e) par votre projet "$projectTitle". Pouvons-nous en discuter ?';

      // 🎯 CORRECTION 1: Utiliser la méthode du MessagingProvider qui retourne un Conversation?
      final conversation = await messagingProvider.startConversationFromProject(
        projectId,
        initialMessage: null,
      );

      Navigator.pop(context); // Fermer le loading

      // 🎯 CORRECTION 2: Vérifier que la conversation n'est pas null
      if (conversation != null) {
        // Naviguer vers l'écran de conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversationId: conversation.id,
              otherPerson: conversation.otherPerson,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création de la conversation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Fermer le loading
      print('Erreur conversation: $e');

      String errorMessage = 'Erreur lors de l\'ouverture de la conversation';
      if (e.toString().contains('contacter votre propre projet')) {
        errorMessage = 'Vous ne pouvez pas contacter votre propre projet';
      } else if (e.toString().contains('Seuls les prestataires')) {
        errorMessage = 'Seuls les prestataires peuvent contacter les clients';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Méthode utilitaire pour parser les IDs
  int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _loadCommonData() async {
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    if (categoryProvider.categories.isEmpty) {
      await categoryProvider.fetchCategories();
    }

    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();

    final providerListProvider =
        Provider.of<ProviderListProvider>(context, listen: false);
    if (locationProvider.currentPosition != null) {
      await providerListProvider.fetchNearbyProviders(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
        radius: 10.0,
      );
    } else {
      await providerListProvider.fetchProviders();
    }

    final serviceProvider =
        Provider.of<ServiceProvider>(context, listen: false);
    await serviceProvider.fetchRecentServices();
    _recentServices = serviceProvider.recentServices;
    print("Les services récent:");
    print(_recentServices);
    await serviceProvider.fetchTopRatedServices();
    _topRatedServices = serviceProvider.topRatedServices;

    // Générer les services à proximité
    // if (providerListProvider.providers.isNotEmpty) {
    //   _nearbyServices = providerListProvider.providers.take(6).map((provider) {
    //     return Service(
    //       id: 200 + provider.id,
    //       title: provider.services.isNotEmpty
    //           ? provider.services.first.title
    //           : provider.name,
    //       description: provider.description,
    //       imageUrl: provider.profileImageUrl.isNotEmpty
    //           ? provider.profileImageUrl
    //           : 'https://picsum.photos/id/${1010 + provider.id}/300/200',
    //       rating: provider.rating,
    //       reviewCount: provider.reviewCount,
    //       provider_id: provider.id,
    //       businessType: provider.businessType,
    //       price: 50.0 + random.nextInt(150) * 1.0,
    //       categoryId: 1 + random.nextInt(5),
    //       priceType: random.nextBool() ? 'quote' : 'fixed',
    //     );
    //   }).toList();
    // } else {
    //   _nearbyServices = List.generate(
    //       6,
    //       (index) => Service(
    //             id: 200 + index,
    //             title: serviceNames[random.nextInt(serviceNames.length)],
    //             description: 'Service de proximité disponible rapidement',
    //             imageUrl: 'https://picsum.photos/id/${1010 + index}/300/200',
    //             rating: 3.5 + random.nextDouble() * 1.5,
    //             reviewCount: 5 + random.nextInt(30),
    //             provider_id: 300 + index,
    //             businessType: random.nextBool() ? 'Entreprise' : 'Freelance',
    //             price: 50.0 + random.nextInt(150) * 1.0,
    //             categoryId: 1 + random.nextInt(5),
    //             priceType: random.nextBool() ? 'quote' : 'fixed',
    //           ));
    // }
  }
  
  Future<void> _loadProviderStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final stats = await apiService.getProviderStats();

      setState(() {
        _providerStats = stats;
      });
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      // Données par défaut en cas d'erreur
      setState(() {
        _providerStats = {
          'prestations_completed_this_month': 0,
          'prestations_in_progress': 0,
          'unread_messages': 0, 
          'total_earnings_this_month': 0.0,
          'avg_rating': 0.0,
          'total_reviews': 0,
        };
      });
    } finally {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _searchServices(String query) async {
    try {
      // Naviguer vers la page de résultats de services
      Navigator.pushNamed(
        context,
        '/search-services',
        arguments: {'query': query, 'type': 'services'},
      );
    } catch (e) {
      print('Erreur lors de la recherche de services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _searchProjects(String query) async {
    try {
      // Naviguer vers la page de résultats de projets
      Navigator.pushNamed(
        context,
        '/search-projects',
        arguments: {'query': query, 'type': 'projects'},
      );
    } catch (e) {
      print('Erreur lors de la recherche de projets: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      currentIndex: 0,
      body: Stack(
        children: [
          _showMapView
              ? MapFilterScreen(
                  onClose: () => setState(() => _showMapView = false))
              : _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(child: _buildAdaptedContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 40,
            width: 80,
            errorBuilder: (context, error, stackTrace) => const Text(
              'LOGO',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.location_on),
                onPressed: () => setState(() => _showMapView = true),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  // Notifications
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    final isProvider = isAuthenticated && ProfileManager.isProviderMode();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: isProvider
                ? 'Rechercher un projet...'
                : 'Rechercher un service...',
            prefixIcon: Icon(isProvider ? Icons.work_outline : Icons.search,
                color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _performSearch(value, isProvider);
            }
          },
        ),
      ),
    );
  }

  void _performSearch(String query, bool isProvider) {
    if (isProvider) {
      // Recherche de projets pour les prestataires
      _searchProjects(query);
    } else {
      // Recherche de services pour les clients
      _searchServices(query);
    }
  }

  Widget _buildAdaptedContent() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;

    if (isAuthenticated && ProfileManager.isProviderMode()) {
      return _buildProviderHomeContent();
    } else {
      return _buildClientHomeContent();
    }
  }

  // ================== CONTENU PRESTATAIRE ==================
  Widget _buildProviderHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProviderBanner(),
          _buildProviderStatsSection(),
          _buildSectionTitle('Projets récents'),
          _buildProviderRecentProjects(),
          _buildSectionTitle('Demandes récentes'),
          _buildRecentQuoteRequests(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProviderBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 23, 47, 233), Color(0xFF142FE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Trouvez les meilleurs projets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Développez votre activité avec des clients de qualité',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/projects-list'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF142FE2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Voir les projets'),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode helper pour convertir safely les types
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }

  Widget _buildProviderStatsSection() {
    if (_isLoadingStats) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_providerStats == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes statistiques',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Prestations\nterminées',
                  value:
                      '${_safeToInt(_providerStats!['prestations_completed_this_month'])}',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'En cours',
                  value:
                      '${_safeToInt(_providerStats!['prestations_in_progress'])}',
                  icon: Icons.work_outline,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Messages\nnon lus',
                  value: '${_safeToInt(_providerStats!['unread_messages'])}',
                  icon: Icons.message_outlined,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Revenus\nce mois',
                  value:
                      '${_safeToDouble(_providerStats!['total_earnings_this_month']).toStringAsFixed(0)} FCFA',
                  icon: Icons.attach_money_outlined,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Note\nmoyenne',
                  value:
                      '${_safeToDouble(_providerStats!['avg_rating']).toStringAsFixed(1)}/5',
                  icon: Icons.star_outline,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total\navis',
                  value: '${_safeToInt(_providerStats!['total_reviews'])}',
                  icon: Icons.rate_review_outlined,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildProviderStatsSection() {
  //   if (_isLoadingStats) {
  //     return Container(
  //       margin: const EdgeInsets.symmetric(horizontal: 20),
  //       height: 200,
  //       child: const Center(child: CircularProgressIndicator()),
  //     );
  //   }

  //   if (_providerStats == null) {
  //     return const SizedBox.shrink();
  //   }

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Mes statistiques',
  //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //         ),
  //         const SizedBox(height: 16),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: _buildStatCard(
  //                 title: 'Prestations\nterminées',
  //                 value: '${_providerStats!['prestations_completed_this_month'] ?? 0}',
  //                 icon: Icons.check_circle_outline,
  //                 color: Colors.green,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: _buildStatCard(
  //                 title: 'En cours',
  //                 value: '${_providerStats!['prestations_in_progress'] ?? 0}',
  //                 icon: Icons.work_outline,
  //                 color: Colors.orange,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: _buildStatCard(
  //                 title: 'Messages\nnon lus',
  //                 value: '${_providerStats!['unread_messages'] ?? 0}',
  //                 icon: Icons.message_outlined,
  //                 color: Colors.blue,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: _buildStatCard(
  //                 title: 'Revenus\nce mois',
  //                 value: '${(_providerStats!['total_earnings_this_month'] as double?)?.toStringAsFixed(0) ?? '0'} FCFA',
  //                 icon: Icons.attach_money_outlined,
  //                 color: Colors.purple,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: _buildStatCard(
  //                 title: 'Note\nmoyenne',
  //                 value: '${(_providerStats!['avg_rating'] as double?)?.toStringAsFixed(1) ?? '0'}/5',
  //                 icon: Icons.star_outline,
  //                 color: Colors.amber,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: _buildStatCard(
  //                 title: 'Total\navis',
  //                 value: '${_providerStats!['total_reviews'] ?? 0}',
  //                 icon: Icons.rate_review_outlined,
  //                 color: Colors.indigo,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderRecentProjects() {
    if (_isLoadingProjects) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentProjects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.work_outline,
        message: 'Aucun projet récent trouvé',
        height: 180,
        actionText: 'Voir tous les projets',
        onAction: () => Navigator.pushNamed(context, '/projectsList'),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        scrollDirection: Axis.horizontal,
        itemCount: _recentProjects.length,
        itemBuilder: (context, index) {
          final project = _recentProjects[index];
          return _buildProjectCard(project);
        },
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    return Container(
      width: 280,
      height: 180, // ✅ AJOUT D'UNE HAUTEUR FIXE
      margin: const EdgeInsets.symmetric(horizontal: 5),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ IMPORTANT
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Titre et statut avec hauteur limitée
            SizedBox(
              height: 50, // Hauteur fixe pour cette section
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project['title'] ?? 'Projet sans nom',
                      style: const TextStyle(
                        fontSize: 14, // ✅ Taille réduite
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2, // ✅ Limiter à 2 lignes
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2), // ✅ Padding réduit
                    decoration: BoxDecoration(
                      color: _getStatusColor(project['status'] ?? 'unknown')
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(project['status']),
                      style: TextStyle(
                        fontSize: 10, // ✅ Taille réduite
                        color: _getStatusColor(project['status'] ?? 'unknown'),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ✅ Informations client et budget
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: Colors.grey), // ✅ Icône plus petite
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    project['client_name'] ??
                        project['client']?['name'] ??
                        'Client inconnu',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey), // ✅ Taille réduite
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.attach_money,
                    size: 14, color: Colors.grey), // ✅ Icône plus petite
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatBudget(project['budget_display']),
                    style: const TextStyle(
                      fontSize: 12, // ✅ Taille réduite
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ✅ Spacer pour pousser les boutons en bas
            const Spacer(),

            // ✅ Boutons d'action compacts
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // ✅ Aligner à droite
              children: [
                IconButton(
                  onPressed: () {
                    _navigateToProjectDetail(project);
                  },
                  icon: const Icon(Icons.visibility_outlined,
                      size: 18), // ✅ Icône plus petite
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    minimumSize: const Size(36, 36), // ✅ Taille minimale
                    padding: const EdgeInsets.all(6), // ✅ Padding réduit
                  ),
                  tooltip: 'Voir les détails',
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () {
                    _startConversationWithProjectOwner(project);
                  },
                  icon: const Icon(Icons.chat_bubble_outline,
                      size: 18), // ✅ Icône plus petite
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    minimumSize: const Size(36, 36), // ✅ Taille minimale
                    padding: const EdgeInsets.all(6), // ✅ Padding réduit
                  ),
                  tooltip: 'Contacter le client',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentQuoteRequests() {
    if (_isLoadingQuotes) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentQuoteRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.request_quote_outlined,
        message: 'Aucune demande de devis récente',
        height: 180,
        actionText: 'Voir toutes les demandes',
        onAction: () => Navigator.pushNamed(context, '/quote-requests'),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        scrollDirection: Axis.horizontal,
        itemCount: _recentQuoteRequests.length,
        itemBuilder: (context, index) {
          final request = _recentQuoteRequests[index];
          return _buildQuoteRequestCard(request);
        },
      ),
    );
  }

  Widget _buildQuoteRequestCard(Map<String, dynamic> request) {
    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(horizontal: 5),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request['title'] ??
                  request['service_title'] ??
                  'Service non spécifié',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  request['client_name'] ??
                      request['client']?['name'] ??
                      'Client inconnu',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatBudget(request['budget']),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(request['created_at']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Répondre à la demande
                      Navigator.pushNamed(
                        context,
                        '/quote-response',
                        arguments: request['id'],
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF142FE2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child:
                        const Text('Répondre', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    // Voir le détail
                    Navigator.pushNamed(
                      context,
                      '/quote-request-detail',
                      arguments: request['id'],
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Détails', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes utilitaires
  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'in_progress':
      case 'active':
        return 'En cours';
      case 'completed':
      case 'finished':
        return 'Terminé';
      case 'pending':
      case 'waiting':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Statut inconnu';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) return 'Aujourd\'hui';
      if (difference == 1) return 'Hier';
      if (difference < 7) return 'Il y a $difference jours';
      return 'Il y a ${(difference / 7).floor()} semaines';
    } catch (e) {
      return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
        return Colors.blue;
      case 'terminé':
        return Colors.green;
      case 'en attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ================== CONTENU CLIENT ==================
  Widget _buildClientHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientBanner(),
          _buildSectionTitle('Meilleurs prestations de la semaine'),
          _buildHorizontalServicesList(
              _topRatedServices, 'Aucune prestation populaire pour le moment'),
          _buildSectionTitle('Annonces récentes'),
          _buildHorizontalServicesList(
              _recentServices, 'Aucune annonce récente disponible'),
          _buildSectionTitle('Meilleurs avis'),
          _buildReviewsSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildClientBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142FE2), Color(0xFF4B39EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Trouvez les meilleurs prestataires',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Réservez facilement des services de qualité',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/explore'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF142FE2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Explorer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== WIDGETS COMMUNS ==================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHorizontalServicesList(
      List<Service> services, String emptyMessage) {
    if (_isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (services.isEmpty) {
      return _buildEmptyState(
        icon: Icons.home_repair_service_outlined,
        message: emptyMessage,
        height: 220,
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailScreen(
                      serviceId: service.id,
                      providerId: service.provider_id,
                    ),
                  ),
                );
              },
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        service.imageUrl,
                        width: 160,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 160,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    // Contenu
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.businessType,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                service.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "(${service.reviewCount})",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.priceType == 'quote'
                                ? 'Sur devis'
                                : '${service.price.toInt()} FCFA',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF142FE2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final reviews = reviewProvider.topReviews;

        if (reviewProvider.isLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (reviews.isEmpty) {
          return _buildEmptyState(
            icon: Icons.rate_review_outlined,
            message: 'Aucun avis disponible pour le moment',
            height: 200,
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                width: 300,
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            child: Text(review.clientName.isNotEmpty
                                ? review.clientName[0]
                                : 'U'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.clientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "Service",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  review.rating.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Text(
                          review.comment,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required double height,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142FE2),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
