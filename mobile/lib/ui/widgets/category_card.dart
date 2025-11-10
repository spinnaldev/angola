// lib/ui/widgets/category_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/category.dart';
import '../../providers/language_provider.dart';

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
          // Image de fond depuis l'API
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
                  category.getLocalizedName(
                    Provider.of<LanguageProvider>(context, listen: false).currentLocale.languageCode
                  ),
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
  
  Widget _buildBackgroundImage() {
    // Si l'URL est une URL réseau (commence par http:// ou https://)
    if (category.imageUrl.startsWith('http://') || category.imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: category.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackImage(),
      );
    }
    // Si c'est une image locale (commence par 'assets/')
    else if (category.imageUrl.startsWith('assets/')) {
      return Image.asset(
        category.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      );
    }
    // Si imageUrl est vide ou invalide
    else {
      return _buildFallbackImage();
    }
  }
  
  Widget _buildFallbackImage() {
    // Image de secours basée sur l'ID de la catégorie
    return Image.asset(
      'assets/images/categories/category_${category.id % 10}.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Si l'image par défaut échoue aussi, afficher un placeholder coloré
        return Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.category,
            size: 50,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}