// lib/ui/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/side_menu.dart';
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
    final menuWidth = MediaQuery.of(context).size.width * 0.85; // 85% de la largeur
    
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
                        const Text(
                          'LOGO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isMenuOpen = true;
                            });
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: authProvider.currentUser?.profilePicture != null && 
                                          authProvider.currentUser!.profilePicture!.isNotEmpty
                                ? NetworkImage(authProvider.currentUser!.profilePicture!)
                                : null,
                            child: authProvider.currentUser?.profilePicture == null || 
                                  authProvider.currentUser!.profilePicture!.isEmpty
                                ? Text(
                                    authProvider.currentUser?.firstName.isNotEmpty == true 
                                      ? authProvider.currentUser!.firstName[0] 
                                      : 'U',
                                    style: const TextStyle(fontSize: 14),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Champ de recherche
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
                                child: CategoryCard(category: category),
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
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: const Color(0xFF4B39EF), // Bleu plus précis
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent, // Transparent pour éviter le fond gris
          elevation: 0, // Supprime l'ombre par défaut
          type: BottomNavigationBarType.fixed, // Fixed pour un comportement constant
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 24),
              label: 'Explorer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 24),
              label: 'Message',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 24),
              label: 'Profil',
            ),
          ],
          onTap: (index) {
            if (index == 0) {
              // Déjà sur Explorer
            } else if (index == 1) {
              // Navigation vers Messages
            } else if (index == 2) {
              // Navigation vers Profil
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }
          },
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: 0,
      //   selectedItemColor: const Color(0xFF142FE2),
      //   unselectedItemColor: Colors.grey,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.search),
      //       label: 'Explorer',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.chat_bubble_outline),
      //       label: 'Message',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.person_outline),
      //       label: 'Profil',
      //     ),
      //   ],
      //   onTap: (index) {
      //     if (index == 0) {
      //       // Déjà sur Explorer
      //     } else if (index == 1) {
      //       // Navigation vers Messages
      //     } else if (index == 2) {
      //       // Navigation vers Profil
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (context) => const ProfileScreen()),
      //       );
      //     }
      //   },
      // ),
    );
  }
}