// lib/ui/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/category_card.dart';
import '../widgets/side_menu.dart';
import 'messaging/messages_screen.dart';
import 'service_list_screen.dart';
import 'profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final menuWidth =
        MediaQuery.of(context).size.width * 0.85; // 85% de la largeur

    return Scaffold(
      body: Stack(
        children: [
          // Contenu principal
          Positioned.fill(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo - utiliser un logo local
                        Image.asset(
                          'assets/images/logo.png',
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                            'LOGO',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            // Naviguer vers l'écran des notifications
                            Navigator.pushNamed(context, '/notifications');
                          },
                          child: Stack(
                            children: [
                              const Icon(Icons.notifications_none, size: 28),
                              if (Provider.of<NotificationProvider>(context).unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 12,
                                      minHeight: 12,
                                    ),
                                    child: Text(
                                      '${Provider.of<NotificationProvider>(context).unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Champ de recherche
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Recherche de services...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 15),
                        ),
                      ),
                    ),
                  ),

                  // Texte "Tous les services"
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 15, 20, 5),
                    child: Text(
                      'Tous les services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Grille des catégories
                  Expanded(
                    child: Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        if (categoryProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (categoryProvider.categories.isEmpty) {
                          return const Center(child: Text('Aucune catégorie disponible'));
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: categoryProvider.categories.length,
                            itemBuilder: (context, index) {
                              final category = categoryProvider.categories[index];
                              // Récupérer le nombre de services pour cette catégorie
                              final serviceCount = categoryProvider.getServiceCount(category.id);
                              
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
                                child: CategoryCard(
                                  category: category,
                                  serviceCount: serviceCount,
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

      // Barre de navigation inférieure
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0, // Index "Explorer"
        onTap: (index) {
          if (index == 0) {
            // Déjà sur Explorer
          } else if (index == 1) {
            // Naviguer vers Messages
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessagesScreen()),
            );
          } else if (index == 2) {
            // Ouvrir le menu latéral pour le profil
            setState(() {
              _isMenuOpen = true;
            });
          }
        },
      ),
    );
  }
}
