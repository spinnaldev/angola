// lib/ui/screens/service_list_screen.dart - VERSION CORRIGÉE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/service.dart';
import '../../core/models/subcategory.dart';
import '../../providers/language_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/subcategory_provider.dart';
import '../common/bottom_navigation.dart';
import 'base_screen.dart';
import 'filter_screen.dart';
import 'service_detail_screen.dart';
import 'profile_screen.dart';
import '../widgets/service_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServiceListScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const ServiceListScreen({
    Key? key, 
    required this.categoryId, 
    required this.categoryName,
  }) : super(key: key);

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  int _selectedSubcategoryIndex = 0;
  bool _isListView = true; // true pour liste (par défaut)
  late ScrollController _tabScrollController;
  
  @override
  void initState() {
    super.initState();
    _tabScrollController = ScrollController();
    _selectedSubcategoryIndex = -1; // -1 représente "Tous"
    
    // ✅ CORRECTION 1: Debug et chargement sécurisé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🚀 Initialisation ServiceListScreen pour catégorie: ${widget.categoryId}');
      
      try {
        final subcategoryProvider = Provider.of<SubcategoryProvider>(context, listen: false);
        subcategoryProvider.fetchSubcategories(widget.categoryId);
        
        final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
        serviceProvider.fetchServicesByCategory(widget.categoryId).then((_) {
          print('✅ Services chargés: ${serviceProvider.services?.length ?? 0}');
        }).catchError((e) {
          print('❌ Erreur chargement services: $e');
        });
      } catch (e) {
        print('❌ Erreur dans initState: $e');
      }
    });
  }
  
  String _getLocalizedAllText() {
    final l10n = AppLocalizations.of(context)!;
    return l10n.allServices; 
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      currentIndex: 1, // Explorer est sélectionné
      body: _buildServiceListContent(),
    );
  }
  
  Widget _buildServiceListContent(){
    final screenWidth = MediaQuery.of(context).size.width;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Barre d'en-tête avec titre de catégorie et boutons (retour et recherche)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.servicesInCategory(widget.categoryName),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, size: 24),
                    onPressed: () {
                      // Action de recherche
                    },
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            
            // Séparateur sous la barre d'en-tête (ligne très fine)
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            
            // ✅ CORRECTION 2: Subcategories avec protection d'erreur
            _buildSubcategoriesSection(),
            
            // Barre de filtres et changement de vue
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Bouton de filtres
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FilterScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.tune, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          l10n.filters,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Bouton de changement de vue (liste/grille)
                  IconButton(
                    icon: Icon(
                      _isListView ? Icons.grid_view : Icons.view_list,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isListView = !_isListView;
                      });
                    },
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            
            // ✅ CORRECTION 3: Services avec protection complète
            Expanded(
              child: _buildServicesSection(screenWidth),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NOUVELLE MÉTHODE: Section des sous-catégories avec protection
  Widget _buildSubcategoriesSection() {
    return Consumer<SubcategoryProvider>(
      builder: (context, subcategoryProvider, child) {
        try {
          // ✅ Protection 1: Vérifier l'état de chargement
          if (subcategoryProvider.isLoading) {
            return const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          // ✅ Protection 2: Vérifier les subcategories
          final subcategories = subcategoryProvider.subcategories ?? [];
          
          if (subcategories.isEmpty) {
            return const SizedBox(height: 48);
          }
          
          // ✅ Protection 3: Construction sécurisée
          return Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _tabScrollController,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Option "Tous"
                  _buildAllTab(),
                  // Sous-catégories
                  ...subcategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final subcategory = entry.value;
                    return _buildSubcategoryTab(subcategory, index);
                  }).toList(),
                ],
              ),
            ),
          );
        } catch (e) {
          print('❌ Erreur dans _buildSubcategoriesSection: $e');
          return const SizedBox(height: 48);
        }
      },
    );
  }

  // ✅ NOUVELLE MÉTHODE: Tab "Tous" séparé
  Widget _buildAllTab() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubcategoryIndex = -1;
        });
        
        try {
          final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
          serviceProvider.fetchServicesByCategory(widget.categoryId);
        } catch (e) {
          print('Erreur chargement tous les services: $e');
        }
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _selectedSubcategoryIndex == -1 ? const Color(0xFF142FE2) : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          _getLocalizedAllText(),
          style: TextStyle(
            color: _selectedSubcategoryIndex == -1 ? const Color(0xFF142FE2) : Colors.black,
            fontWeight: _selectedSubcategoryIndex == -1 ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ✅ NOUVELLE MÉTHODE: Section des services avec protection complète
  Widget _buildServicesSection(double screenWidth) {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, child) {
        try {
          // ✅ Protection 1: État de chargement
          if (serviceProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // ✅ Protection 2: Vérifier si services est null
          final services = serviceProvider.services;
          
          if (services == null) {
            print('⚠️ Services est null dans serviceProvider');
            return _buildEmptyState('Services non disponibles');
          }
          
          // ✅ Protection 3: Filtrer les services valides
          final validServices = services.where((service) => service != null).toList();
          
          print('🔍 Debug: ${validServices.length} services valides sur ${services.length} totaux');
          
          if (validServices.isEmpty) {
            return _buildEmptyState('Aucun service disponible dans cette catégorie');
          }
          
          // ✅ Protection 4: Affichage sécurisé selon le mode
          return _buildServicesList(validServices, screenWidth);
          
        } catch (e) {
          print('❌ Erreur dans _buildServicesSection: $e');
          return _buildEmptyState('Erreur de chargement des services');
        }
      },
    );
  }

  // ✅ NOUVELLE MÉTHODE: Liste des services avec protection
  Widget _buildServicesList(List<Service> services, double screenWidth) {
    try {
      if (_isListView) {
        // Affichage en liste
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: services.length,
          itemBuilder: (context, index) {
            // ✅ Protection d'index
            if (index < 0 || index >= services.length) {
              return const SizedBox.shrink();
            }
            
            final service = services[index];
            
            // ✅ Protection de service null
            if (service == null) {
              return const SizedBox.shrink();
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildServiceListItem(service, screenWidth),
            );
          },
        );
      } else {
        // Affichage en grille
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            // ✅ Protection d'index
            if (index < 0 || index >= services.length) {
              return const SizedBox.shrink();
            }
            
            final service = services[index];
            
            // ✅ Protection de service null
            if (service == null) {
              return const SizedBox.shrink();
            }
            
            return _buildServiceGridItem(service);
          },
        );
      }
    } catch (e) {
      print('❌ Erreur dans _buildServicesList: $e');
      return _buildEmptyState('Erreur d\'affichage des services');
    }
  }

  // ✅ NOUVELLE MÉTHODE: État vide standardisé
  Widget _buildEmptyState(String message) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noServicesAvailable,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tryAnotherCategory,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubcategoryTab(Subcategory subcategory, int index) {
    final bool isSelected = _selectedSubcategoryIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubcategoryIndex = index;
        });
        
        try {
          // Filtrer les services par sous-catégorie
          final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
          serviceProvider.fetchServicesBySubcategory(subcategory.id);
        } catch (e) {
          print('Erreur chargement sous-catégorie: $e');
        }
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF142FE2) : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          subcategory.getLocalizedName(
            Provider.of<LanguageProvider>(context, listen: false).currentLocale.languageCode
          ),
          style: TextStyle(
            color: isSelected ? const Color(0xFF142FE2) : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  // ✅ CORRECTION 4: Service list item avec protection
  Widget _buildServiceListItem(Service service, double screenWidth) {
    try {
      // ✅ Vérification supplémentaire du service
      if (service == null) {
        return const SizedBox(height: 100); // Maintenir la hauteur pour éviter les erreurs de layout
      }

      return ServiceCard(
        service: service,
        onTap: () {
          // ✅ PROTECTION : Vérifier que les IDs ne sont pas null avant navigation
          final serviceId = service.id;
          final providerId = service.provider_id;
          
          if (serviceId == null || providerId == null) {
            // Afficher un message d'erreur si les données sont manquantes
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Impossible d\'ouvrir ce service - données incomplètes'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(
                serviceId: serviceId,
                providerId: providerId,
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('❌ Erreur dans _buildServiceListItem: $e');
      return Container(
        height: 100,
        child: const Center(
          child: Text('Service indisponible'),
        ),
      );
    }
  }
  
  // ✅ CORRECTION 5: Service grid item avec protection
  Widget _buildServiceGridItem(Service service) {
    try {
      // ✅ Vérification supplémentaire du service
      if (service == null) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('Service indisponible'),
          ),
        );
      }

      return GestureDetector(
        onTap: () {
          final serviceId = service.id;
          final providerId = service.provider_id;
          
          if (serviceId == null || providerId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Impossible d\'ouvrir ce service - données incomplètes'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(
                serviceId: serviceId,
                providerId: providerId,
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
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec protection
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  service.imageUrl ?? '',
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              ),
              
              // Info avec protection
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title ?? 'Service sans titre',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.businessType ?? 'Entreprise',
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          (service.rating ?? 0.0).toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "(${service.reviewCount ?? 0})",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (service.priceType ?? 'quote') == 'quote' 
                        ? 'Sur devis' 
                        : '${(service.price ?? 0.0).toInt()} AOA',
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
      );
    } catch (e) {
      print('❌ Erreur dans _buildServiceGridItem: $e');
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Erreur service'),
        ),
      );
    }
  }
}