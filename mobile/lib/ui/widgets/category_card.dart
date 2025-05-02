// lib/ui/widgets/category_card.dart
import 'package:flutter/material.dart';
import '../../core/models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final int serviceCount;
  
  const CategoryCard({
    Key? key, 
    required this.category,
    this.serviceCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond (maintenant depuis les assets locaux)
          _buildBackgroundImage(),
          
          // Superposition sombre pour assurer la lisibilité du texte
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          
          // Informations de la catégorie
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black45,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
                // Affichage du nombre de services
                // if (serviceCount > 0)
                  Text(
                    '$serviceCount service${serviceCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black45,
                          offset: Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Méthode pour déterminer quelle image afficher
  Widget _buildBackgroundImage() {
    // Si c'est une image locale (commençant par 'assets/')
    if (category.imageUrl.startsWith('assets/')) {
      return Image.asset(
        category.imageUrl,
        fit: BoxFit.cover,
      );
    } 
    // Sinon, utiliser une image par défaut basée sur l'ID de la catégorie
    else {
      return Image.asset(
        'assets/images/categories/category_${category.id % 10}.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Image de secours si l'image spécifique n'existe pas
          return Image.asset(
            'assets/images/categories/default.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Si même l'image par défaut échoue, afficher un placeholder coloré
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              );
            },
          );
        },
      );
    }
  }
}