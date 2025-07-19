import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/category_provider.dart';
import '../../providers/language_provider.dart';
import '../widgets/category_card.dart';
import 'service_list_screen.dart';
import 'base_screen.dart';
import 'search_results_screen.dart';

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
  void _performSearch() {
    final query = _searchController.text.trim();
    
    print('🔍 Recherche ExploreScreen: "$query"'); // Debug
    
    if (query.isNotEmpty) {
      print('✅ Navigation vers SearchResultsScreen (services)'); // Debug
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            query: query,
            type: 'services', // Explorer = toujours services
          ),
        ),
      );
    } else {
      print('⚠️ Recherche vide'); // Debug
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un terme de recherche'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      currentIndex: 1, // Explorer est sélectionné
      body: _buildExploreContent(),
    );
  }

  Widget _buildExploreContent() {
    final l10n = AppLocalizations.of(context)!;
    
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
                width: 80,
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
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //   child: Container(
        //     height: 50,
        //     decoration: BoxDecoration(
        //       color: Colors.grey[200],
        //       borderRadius: BorderRadius.circular(8),
        //     ),
        //     child: TextField(
        //       controller: _searchController,
        //       decoration: InputDecoration(
        //         hintText: l10n.searchForServices,
        //         prefixIcon: const Icon(Icons.search, color: Colors.grey),
        //         border: InputBorder.none,
        //         contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        //       ),
        //     ),
        //   ),
        // ),

        
        // Container(
        //   height: 50,
        //   decoration: BoxDecoration(
        //     color: Colors.grey[200],
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   child: TextField(
        //     controller: _searchController,
        //     decoration: InputDecoration(
        //       hintText: l10n.searchForServices,
        //       prefixIcon: const Icon(Icons.search, color: Colors.grey),
        //       // ✅ AJOUT D'UN BOUTON DE RECHERCHE
        //       suffixIcon: IconButton(
        //         icon: const Icon(Icons.arrow_forward, color: Colors.grey),
        //         onPressed: _performSearch,
        //       ),
        //       border: InputBorder.none,
        //       contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        //     ),
        //     // ✅ AJOUT DE onSubmitted
        //     onSubmitted: (_) => _performSearch(),
        //   ),
        // ),

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
                hintText: l10n.searchForServices,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
        ),

        // Texte "Tous les services"
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
          child: Text(
            l10n.allServices,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Grille des catégories en mosaïque
        Expanded(
          child: Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              if (categoryProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (categoryProvider.categories.isEmpty) {
                return Center(
                  child: Text(l10n.noCategoriesAvailable),
                );
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  itemCount: categoryProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = categoryProvider.categories[index];
                    // Récupérer le nombre de services pour cette catégorie
                    final serviceCount = categoryProvider.getServiceCount(category.id);
                    
                    // Déterminer la hauteur en fonction de l'index pour créer un effet mosaïque
                    final double height = _getCategoryHeight(index);
                    
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceListScreen(
                              categoryId: category.id,
                              categoryName: category.getLocalizedName(
                                Provider.of<LanguageProvider>(context, listen: false).currentLocale.languageCode
                              ),
                            ),
                          ),
                        );
                      },
                      child: SizedBox(
                        height: height,
                        child: CategoryCard(
                          category: category,
                          serviceCount: serviceCount,
                        ),
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
  
  // Méthode pour calculer la hauteur de chaque catégorie en fonction de l'index
  double _getCategoryHeight(int index) {
    // Alternance de hauteurs pour créer un effet mosaïque comme dans l'image 1
    // Pattern basé sur la première capture d'écran
    switch (index % 6) {
      case 0: return 250.0; // Premier élément (Maison & Construction)
      case 1: return 210.0; // Deuxième élément (Bien-être & Beauté)
      case 2: return 210.0; // Troisième élément (Événements & Artistiques)
      case 3: return 290.0; // Quatrième élément (Transports & Logistiques)
      case 4: return 230.0; // Cinquième élément
      case 5: return 250.0; // Sixième élément
      default: return 180.0;
    }
  }
}