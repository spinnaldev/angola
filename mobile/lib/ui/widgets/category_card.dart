// lib/ui/widgets/category_card.dart
import 'package:flutter/material.dart';
import '../../core/models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  
  const CategoryCard({Key? key, required this.category}) : super(key: key);

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
          // Image de fond
          Image.network(
            category.imageUrl ?? 'https://via.placeholder.com/150',
            fit: BoxFit.cover,
          ),
          
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
          
          // Texte de la catégorie (en bas à gauche)
          Positioned(
            left: 10,
            bottom: 10,
            child: Text(
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
          ),
        ],
      ),
    );
  }
}