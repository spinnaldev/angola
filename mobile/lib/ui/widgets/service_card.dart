import 'package:flutter/material.dart';
import '../../core/models/service.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;

  const ServiceCard({
    Key? key,
    required this.service,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Image du service
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                service.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                },
              ),
            ),
            
            // Informations du service
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Titre du service
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Étoiles et note
                    Row(
                      children: [
                        // Étoiles jaunes
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                        ),
                        
                        const SizedBox(width: 4),
                        
                        // Nombre d'avis
                        Text(
                          '(${service.reviewCount})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Bouton "Voir" placé à droite
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF142FE2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Voir',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}