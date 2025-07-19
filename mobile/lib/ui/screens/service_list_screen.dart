// lib/ui/screens/service_list_screen.dart
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
    
    // Charger les sous-catégories et services au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subcategoryProvider = Provider.of<SubcategoryProvider>(context, listen: false);
      subcategoryProvider.fetchSubcategories(widget.categoryId);
      
      // Charger tous les services de la catégorie par défaut
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      serviceProvider.fetchServicesByCategory(widget.categoryId);
    });
  }
  String _getLocalizedAllText() {
    final languageCode = Provider.of<LanguageProvider>(context, listen: false).currentLocale.languageCode;
    
    switch (languageCode) {
      case 'en':
        return 'All';
      case 'fr':
        return 'Tous';
      case 'pt':
      default:
        return 'Todos';
    }
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
                        widget.categoryName,
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
            
            // Sous-catégories (tabs) avec défilement horizontal
            Consumer<SubcategoryProvider>(
              builder: (context, subcategoryProvider, child) {
                final subcategories = subcategoryProvider.subcategories;
                
                if (subcategoryProvider.isLoading) {
                  return const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (subcategories.isEmpty) {
                  return const SizedBox(height: 48);
                }
                
                // Utiliser un SingleChildScrollView horizontal pour le défilement
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
                        // Ajouter l'option "Tous" comme premier élément
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSubcategoryIndex = -1; // -1 pour "Tous"
                            });
                            
                            // Charger tous les services de la catégorie
                            final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
                            serviceProvider.fetchServicesByCategory(widget.categoryId);
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
                        ),
                        // Ensuite, afficher les sous-catégories existantes
                        ...List.generate(subcategories.length, (index) {
                          final subcategory = subcategories[index];
                          return _buildSubcategoryTab(subcategory, index);
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
            
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
                          'Filtres',
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
            
            // Liste des services ou message "Aucun service disponible"
            Expanded(
              child: Consumer<ServiceProvider>(
                builder: (context, serviceProvider, child) {
                  if (serviceProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final services = serviceProvider.services;
                  
                  if (services.isEmpty) {
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
                            'Aucun service disponible dans cette catégorie',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Revenez plus tard ou essayez une autre catégorie',
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
                  
                  // Liste des services en affichage liste ou grille selon _isListView
                  if (_isListView) {
                    // Affichage en liste
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return _buildServiceListItem(service, screenWidth);
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
                        final service = services[index];
                        return _buildServiceGridItem(service);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      
    );
  }
  //
  Widget _buildSubcategoryTab(Subcategory subcategory, int index) {
    final bool isSelected = _selectedSubcategoryIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubcategoryIndex = index;
        });
        
        // Filtrer les services par sous-catégorie
        final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
        serviceProvider.fetchServicesBySubcategory(subcategory.id);
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
  
  // Élément de liste pour les services
  Widget _buildServiceListItem(Service service, double screenWidth) {
    return ServiceCard(
      service: service,
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
    );
  }
  
  // Élément de grille pour les services
  Widget _buildServiceGridItem(Service service) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(
              serviceId: service.id,
              providerId: service.provider_id,            ),
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
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                service.imageUrl,
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
            
            // Info
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
                      const Icon(Icons.star, color: Colors.amber, size: 16),
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
    );
  }
}