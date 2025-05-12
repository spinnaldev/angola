// lib/ui/screens/explore_screen.dart (mise à jour pour utiliser BaseScreen)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../widgets/category_card.dart';
import 'service_list_screen.dart';
import 'base_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charger les catégories au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      currentIndex: 1, // Explorer est sélectionné
      body: _buildExploreContent(),
    );
  }

  Widget _buildExploreContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec logo et icônes
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo.png',
                height: 40,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'LOGO',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  // Naviguer vers l'écran des notifications
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
    );
  }
}