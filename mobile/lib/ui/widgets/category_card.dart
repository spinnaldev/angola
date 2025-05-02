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
          // Image de fond avec meilleure gestion des erreurs
          _buildNetworkImage(),
          
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
          
          // Texte de la catégorie avec le nombre de services
          Positioned(
            left: 10,
            right: 10, // Pour éviter le débordement
            bottom: 10,
            child: _buildCategoryText(),
          ),
        ],
      ),
    );
  }

  // Optimisation de l'affichage des images réseau
  Widget _buildNetworkImage() {
    // Image par défaut en cas d'erreur
    final fallbackWidget = Container(
      color: _getCategoryColor(),
      child: Center(
        child: Icon(
          _getCategoryIcon(),
          size: 40,
          color: Colors.white,
        ),
      ),
    );
    
    // Si l'URL est vide, utiliser l'image de secours
    if (category.imageUrl.isEmpty) {
      return fallbackWidget;
    }

    // Essayer de charger l'image depuis l'URL avec un meilleur gestionnaire d'erreurs
    return Image.network(
      category.imageUrl,
      fit: BoxFit.cover,
      // Afficher un indicateur de chargement pendant le téléchargement
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: _getCategoryColor().withOpacity(0.3),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: _getCategoryColor(),
            ),
          ),
        );
      },
      // En cas d'erreur, afficher une couleur et une icône représentant la catégorie
      errorBuilder: (context, error, stackTrace) {
        print('Erreur de chargement d\'image: $error pour la catégorie ${category.name}');
        // Réessayer avec une autre URL si disponible
        if (category.imageUrl.contains('unsplash.com')) {
          // Utiliser une URL de repli pour les images Unsplash
          return Image.network(
            // URL de repli - utiliser une URL générique pour chaque type de catégorie
            'https://source.unsplash.com/300x200/?${_getCategoryKeyword()}',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Si même l'image de repli échoue, afficher le fallback widget
              return fallbackWidget;
            },
          );
        }
        return fallbackWidget;
      },
    );
  }

  // Méthode pour obtenir un mot-clé de recherche par catégorie
  String _getCategoryKeyword() {
    switch(category.id) {
      case 1: return 'construction,house';
      case 2: return 'beauty,spa';
      case 3: return 'event,party';
      case 4: return 'transport,logistics';
      case 5: return 'health,wellness';
      case 6: return 'professional,service';
      case 7: return 'digital,technology';
      case 8: return 'animal,pet';
      case 9: return 'service,miscellaneous';
      default: return 'service';
    }
  }

  // Méthode pour obtenir une couleur par catégorie
  Color _getCategoryColor() {
    switch(category.id) {
      case 1: return Colors.blue[800]!;
      case 2: return Colors.purple[300]!;
      case 3: return Colors.red[400]!;
      case 4: return Colors.blueGrey[700]!;
      case 5: return Colors.pink[300]!;
      case 6: return Colors.indigo[500]!;
      case 7: return Colors.cyan[700]!;
      case 8: return Colors.amber[600]!;
      case 9: return Colors.green[600]!;
      default: return Colors.grey[700]!;
    }
  }

  // Obtenir l'icône appropriée pour la catégorie
  IconData _getCategoryIcon() {
    switch(category.id) {
      case 1: return Icons.home;
      case 2: return Icons.spa;
      case 3: return Icons.event;
      case 4: return Icons.local_shipping;
      case 5: return Icons.favorite;
      case 6: return Icons.work;
      case 7: return Icons.computer;
      case 8: return Icons.pets;
      case 9: return Icons.miscellaneous_services;
      default: return Icons.category;
    }
  }

  // Méthode pour construire le texte de la catégorie
  Widget _buildCategoryText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nom de la catégorie avec retour à la ligne automatique
        Text(
          "${category.name} (${serviceCount})",
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
          maxLines: 2, // Autoriser jusqu'à 2 lignes
          overflow: TextOverflow.ellipsis, // Ajouter ... si le texte est trop long
        ),
      ],
    );
  }
}