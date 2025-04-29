// lib/ui/screens/service_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/service.dart';
import '../../core/models/subcategory.dart';
import '../../providers/service_provider.dart';
import '../../providers/subcategory_provider.dart';
import '../widgets/service_card.dart';
import 'filter_screen.dart';
import 'service_detail_screen.dart';

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

class _ServiceListScreenState extends State<ServiceListScreen> with SingleTickerProviderStateMixin {
  int _selectedSubcategoryIndex = 0;
  bool _isListView = false; // true pour liste, false pour grille
  
  @override
  void initState() {
    super.initState();
    
    // Charger les sous-catégories et services au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subcategoryProvider = Provider.of<SubcategoryProvider>(context, listen: false);
      subcategoryProvider.fetchSubcategories(widget.categoryId);
      
      // Charger tous les services de la catégorie par défaut
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      serviceProvider.fetchServicesByCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Barre d'en-tête avec titre de catégorie et recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.categoryName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // Action de recherche
                    },
                  ),
                ],
              ),
            ),
            
            // Sous-catégories en tabs
            Consumer<SubcategoryProvider>(
              builder: (context, subcategoryProvider, child) {
                final subcategories = subcategoryProvider.subcategories;
                
                if (subcategoryProvider.isLoading) {
                  return const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (subcategories.isEmpty) {
                  return const SizedBox(height: 50);
                }
                
                return Container(
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 5),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: subcategories.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSubcategoryIndex = index;
                          });
                          
                          // Filtrer les services par sous-catégorie
                          final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
                          serviceProvider.fetchServicesBySubcategory(subcategories[index].id);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedSubcategoryIndex == index 
                                    ? const Color(0xFF142FE2)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            subcategories[index].name,
                            style: TextStyle(
                              color: _selectedSubcategoryIndex == index 
                                  ? const Color(0xFF142FE2)
                                  : Colors.black,
                              fontWeight: _selectedSubcategoryIndex == index
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            
            // Barre de filtres et changement de vue
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: const [
                          Icon(Icons.tune, size: 18),
                          SizedBox(width: 4),
                          Text('Filtres'),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Bouton de changement de vue (liste/grille)
                  IconButton(
                    icon: Icon(_isListView ? Icons.grid_view : Icons.view_list),
                    onPressed: () {
                      setState(() {
                        _isListView = !_isListView;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Liste des services
            Expanded(
              child: Consumer<ServiceProvider>(
                builder: (context, serviceProvider, child) {
                  if (serviceProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final services = serviceProvider.services;
                  
                  if (services.isEmpty) {
                    return const Center(child: Text('Aucun service disponible'));
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
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
                          child: ServiceCard(service: service),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      // Barre de navigation inférieure
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF142FE2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explorer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}