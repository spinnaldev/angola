import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart'; // AJOUT pour la localisation
import 'package:teyago/core/models/provider_model.dart';
import 'package:teyago/ui/screens/reviews_screen.dart';
import '../../core/models/review.dart';
import '../../core/models/client_project.dart';
import '../../providers/category_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../../core/models/service.dart';
import '../../core/services/api_service.dart';
import '../screens/service_list_screen.dart';
import '../screens/service_detail_screen.dart';
import '../screens/projects_list_screen.dart';
import '../screens/project_detail_screen.dart';
import '../widgets/map_filter_screen.dart';
import 'dart:math' as math;
import 'base_screen.dart';
import '../../providers/location_provider.dart';
import '../../providers/provider_list_provider.dart';
import '../../providers/review_provider.dart';
import 'search_results_screen.dart';
import '../widgets/service_image.dart';
import '../../providers/notification_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/services/improved_location_service.dart';
import '../../providers/improved_nearby_provider.dart';
import '../screens/provider/quote_requests_screen.dart';
import '../screens/provider/my_offers_screen.dart';
import '../screens/messaging/messages_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/shared_header.dart';

import 'dart:math' show Random;

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
  List<Review> _topReviews = [];

  bool _hasFetchedReviews = false;

  // Variables pour les projets (mode prestataire)
  List<ClientProject> _recentProjects = [];
  List<ClientProject> _nearbyProjects = [];

  // Variables pour les statistiques prestataire
  Map<String, dynamic> _providerStats = {};
  bool _isLoadingStats = false;

  bool _showMapView = false;
  late TabController _tabController;
  bool _isLoading = true;

  // NOUVELLES VARIABLES POUR LA LOCALISATION
  bool _isLocationLoading = false;
  String? _currentLocationName;
  bool _locationPermissionDenied = false;
  bool? _previousAuthState;
  // Add the missing random instance
  final math.Random random = math.Random();

  // Add the missing serviceNames list
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentAuthState = authProvider.isAuthenticated;
    
    if (_previousAuthState != null && _previousAuthState != currentAuthState) {
      print("🔓 Changement d'état d'authentification détecté");
      
      if (!currentAuthState) {
        print("🔔 Utilisateur déconnecté - Effacement des notifications");
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.clearNotifications();
      } else {
        print("🔔 Utilisateur connecté - Chargement des notifications");
        _loadNotificationsIfAuthenticated();
      }
    }
    
    _previousAuthState = currentAuthState;
    
    if (!_hasFetchedReviews) {
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      reviewProvider.fetchTopReviews();
      _hasFetchedReviews = true;
    }
  }

  // Ajouter cette nouvelle méthode :
  void _loadNotificationsIfAuthenticated() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      print("🔔 Utilisateur connecté - Chargement des notifications");
      notificationProvider.loadUnreadCount();
    } else {
      print("🔔 Utilisateur non connecté - Effacement des notifications");
      notificationProvider.clearNotifications();
    }
  }
  

  @override
  void initState() {
    super.initState();
    // Différents onglets selon le profil
    int tabLength = _isProviderMode()
        ? 3
        : 4; // Prestataires: 3 onglets, Clients: 4 onglets
    _tabController = TabController(length: tabLength, vsync: this);
    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        _previousAuthState = authProvider.isAuthenticated;
        _loadNotificationsIfAuthenticated();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isProviderMode() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isAuthenticated && ProfileManager.isProviderMode();
  }

  void _performSearch() {
    final query = _searchController.text.trim();

    if (query.isNotEmpty) {
      final searchType = _isProviderMode() ? 'projects' : 'services';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            query: query,
            type: searchType,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un terme de recherche'),
        ),
      );
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isProviderMode()) {
        // Mode prestataire - charger les projets
        await _loadProjectsData();
      } else {
        // Mode client/invité - charger les services
        await _loadServicesData();
      }

      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      _topReviews = reviewProvider.topReviews;
      print("ON a recuperer les top reviews unh");
      print(_topReviews);
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

  void _convertProvidersToServices(List<ProviderModel> providers) {
    _nearbyServices = providers.take(6).map((provider) {
      return Service(
        id: 200 + provider.id,
        title: provider.services.isNotEmpty
            ? provider.services.first.title
            : provider.name,
        description: provider.description,
        imageUrl: provider.profileImageUrl.isNotEmpty
            ? provider.profileImageUrl
            : 'https://picsum.photos/id/${1010 + provider.id}/300/200',
        rating: provider.rating,
        reviewCount: provider.reviewCount,
        provider_id: provider.id,
        businessType: provider.businessType,
        price: 50.0 + Random().nextInt(150).toDouble(),
        categoryId: 1 + Random().nextInt(5),
        priceType: Random().nextBool() ? 'quote' : 'fixed',
        distance: provider.distance,
      );
    }).toList();
  }

  // MÉTHODE AMÉLIORÉE _loadServicesData avec gestion de la localisation
  Future<void> _loadServicesData() async {
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    if (categoryProvider.categories.isEmpty) {
      await categoryProvider.fetchCategories();
    }

    // GESTION AMÉLIORÉE DE LA LOCALISATION
    setState(() {
      _isLocationLoading = true;
    });

    final locationService =
        Provider.of<ImprovedLocationService>(context, listen: false);
    final nearbyProvider =
        Provider.of<ImprovedNearbyProvider>(context, listen: false);

    try {
      bool locationSuccess = await locationService.getCurrentLocation();
      if (locationSuccess && locationService.hasValidPosition) {
        setState(() {
          _locationPermissionDenied = false;
          _isLocationLoading = false;
        });

        await nearbyProvider.searchNearbyProviders(
            radius: 10.0, forceRefresh: true);
        _convertProvidersToServices(nearbyProvider.nearbyProviders);
        await _getCurrentLocationName(locationService.currentPosition!);
      } else {
        setState(() {
          _locationPermissionDenied = true;
          _isLocationLoading = false;
        });
        await _loadServicesWithoutLocation();
      }
    } catch (e) {
      print('Erreur localisation: $e');
      setState(() {
        _isLocationLoading = false;
        _locationPermissionDenied = true;
      });
      await _loadServicesWithoutLocation();
    }

    // final locationProvider =
    //     Provider.of<LocationProvider>(context, listen: false);

    // try {
    //   // Vérifier les services de localisation
    //   bool servicesEnabled = await locationProvider.checkLocationServices();
    //   if (!servicesEnabled) {
    //     setState(() {
    //       _locationPermissionDenied = true;
    //       _isLocationLoading = false;
    //     });
    //     // Continuer sans localisation
    //     await _loadServicesWithoutLocation();
    //     return;
    //   }

    //   // Demander la permission et récupérer la position
    //   bool permissionGranted = await locationProvider.requestLocationPermission();
    //   if (!permissionGranted) {
    //     setState(() {
    //       _locationPermissionDenied = true;
    //       _isLocationLoading = false;
    //     });
    //     // Continuer sans localisation
    //     await _loadServicesWithoutLocation();
    //     return;
    //   }

    //   // Récupérer la position actuelle
    //   bool locationSuccess = await locationProvider.getCurrentLocation();
    //   if (locationSuccess && locationProvider.currentPosition != null) {
    //     setState(() {
    //       _locationPermissionDenied = false;
    //       _isLocationLoading = false;
    //     });

    //     // Récupérer le nom de la ville (optionnel)
    //     await _getCurrentLocationName(locationProvider.currentPosition!);

    //     // Charger les prestataires à proximité
    //     await _loadNearbyProviders(locationProvider.currentPosition!);
    //   } else {
    //     setState(() {
    //       _isLocationLoading = false;
    //     });
    //     // Continuer sans localisation
    //     await _loadServicesWithoutLocation();
    //   }
    // } catch (e) {
    //   print('Erreur lors de la récupération de la localisation: $e');
    //   setState(() {
    //     _isLocationLoading = false;
    //   });
    //   await _loadServicesWithoutLocation();
    // }

    // Charger les autres services (récents, mieux notés)
    final serviceProvider =
        Provider.of<ServiceProvider>(context, listen: false);

    try {
      await serviceProvider.fetchRecentServices();
      _recentServices = serviceProvider.recentServices;

      await serviceProvider.fetchTopRatedServices();
      _topRatedServices = serviceProvider.topRatedServices;
    } catch (e) {
      print('Erreur lors du chargement des services: $e');
    }
  }

  // NOUVELLES MÉTHODES POUR LA GESTION DE LA LOCALISATION
  Future<void> _getCurrentLocationName(Position position) async {
    try {
      // Vous pouvez utiliser geocoding pour récupérer le nom de la ville
      // Pour l'instant, on définit un nom générique
      setState(() {
        _currentLocationName = 'Votre position';
      });
    } catch (e) {
      print('Erreur lors de la récupération du nom de la localisation: $e');
    }
  }

  Future<void> _loadNearbyProviders(Position position) async {
    final providerListProvider =
        Provider.of<ProviderListProvider>(context, listen: false);

    try {
      await providerListProvider.fetchNearbyProviders(
        position.latitude,
        position.longitude,
        radius: 10.0, // 10 km de rayon
      );

      // Générer les services à proximité
      if (providerListProvider.providers.isNotEmpty) {
        _nearbyServices =
            providerListProvider.providers.take(6).map((provider) {
          return Service(
            id: 200 + provider.id,
            title: provider.services.isNotEmpty
                ? provider.services.first.title
                : provider.name,
            description: provider.description,
            imageUrl: provider.profileImageUrl.isNotEmpty
                ? provider.profileImageUrl
                : 'https://picsum.photos/id/${1010 + provider.id}/300/200',
            rating: provider.rating,
            reviewCount: provider.reviewCount,
            provider_id: provider.id,
            businessType: provider.businessType,
            price: 50.0 + random.nextInt(150) * 1.0,
            categoryId: 1 + random.nextInt(5),
            priceType: random.nextBool() ? 'quote' : 'fixed',
          );
        }).toList();
      } else {
        _nearbyServices = [];
      }
    } catch (e) {
      print('Erreur lors du chargement des prestataires à proximité: $e');
      _nearbyServices = [];
    }
  }

  Future<void> _loadServicesWithoutLocation() async {
    final providerListProvider =
        Provider.of<ProviderListProvider>(context, listen: false);

    try {
      // Charger tous les prestataires sans filtre de proximité
      await providerListProvider.fetchProviders();

      // Générer quelques services par défaut
      if (providerListProvider.providers.isNotEmpty) {
        _nearbyServices =
            providerListProvider.providers.take(6).map((provider) {
          return Service(
            id: 200 + provider.id,
            title: provider.services.isNotEmpty
                ? provider.services.first.title
                : provider.name,
            description: provider.description,
            imageUrl: provider.profileImageUrl.isNotEmpty
                ? provider.profileImageUrl
                : 'https://picsum.photos/id/${1010 + provider.id}/300/200',
            rating: provider.rating,
            reviewCount: provider.reviewCount,
            provider_id: provider.id,
            businessType: provider.businessType,
            price: 50.0 + random.nextInt(150) * 1.0,
            categoryId: 1 + random.nextInt(5),
            priceType: random.nextBool() ? 'quote' : 'fixed',
          );
        }).toList();
      } else {
        _nearbyServices = [];
      }
    } catch (e) {
      print('Erreur lors du chargement des prestataires: $e');
      _nearbyServices = [];
    }
  }

  // MÉTHODE AMÉLIORÉE _loadProjectsData avec gestion de la localisation
  Future<void> _loadProjectsData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Charger les statistiques du prestataire
      await _loadProviderStats();

      // === NOUVELLE GESTION DE LA LOCALISATION POUR LES PROJETS ===
      setState(() {
        _isLocationLoading = true;
      });

      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);

      try {
        // Récupérer la position pour les projets à proximité
        bool servicesEnabled = await locationProvider.checkLocationServices();
        if (servicesEnabled) {
          bool permissionGranted =
              await locationProvider.requestLocationPermission();
          if (permissionGranted) {
            bool locationSuccess = await locationProvider.getCurrentLocation();
            if (locationSuccess && locationProvider.currentPosition != null) {
              await _loadNearbyProjects(locationProvider.currentPosition!);
            }
          }
        }
      } catch (e) {
        print('Erreur localisation projets: $e');
      } finally {
        setState(() {
          _isLocationLoading = false;
        });
      }

      // Charger les projets récents directement depuis l'API
      final recentProjectsResponse =
          await apiService.getProviderRecentProjects();
      print("Projets utilisateur");

      try {
        final List<dynamic> rawProjects =
            recentProjectsResponse['results'] ?? [];
        _recentProjects = rawProjects
            .map((projectData) =>
                ClientProject.fromJson(projectData as Map<String, dynamic>))
            .toList();
        print("${_recentProjects.length} projets chargés avec succès");
      } catch (e) {
        print('Erreur lors de la conversion des projets: $e');
        _recentProjects = [];
      }

      // Si pas de projets récents depuis l'API, essayer le ProjectProvider comme fallback
      if (_recentProjects.isEmpty) {
        final projectProvider =
            Provider.of<ProjectProvider>(context, listen: false);
        await projectProvider.fetchUserProjects();

        // Prendre les projets utilisateur et les trier par date
        final allUserProjects = projectProvider.userProjects;
        if (allUserProjects.isNotEmpty) {
          allUserProjects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _recentProjects = allUserProjects.take(8).toList();
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des projets: $e');
      // En cas d'erreur, utiliser des données de fallback
      _recentProjects = _generateMockProjects(8);
      _nearbyProjects = _generateMockProjects(6);
    }
  }

  // NOUVELLE MÉTHODE pour charger les projets à proximité
  Future<void> _loadNearbyProjects(Position position) async {
    try {
      // Pour l'instant, générer des projets mockés basés sur la localisation
      // Vous pouvez adapter selon votre API
      _nearbyProjects = [];
    } catch (e) {
      print('Erreur lors du chargement des projets à proximité: $e');
      _nearbyProjects = [];
    }
  }

  // NOUVELLE MÉTHODE pour générer des projets mockés à proximité
  List<ClientProject> _generateNearbyProjectsMock(Position position) {
    final List<String> nearbyAreas = [
      'Cotonou Centre',
      'Calavi',
      'Akpakpa',
      'Godomey',
      'Fidjrossè',
      'Dantokpa',
    ];

    return List.generate(
      6,
      (index) {
        return ClientProject(
          id: 300 + index,
          title: 'Projet ${_getLocalProjectType(index)} à proximité',
          description:
              'Projet local nécessitant une intervention rapide dans votre zone.',
          clientName: 'Client ${nearbyAreas[index % nearbyAreas.length]}',
          categoryName: _getProjectCategory(index),
          budgetRange: _getBudgetRange(index),
          budgetDisplay:
              '${_getBudgetMin(index)} - ${_getBudgetMax(index)} AOA',
          location: nearbyAreas[index % nearbyAreas.length],
          remotePossible: random.nextBool(),
          urgency: [
            'high',
            'very_high'
          ][random.nextInt(2)], // Projets urgents à proximité
          status: 'open',
          contactViaPlatform: true,
          showEmail: false,
          showPhone: true, // Plus de contact direct pour les projets locaux
          requiredSkills: _getRequiredSkills(index),
          offersCount: random.nextInt(5), // Moins d'offres car nouveau
          viewsCount: 10 + random.nextInt(50),
          createdAt:
              DateTime.now().subtract(Duration(hours: random.nextInt(24))),
        );
      },
    );
  }

  // NOUVELLE MÉTHODE Types de projets locaux spécifiques
  String _getLocalProjectType(int index) {
    final types = [
      'réparation urgente',
      'dépannage électrique',
      'plomberie d\'urgence',
      'livraison express',
      'nettoyage après sinistre',
      'sécurité événement',
    ];
    return types[index % types.length];
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

  List<ClientProject> _generateMockProjects(int count) {
    return List.generate(
      count,
      (index) => ClientProject(
        id: 200 + index,
        title: 'Projet de ${_getProjectType(index)}',
        description:
            'Description détaillée du projet nécessitant des compétences spécialisées',
        clientName: 'Client ${index + 1}',
        categoryName: _getProjectCategory(index),
        budgetRange: _getBudgetRange(index),
        budgetDisplay: '${_getBudgetMin(index)} - ${_getBudgetMax(index)} AOA',
        location: 'Cotonou, Bénin',
        remotePossible: random.nextBool(),
        urgency: _getUrgency(index),
        status: 'open',
        contactViaPlatform: true,
        showEmail: false,
        showPhone: false,
        requiredSkills: _getRequiredSkills(index),
        offersCount: random.nextInt(15),
        viewsCount: 20 + random.nextInt(100),
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(7))),
      ),
    );
  }

  String _getProjectType(int index) {
    final types = [
      'développement web',
      'rénovation',
      'design graphique',
      'plomberie',
      'électricité',
      'jardinage',
      'nettoyage',
      'coaching'
    ];
    return types[index % types.length];
  }

  String _getProjectCategory(int index) {
    final categories = [
      'Informatique',
      'Maison & Jardin',
      'Services Pro',
      'Artisanat',
      'Bien-être',
      'Transport'
    ];
    return categories[index % categories.length];
  }

  String _getBudgetRange(int index) {
    final ranges = ['100-500', '500-1000', '1000-5000', '5000-15000'];
    return ranges[index % ranges.length];
  }

  int _getBudgetMin(int index) {
    final mins = [100, 500, 1000, 5000];
    return mins[index % mins.length];
  }

  int _getBudgetMax(int index) {
    final maxs = [500, 1000, 5000, 15000];
    return maxs[index % maxs.length];
  }

  String _getUrgency(int index) {
    final urgencies = ['low', 'medium', 'high', 'very_high'];
    return urgencies[index % urgencies.length];
  }

  List<String> _getRequiredSkills(int index) {
    final skillSets = [
      ['Flutter', 'Dart', 'Mobile'],
      ['Plomberie', 'Réparation', 'Installation'],
      ['Design', 'Photoshop', 'Créativité'],
      ['Électricité', 'Sécurité', 'Installation'],
      ['Jardinage', 'Entretien', 'Paysagisme'],
      ['Nettoyage', 'Hygiène', 'Détail'],
    ];
    return skillSets[index % skillSets.length];
  }

  // NOUVEAU WIDGET pour l'icône de localisation intelligente
  Widget _buildLocationIcon(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                _locationPermissionDenied
                    ? Icons.location_disabled
                    : locationProvider.currentPosition != null
                        ? Icons.location_on
                        : Icons.location_searching,
                color: _locationPermissionDenied
                    ? Colors.red
                    : locationProvider.currentPosition != null
                        ? Colors.green
                        : Colors.grey,
              ),
              onPressed: () {
                if (_locationPermissionDenied) {
                  _showLocationPermissionDialog();
                } else {
                  setState(() {
                    _showMapView = true;
                  });
                }
              },
              tooltip: _getLocationTooltip(locationProvider),
            ),
            if (_isLocationLoading)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // NOUVELLES MÉTHODES HELPER pour la localisation
  String _getLocationTooltip(LocationProvider locationProvider) {
    final l10n = AppLocalizations.of(context)!;

    if (_locationPermissionDenied) {
      return l10n.locationPermissionDenied;
    } else if (locationProvider.currentPosition != null) {
      return _currentLocationName ?? l10n.locationEnabled;
    } else {
      return l10n.searchingYourPosition;
    }
  }

  void _showLocationPermissionDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.locationPermission),
          content: Text(l10n.locationPermissionDialogContent),
          actions: [
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(l10n.settings),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // NOUVEAU WIDGET pour afficher le statut de localisation
  Widget _buildLocationStatus() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<LocationProvider, AuthProvider>(
      builder: (context, locationProvider, authProvider, child) {
        // ✅ NOUVEAU : Déterminer le type d'utilisateur connecté
        final user = authProvider.currentUser;
        final isProvider = user?.role == 'provider';

        // ✅ NOUVEAU : Définir le type d'entités à afficher selon le rôle
        String nearbyType;
        String enableLocationMessage;

        if (isProvider) {
          // Si je suis prestataire, je veux voir les clients à proximité
          nearbyType = l10n.clientsNearby;
          enableLocationMessage = l10n.enableLocationForClients;
        } else {
          // Si je suis client, je veux voir les prestataires à proximité
          nearbyType = l10n.providersNearby;
          enableLocationMessage = l10n.enableLocationForProviders;
        }

        if (_locationPermissionDenied) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_disabled, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.locationDisabled, // ✅ TRADUCTION
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      Text(
                        enableLocationMessage, // ✅ TRADUCTION + LOGIQUE RÔLE
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // Réessayer d'obtenir la localisation
                    await _loadData();
                  },
                  child: Text(l10n.retry), // ✅ TRADUCTION
                ),
              ],
            ),
          );
        } else if (locationProvider.currentPosition != null) {
          // ✅ NOUVEAU : Ne montrer que si on a de vraies données
          final nearbyCount = _getNearbyCount(isProvider);

          // ✅ NOUVEAU : N'afficher que s'il y a vraiment des données
          if (nearbyCount == 0) {
            return const SizedBox
                .shrink(); // Ne rien afficher si pas de données
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentLocationName ??
                        l10n.locationActivated, // ✅ TRADUCTION
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green[800],
                    ),
                  ),
                ),
                Text(
                  l10n.nearbyCount(nearbyCount.toString(), nearbyType),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  int _getNearbyCount(bool isProvider) {
    if (isProvider) {
      // Si je suis prestataire, compter les clients/projets à proximité
      return _nearbyProjects
          .length; // ou _nearbyClients.length si vous avez cette liste
    } else {
      // Si je suis client, compter les prestataires à proximité
      return _nearbyServices.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      currentIndex: 0, // Accueil est sélectionné
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
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec logo et icônes - MODIFIÉ
          // ✅ EN-TÊTE AVEC LOCALISATION (uniquement pour l'accueil)
          SharedHeader(
            showLocationIcon: true, // ← Active l'icône de localisation
            locationPermissionDenied: _locationPermissionDenied,
            isLocationLoading: _isLocationLoading,
            onLocationTap: () {
              setState(() {
                _showMapView = true;
              });
            },
            onLocationPermissionDenied: () {
              _showLocationPermissionDialog();
            },
          ),

          // NOUVEAU WIDGET - Statut de localisation
          _buildLocationStatus(),

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
                decoration: InputDecoration(
                  hintText: _isProviderMode()
                      ? l10n.searchProject
                      : l10n.searchService,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),

          // TabBar pour les différentes sections
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF142FE2),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF142FE2),
            tabs: _isProviderMode()
                ? [
                    Tab(text: l10n.home),
                    Tab(text: l10n.recent),
                    Tab(text: l10n.nearby),
                  ]
                : [
                    Tab(text: l10n.home),
                    Tab(text: l10n.best),
                    Tab(text: l10n.recent),
                    Tab(text: l10n.nearby),
                  ],
          ),

          // Contenu des tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _isProviderMode()
                  ? [
                      _buildProviderHomeTab(),
                      _buildRecentProjectsTab(),
                      _buildNearbyProjectsTab(),
                    ]
                  : [
                      _buildClientHomeTab(),
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

  // WIDGET AMÉLIORÉ pour les projets à proximité (mode prestataire)
  Widget _buildNearbyProjectsTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Header avec statut de localisation - AMÉLIORÉ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nearbyProjectsTab,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, child) {
                        if (locationProvider.currentPosition != null) {
                          return Text(
                            'Dans un rayon de 15 km • ${_nearbyProjects.length} projets',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          );
                        } else {
                          return Text(
                            'Localisation non disponible',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[600],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Bouton actualiser - NOUVEAU
                  IconButton(
                    onPressed: () async {
                      setState(() {
                        _isLocationLoading = true;
                      });
                      await _loadProjectsData();
                      setState(() {
                        _isLocationLoading = false;
                      });
                    },
                    icon: _isLocationLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh, color: Colors.grey[600]),
                    tooltip: 'Actualiser',
                  ),

                  // Bouton carte
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showMapView = true;
                      });
                    },
                    icon: const Icon(Icons.map, size: 16),
                    label: Text(l10n.map),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF142FE2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Projets à proximité avec badges - AMÉLIORÉ
          _buildVerticalProjectsList(
            _nearbyProjects,
            _nearbyProjects.length,
            l10n.noProjectsAvailableRegion,
            showUrgencyBadge: true, // NOUVEAU
            showDistanceBadge: true, // NOUVEAU
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return Consumer2<NotificationProvider, AuthProvider>(
      builder: (context, notificationProvider, authProvider, child) {
        // 🔒 VÉRIFICATION D'AUTHENTIFICATION
        if (!authProvider.isAuthenticated) {
          return const SizedBox.shrink();
        }
        
        final unreadCount = notificationProvider.unreadCount;
        
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ================== MODE CLIENT ==================

  // Tab d'accueil pour les clients
  Widget _buildClientHomeTab() {
    final l10n = AppLocalizations.of(context)!;

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
                      Text(
                        l10n.findBestProviders,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.bookQualityServices,
                        style: const TextStyle(
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
                        child: Text(l10n.explore),
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
          _buildSectionTitle(l10n.bestServicesWeek),
          _buildHorizontalServicesList(
              _topRatedServices, l10n.noPopularServicesMoment),

          // Annonces récentes
          _buildSectionTitle(l10n.recentAnnouncements),
          _buildHorizontalServicesList(
              _recentServices, l10n.noRecentAnnouncementsAvailable),

          // Meilleurs avis
          _buildSectionTitle(l10n.bestReviews),
          _buildReviewsSection(),

          // Services à proximité
          _buildSectionTitle(l10n.nearbyServices),
          _buildVerticalServicesList(
              _nearbyServices, 3, l10n.noServicesAvailableRegion),

          // Voir tous les services
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/explore');
                },
                icon: const Icon(Icons.explore),
                label: Text(l10n.exploreAllServices),
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

  // ================== MODE PRESTATAIRE ==================

  // Tab d'accueil pour les prestataires
  Widget _buildProviderHomeTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière promotionnelle pour projets
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
                      Text(
                        l10n.discoverNewProjects,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.findClientsDevelopBusiness,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProjectsListScreen(),
                            ),
                          );
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
                        child: Text(l10n.viewProjects),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Statistiques du prestataire
          _buildProviderStats(),

          // Projets récents
          _buildSectionTitle(l10n.recentProjects),
          _buildHorizontalProjectsList(
              _recentProjects, l10n.noRecentProjectsAvailable),

          // Projets à proximité
          _buildSectionTitle(l10n.nearbyServices),
          _buildVerticalProjectsList(
              _nearbyProjects, 3, l10n.noProjectsAvailableRegion),

          // Voir tous les projets
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProjectsListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.work),
                label: Text(l10n.viewAllProjects),
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

  Widget _buildRecentProjectsTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.mostRecentProjects,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildVerticalProjectsList(_recentProjects, _recentProjects.length,
              l10n.noNewProjectsAvailable),
        ],
      ),
    );
  }

  // Statistiques du prestataire
  Widget _buildProviderStats() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.yourStatistics,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isLoadingStats)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.completedServices,
                  _providerStats['prestations_completed_this_month']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                  // ✅ REDIRECTION: Services terminés → Page liste demandes de devis
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuoteRequestsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.inProgress,
                  _providerStats['prestations_in_progress']?.toString() ?? '0',
                  Icons.work,
                  Colors.blue,
                  // ✅ REDIRECTION: En cours → Page des offres
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOffersScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.unreadMessages,
                  _providerStats['unread_messages']?.toString() ?? '0',
                  Icons.message,
                  Colors.orange,
                  // ✅ REDIRECTION: Messages non lus → Page des messages
                  onTap: () {
                    Navigator.pushNamed(context, '/messages');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.offreEnCours,
                  _providerStats['pending_offers']?.toString() ?? '0',
                  Icons.account_balance_wallet,
                  Colors.green,
                  // ✅ REDIRECTION: Offres en attente → Page des offres
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOffersScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  l10n.averageRating,
                  (_providerStats['avg_rating'] ?? 0.0).toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                  // ✅ REDIRECTION: Note moyenne → Page des avis (profil)
                  onTap: () {
                    // Navigator.pushNamed(context, '/profile');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReviewsScreen(),
                      ),
                    );
                  },
                  
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  l10n.totalReviews, 
                  _providerStats['total_reviews']?.toString() ?? '0',
                  Icons.rate_review,
                  Colors.purple,
                  // ✅ REDIRECTION: Total des avis → Page des avis (profil)
                  onTap: () {
                    // Navigator.pushNamed(context, '/profile');
                    // Navigator.pushNamed(context, '/profile');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReviewsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title, 
    String value, 
    IconData icon, 
    Color color, {
    VoidCallback? onTap, // ✅ NOUVEAU PARAMÈTRE OPTIONNEL
  }) {
    Widget cardContent = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              // ✅ AJOUT d'une icône de navigation si cliquable
              if (onTap != null) ...[
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );

    // ✅ Envelopper dans GestureDetector seulement si cliquable
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }

  // ================== WIDGETS COMMUNS ==================

  // Tab des meilleurs services (mode client uniquement)
  Widget _buildTopRatedTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.bestProvidersByRating,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildVerticalServicesList(_topRatedServices,
              _topRatedServices.length, l10n.noWellRatedServicesMoment),
        ],
      ),
    );
  }

  // Tab des services récents (mode client uniquement)
  Widget _buildRecentTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.mostRecentAnnouncements,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildVerticalServicesList(_recentServices, _recentServices.length,
              l10n.noNewAnnouncementsAvailable),
        ],
      ),
    );
  }

  // Tab des services à proximité (mode client uniquement)
  Widget _buildNearbyTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.nearbyServicesTab,
                style: const TextStyle(
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
                label: Text(l10n.map),
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
          _buildVerticalServicesList(_nearbyServices, _nearbyServices.length,
              l10n.noServicesAvailableRegion),
        ],
      ),
    );
  }

  // NOUVELLE MÉTHODE pour calculer la distance approximative
  String? _calculateDistance(ClientProject project) {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    if (locationProvider.currentPosition == null ||
        project.latitude == null ||
        project.longitude == null) {
      return null;
    }

    try {
      final distance = Geolocator.distanceBetween(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
        project.latitude!,
        project.longitude!,
      );

      if (distance < 1000) {
        return '${distance.round()}m';
      } else {
        return '${(distance / 1000).toStringAsFixed(1)}km';
      }
    } catch (e) {
      return null;
    }
  }

  /// Widget pour afficher les catégories (mode client uniquement)
  Widget _buildCategories() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Text(
            l10n.popularCategories,
            style: const TextStyle(
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

            if (categoryProvider.categories.isEmpty) {
              return _buildEmptyState(
                icon: Icons.category_outlined,
                message: l10n.noCategoriesAvailableMoment,
                height: 120,
              );
            }

            final categories = categoryProvider.categories;

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
                            categoryName: category.getLocalizedName(
                                Provider.of<LanguageProvider>(context,
                                        listen: false)
                                    .currentLocale
                                    .languageCode),
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
                            category.getLocalizedName(
                                Provider.of<LanguageProvider>(context,
                                        listen: false)
                                    .currentLocale
                                    .languageCode),
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
            child: Text(
              l10n.viewAllCategories,
              style: const TextStyle(
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
  Widget _buildHorizontalServicesList(
      List<Service> services, String emptyMessage) {
    final l10n = AppLocalizations.of(context)!;

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
                    ServiceImage(
                      imageUrl: service.imageUrl,
                      width: 160,
                      height: 100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
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
                                ? l10n.onQuote
                                : '${service.price.toInt()} AOA',
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

  // Widget pour afficher une liste horizontale de projets
  Widget _buildHorizontalProjectsList(
      List<ClientProject> projects, String emptyMessage) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (projects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.work_outline,
        message: emptyMessage,
        height: 220,
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        scrollDirection: Axis.horizontal,
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
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
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône du projet
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF142FE2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.work,
                          color: Color(0xFF142FE2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Titre du projet
                      Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Localisation
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              project.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Budget
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          project.budgetDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Statut
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: project.status == 'open'
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          project.status == 'open' ? l10n.open : l10n.closed,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: project.status == 'open'
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget pour afficher une liste verticale de services
  Widget _buildVerticalServicesList(
      List<Service> services, int limit, String emptyMessage) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (services.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        message: emptyMessage,
        height: 200,
      );
    }

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
                    providerId: service.provider_id,
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
                  ServiceImage(
                    imageUrl: service.imageUrl,
                    width: 80,
                    height: 80,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
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
                              ? AppLocalizations.of(context)!.onQuote
                              : '${service.price.toInt()} ${AppLocalizations.of(context)!.fcfa}',
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
                                  providerId: service.provider_id,
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
                          child: Text(
                            AppLocalizations.of(context)!.view,
                            style: const TextStyle(
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

  // WIDGET AMÉLIORÉ pour afficher une liste verticale de projets avec badges
  Widget _buildVerticalProjectsList(
    List<ClientProject> projects,
    int limit,
    String emptyMessage, {
    bool showUrgencyBadge = false,
    bool showDistanceBadge = false,
  }) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (projects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.work_off,
        message: emptyMessage,
        height: 200,
      );
    }

    final displayProjects =
        projects.length > limit ? projects.sublist(0, limit) : projects;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayProjects.length,
      itemBuilder: (context, index) {
        final project = displayProjects[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProjectDetailScreen(projectId: project.id),
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
                // Bordure spéciale pour les projets urgents
                border: showUrgencyBadge && project.urgency == 'very_high'
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF142FE2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.work,
                            color: Color(0xFF142FE2),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      project.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Badge d'urgence - NOUVEAU
                                  if (showUrgencyBadge &&
                                      project.urgency == 'very_high')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'URGENT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${AppLocalizations.of(context)!.by} ${project.clientName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: project.status == 'open'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: project.status == 'open'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          child: Text(
                            project.status == 'open'
                                ? AppLocalizations.of(context)!.open
                                : AppLocalizations.of(context)!.closed,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: project.status == 'open'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      project.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        // Badge de distance (si disponible) - NOUVEAU
                        if (showDistanceBadge)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.near_me,
                                    size: 12, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  _calculateDistance(project) ?? 'Proche',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF142FE2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            project.budgetDisplay,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF142FE2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget pour afficher la section des meilleurs avis
  Widget _buildReviewsSection() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final reviews = _topReviews;

        if (reviewProvider.isLoading) {
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (reviews.isEmpty) {
          return _buildEmptyState(
            icon: Icons.rate_review_outlined,
            message: AppLocalizations.of(context)!.noReviewsAvailableMoment,
            height: 280,
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];

              return GestureDetector(
                onTap: () {
                  if (review.serviceId != null && review.providerId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailScreen(
                          serviceId: review.serviceId!,
                          providerId: review.providerId,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            AppLocalizations.of(context)!.serviceNotAvailable),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 320,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  const Color(0xFF142FE2).withOpacity(0.1),
                              child: Text(
                                review.clientName.isNotEmpty
                                    ? review.clientName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF142FE2),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.clientName.isNotEmpty
                                        ? review.clientName
                                        : 'Utilisateur anonyme',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getClientCompanyName(review),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade300,
                                    Colors.amber.shade500,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    review.rating.toString(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF142FE2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _getReviewTitle(review),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF142FE2),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: Color(0xFF142FE2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Text(
                            review.comment.isNotEmpty
                                ? review.comment
                                : 'Excellent service, je recommande vivement !',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getReviewDate(review),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            Icon(
                              Icons.touch_app,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Widget générique pour afficher un état vide
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(actionText),
              ),
            ],
          ],
        ),
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

  // Méthode pour obtenir le nom de l'entreprise du CLIENT (celui qui écrit l'avis)
  String _getClientCompanyName(Review review) {
    final l10n = AppLocalizations.of(context)!;

    if (review.clientCompanyName != null &&
        review.clientCompanyName!.isNotEmpty) {
      return review.clientCompanyName!;
    }

    return l10n.genericClientType;
  }

  String _getReviewTitle(Review review) {
    final l10n = AppLocalizations.of(context)!;

    if (review.reviewTitle != null && review.reviewTitle!.isNotEmpty) {
      return review.reviewTitle!;
    }

    return l10n.genericReviewTitle;
  }

  String _getReviewDate(Review review) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(review.createdAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return l10n.monthsAgo(months);
    } else if (difference.inDays > 0) {
      return l10n.daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return l10n.hoursAgo(difference.inHours);
    } else {
      return l10n.recently;
    }
  }
}
