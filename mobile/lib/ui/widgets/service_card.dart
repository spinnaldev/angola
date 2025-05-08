// lib/ui/widgets/service_card.dart

import 'package:flutter/material.dart';
import '../../core/models/service.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;

  const ServiceCard({
    Key? key,
    required this.service,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image du service - carré de 80x80
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      service.imageUrl.isNotEmpty
                          ? service.imageUrl
                          : 'https://via.placeholder.com/80',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                
                // Espace entre l'image et le contenu
                const SizedBox(width: 12),
                
                // Contenu (titre et description)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titre du service
                      Text(
                        service.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Espace entre titre et description
                      const SizedBox(height: 4),
                      
                      // Description du service
                      Text(
                        'Entreprise de ${service.businessType.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Partie droite (étoiles et bouton)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Étoiles
                    Row(
                      children: [
                        // 5 étoiles jaunes
                        for (int i = 0; i < 5; i++)
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                        
                        // Nombre d'avis
                        const SizedBox(width: 4),
                        Text(
                          "(${service.reviewCount})",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    // Espace entre étoiles et bouton
                    const SizedBox(height: 10),
                    
                    // Bouton "Voir"
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF142FE2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(60, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Voir',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Léger padding à droite
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}