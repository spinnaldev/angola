// lib/ui/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/category_grid_card.dart';
import '../widgets/side_menu.dart';
import 'service_list_screen.dart';
import 'profile_screen.dart';
import '../common/bottom_navigation.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isMenuOpen = false;
  
  @override
  void initState() {
    super.initState();
    // Charger les catégories au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      
      // Vérifier si l'utilisateur est connecté
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        authProvider.getCurrentUser();
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      // Déjà sur Explorer, ne rien faire
    } else if (index == 1) {
      // Navigation vers Messages
    } else if (index == 2) {
      // Ouvrir le menu latéral quand on appuie sur Profil
      setState(() {
        _isMenuOpen = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = MediaQuery.of(context).size.width * 0.85; // 85% de la largeur
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Contenu principal
          Positioned.fill(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec logo et icône de notification
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LOGO',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Icône de notification au lieu du profil
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {
                            // Action pour les notifications
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Champ de recherche
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Recherche de services...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Texte "Tous les services"
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Text(
                      'Tous les services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // Grille des catégories (style image 2)
                  Expanded(
                    child: Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        if (categoryProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (categoryProvider.categoriesWithCount.isEmpty) {
                          return const Center(child: Text('Aucune catégorie disponible'));
                        }
                        
                        // Affichage en grille avec 2 catégories par ligne comme dans l'image 2
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // 2 éléments par ligne
                              childAspectRatio: 1.0, // Ratio 1:1 pour forme carrée
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: categoryProvider.categoriesWithCount.length,
                            itemBuilder: (context, index) {
                              final categoryWithCount = categoryProvider.categoriesWithCount[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ServiceListScreen(
                                        categoryId: categoryWithCount.category.id,
                                        categoryName: categoryWithCount.category.name,
                                      ),
                                    ),
                                  );
                                },
                                child: CategoryGridCard(
                                  category: categoryWithCount.category,
                                  serviceCount: categoryWithCount.serviceCount,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Superposition semi-transparente quand le menu est ouvert
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMenuOpen = false;
                  });
                },
                child: Container(
                  color: Colors.black54, // Fond semi-transparent
                ),
              ),
            ),
          
          // Menu latéral avec animation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isMenuOpen ? 0 : -menuWidth, // Position depuis la droite
            top: 0,
            bottom: 0,
            width: menuWidth,
            child: GestureDetector(
              // Empêche les taps sur le menu de fermer la superposition
              onTap: () {},
              child: SideMenu(
                onClose: () {
                  setState(() {
                    _isMenuOpen = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      
      // Utilisation du composant BottomNavigationBar
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0, // Explorer par défaut
        onTap: _handleNavigation,
      ),
    );
  }
}