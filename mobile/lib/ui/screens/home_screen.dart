// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/service_provider.dart';
import '../../core/models/category.dart';
import '../../core/models/service.dart';
import '../screens/service_list_screen.dart';
import '../screens/service_detail_screen.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/map_filter_screen.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Service> _recentServices = [];
  List<Service> _nearbyServices = [];
  List<Service> _topRatedServices = [];
  List<Service> _featuredServices = [];
  bool _showMapView = false;
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
    // Charger les catégories
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    if (categoryProvider.categories.isEmpty) {
      categoryProvider.fetchCategories();
    }

    // Simuler le chargement des services pour la démo
    _generateDemoServices();
  }

  // Cette méthode simule le chargement de services pour la démo
  void _generateDemoServices() {
    // Pour la démo, on crée des services aléatoires
    final serviceNames = [
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

    final random = math.Random();

    // Services récents
    _recentServices = List.generate(
      6,
      (index) => Service(
        id: 100 + index,
        title: serviceNames[random.nextInt(serviceNames.length)],
        description: 'Service de qualité par des professionnels',
        imageUrl: 'https://picsum.photos/id/${1000 + index}/300/200',
        rating: 3.5 + random.nextDouble() * 1.5,
        reviewCount: 5 + random.nextInt(30),
        providerId: 200 + index,
        businessType: random.nextBool() ? 'Entreprise' : 'Freelance',
        price: 50.0 + random.nextInt(150) * 1.0,
        categoryId: 1 + random.nextInt(5),
        priceType: random.nextBool() ? 'fixed' : 'hourly',
      ),
    );

    // Services à proximité
    _nearbyServices = List.generate(
      6,
      (index) => Service(
        id: 200 + index,
        title: serviceNames[random.nextInt(serviceNames.length)],
        description: 'Service de proximité disponible rapidement',
        imageUrl: 'https://picsum.photos/id/${1010 + index}/300/200',
        rating: 3.5 + random.nextDouble() * 1.5,
        reviewCount: 5 + random.nextInt(30),
        providerId: 300 + index,
        businessType: random.nextBool() ? 'Entreprise' : 'Freelance',
        price: 50.0 + random.nextInt(150) * 1.0,
        categoryId: 1 + random.nextInt(5),
        priceType: random.nextBool() ? 'quote' : 'fixed',
      ),
    );

    // Meilleurs prestations de la semaine (top rated)
    _topRatedServices = List.generate(
      6,
      (index) => Service(
        id: 300 + index,
        title: serviceNames[random.nextInt(serviceNames.length)],
        description: 'Service hautement recommandé',
        imageUrl: 'https://picsum.photos/id/${1020 + index}/300/200',
        rating: 4.5 + (random.nextDouble() * 0.5), // Notes plus élevées
        reviewCount: 20 + random.nextInt(50),
        providerId: 400 + index,
        businessType: random.nextBool() ? 'Entreprise' : 'Freelance',
        price: 50.0 + random.nextInt(150) * 1.0,
        categoryId: 1 + random.nextInt(5),
        priceType: random.nextBool() ? 'fixed' : 'hourly',
      ),
    );

    // Annonces récentes (featured)
    _featuredServices = List.generate(
      6,
      (index) => Service(
        id: 400 + index,
        title: serviceNames[random.nextInt(serviceNames.length)],
        description: 'Service en promotion',
        imageUrl: 'https://picsum.photos/id/${1030 + index}/300/200',
        rating: 4.0 + random.nextDouble(),
        reviewCount: 10 + random.nextInt(40),
        providerId: 500 + index,
        businessType: random.nextBool() ? 'Entreprise' : 'Freelance',
        price: 50.0 + random.nextInt(150) * 1.0,
        categoryId: 1 + random.nextInt(5),
        priceType: random.nextBool() ? 'fixed' : 'quote',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _showMapView
              ? MapFilterScreen(
                  onClose: () => setState(() => _showMapView = false))
              : _buildMainContent(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0, // Accueil est sélectionné
        onTap: (index) {
          if (index == 0) {
            // Déjà sur l'accueil
          } else if (index == 1) {
            Navigator.pushNamed(context, '/explore');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/messages');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec logo et icônes
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo - utiliser un logo local
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.location_on),
                      onPressed: () {
                        setState(() {
                          _showMapView = true;
                        });
                      },
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
          ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un service...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    // Naviguer vers les résultats de recherche
                  }
                },
              ),
            ),
          ),

          // TabBar pour les différentes sections
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF142FE2),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF142FE2),
            tabs: const [
              Tab(text: 'Accueil'),
              Tab(text: 'Meilleurs'),
              Tab(text: 'Récents'),
              Tab(text: 'Proximité'),
            ],
          ),

          // Contenu des tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeTab(),
                _buildTopRatedTab(),
                _buildRecentTab(),
                _buildNearbyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab d'accueil
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière promotionnelle
          Container(
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/explore');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF142FE2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Explorer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Catégories
          _buildCategories(),

          // Meilleurs prestations de la semaine
          _buildSectionTitle('Meilleurs prestations de la semaine'),
          _buildHorizontalServicesList(_topRatedServices),

          // Annonces récentes
          _buildSectionTitle('Annonces récentes'),
          _buildHorizontalServicesList(_featuredServices),

          // Meilleurs avis
          _buildSectionTitle('Meilleurs avis'),
          _buildReviewsSection(),

          // Services à proximité
          _buildSectionTitle('À proximité de vous'),
          _buildVerticalServicesList(_nearbyServices, 3),

          // Voir tous les services
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/explore');
                },
                icon: const Icon(Icons.explore),
                label: const Text('Explorer tous les services'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142FE2),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),

          // Espace au fond
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Tab des meilleurs services
  Widget _buildTopRatedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Meilleurs prestataires par note',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildVerticalServicesList(
              _topRatedServices, _topRatedServices.length),
        ],
      ),
    );
  }

  // Tab des services récents
  Widget _buildRecentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Annonces les plus récentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildVerticalServicesList(
              _featuredServices, _featuredServices.length),
        ],
      ),
    );
  }

  // Tab des services à proximité
  Widget _buildNearbyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Services à proximité',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showMapView = true;
                  });
                },
                icon: const Icon(Icons.map, size: 16),
                label: const Text('Carte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142FE2),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVerticalServicesList(_nearbyServices, _nearbyServices.length),
        ],
      ),
    );
  }

  // Widget pour afficher les catégories
  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Text(
            'Catégories populaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Grille de catégories
        Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            if (categoryProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final categories = categoryProvider.categories.isEmpty
                ? Category.getDefaultCategories()
                : categoryProvider.categories;

            // Limiter à 4 catégories pour l'écran d'accueil
            final displayCategories =
                categories.length > 4 ? categories.sublist(0, 4) : categories;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(displayCategories.length, (index) {
                  final category = displayCategories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceListScreen(
                            categoryId: category.id,
                            categoryName: category.name,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category.id),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCategoryIcon(category.id),
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 80,
                          child: Text(
                            category.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        ),

        // Voir toutes les catégories
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/explore');
            },
            child: const Text(
              'Voir toutes les catégories',
              style: TextStyle(
                color: Color(0xFF142FE2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour afficher le titre d'une section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget pour afficher une liste horizontale de services
  Widget _buildHorizontalServicesList(List<Service> services) {
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

  // Widget pour afficher une liste verticale de services
  Widget _buildVerticalServicesList(List<Service> services, int limit) {
    final displayServices =
        services.length > limit ? services.sublist(0, limit) : services;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayServices.length,
      itemBuilder: (context, index) {
        final service = displayServices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(
                    serviceId: service.id,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      service.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  ),

                  // Détails du service
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.businessType,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                service.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "(${service.reviewCount})",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Prix et bouton
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          service.priceType == 'quote'
                              ? 'Sur devis'
                              : '${service.price.toInt()} FCFA',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF142FE2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServiceDetailScreen(
                                  serviceId: service.id,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF142FE2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: const Size(60, 30),
                          ),
                          child: const Text(
                            'Voir',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }

  // Widget pour afficher la section des meilleurs avis
  Widget _buildReviewsSection() {
    final reviews = [
      {
        'userName': 'Sophie M.',
        'userImage': 'https://randomuser.me/api/portraits/women/44.jpg',
        'service': 'Plomberie',
        'rating': 5.0,
        'comment':
            'Un travail impeccable et très rapide. Je recommande vivement!',
        'date': 'Il y a 2 jours',
      },
      {
        'userName': 'Jean D.',
        'userImage': 'https://randomuser.me/api/portraits/men/32.jpg',
        'service': 'Rénovation Intérieure',
        'rating': 4.8,
        'comment':
            'Excellent travail de rénovation, très soigné et professionnel.',
        'date': 'Il y a 3 jours',
      },
      {
        'userName': 'Marie L.',
        'userImage': 'https://randomuser.me/api/portraits/women/68.jpg',
        'service': 'Électricité',
        'rating': 5.0,
        'comment': 'Très réactif et compétent, problème résolu rapidement.',
        'date': 'Il y a 1 semaine',
      },
    ];

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
                      // Photo de profil
                      CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            NetworkImage(review['userImage'] as String),
                        onBackgroundImageError: (exception, stackTrace) {},
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['userName'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              review['service'] as String,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Note
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
                              (review['rating'] as double).toStringAsFixed(1),
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
                      review['comment'] as String,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review['date'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Méthodes pour obtenir la couleur et l'icône de chaque catégorie
  Color _getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 1:
        return const Color(0xFF4B39EF); // Maison & Construction
      case 2:
        return const Color(0xFFAA39EF); // Bien-être & Beauté
      case 3:
        return const Color(0xFFEF3976); // Événements & Artistiques
      case 4:
        return const Color(0xFF4B88EF); // Transport & Logistique
      case 5:
        return const Color(0xFFEF6C39); // Santé & Bien-être
      case 6:
        return const Color(0xFF39EFBA); // Services Professionnels
      case 7:
        return const Color(0xFF3976EF); // Services Numériques
      case 8:
        return const Color(0xFFEFD939); // Services pour Animaux
      case 9:
        return const Color(0xFF39BAEF); // Services Divers
      default:
        return const Color(0xFF142FE2);
    }
  }

  IconData _getCategoryIcon(int categoryId) {
    switch (categoryId) {
      case 1:
        return Icons.home;
      case 2:
        return Icons.spa;
      case 3:
        return Icons.event;
      case 4:
        return Icons.local_shipping;
      case 5:
        return Icons.favorite;
      case 6:
        return Icons.work;
      case 7:
        return Icons.computer;
      case 8:
        return Icons.pets;
      case 9:
        return Icons.miscellaneous_services;
      default:
        return Icons.category;
    }
  }
}
