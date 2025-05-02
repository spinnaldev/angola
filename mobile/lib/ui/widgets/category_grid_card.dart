// lib/ui/widgets/category_grid_card.dart
import 'package:flutter/material.dart';
import '../../core/models/category.dart';

class CategoryGridCard extends StatelessWidget {
  final Category category;
  final int serviceCount;
  
  const CategoryGridCard({
    Key? key, 
    required this.category,
    required this.serviceCount,
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
          // Image de fond avec gestion des images locales
          _buildLocalImage(),
          
          // Superposition du dégradé
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
          
          // Affichage de l'icône centrée dans la partie supérieure
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: Icon(
                _getCategoryIcon(),
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          
          // Texte de la catégorie et nombre de services en bas
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '($serviceCount)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Méthode pour construire l'image locale en fonction de la catégorie
  Widget _buildLocalImage() {
    return Container(
      decoration: BoxDecoration(
        color: _getCategoryColor(),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(),
        ),
      ),
    );
  }
  
  // Obtenir les couleurs du dégradé pour chaque catégorie
  List<Color> _getGradientColors() {
    switch(category.id) {
      case 1: // Maison & Construction
        return [Colors.blue[700]!, Colors.blue[900]!];
      case 2: // Bien-être & Beauté
        return [Colors.purple[300]!, Colors.purple[700]!];
      case 3: // Événements & Artistiques
        return [Colors.red[400]!, Colors.red[700]!];
      case 4: // Transport & Logistique
        return [Colors.blueGrey[600]!, Colors.blueGrey[900]!];
      case 5: // Santé & Bien-être
        return [Colors.pink[300]!, Colors.pink[700]!];
      case 6: // Services Professionnels
        return [Colors.indigo[400]!, Colors.indigo[800]!];
      case 7: // Services Numériques
        return [Colors.teal[400]!, Colors.teal[800]!];
      case 8: // Services pour Animaux
        return [Colors.amber[400]!, Colors.amber[700]!];
      case 9: // Services Divers
        return [Colors.yellow[600]!, Colors.orange[800]!];
      default:
        return [Colors.lightBlue, Colors.blue];
    }
  }
  
  // Obtenir la couleur principale de la catégorie
  Color _getCategoryColor() {
    switch(category.id) {
      case 1: return Colors.blue[800]!;
      case 2: return Colors.purple[500]!;
      case 3: return Colors.red[500]!;
      case 4: return Colors.blueGrey[700]!;
      case 5: return Colors.pink[500]!;
      case 6: return Colors.indigo[600]!;
      case 7: return Colors.teal[600]!;
      case 8: return Colors.amber[600]!;
      case 9: return Colors.orange[700]!;
      default: return Colors.blue;
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
}