// // mobile/lib/ui/widgets/service_card.dart
// import 'package:flutter/material.dart';
// import '../../core/models/service.dart';

// class ServiceCard extends StatelessWidget {
//   final Service service;
//   final VoidCallback? onTap;

//   const ServiceCard({
//     Key? key,
//     required this.service,
//     this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image du service
//             Container(
//               height: 120,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.grey[200],
//                 borderRadius:
//                     const BorderRadius.vertical(top: Radius.circular(12)),
//                 image: service.imageUrl.isNotEmpty
//                     ? DecorationImage(
//                         image: NetworkImage(service.imageUrl),
//                         fit: BoxFit.cover,
//                       )
//                     : null,
//               ),
//               child: service.imageUrl.isEmpty
//                   ? const Icon(
//                       Icons.work_outline,
//                       size: 40,
//                       color: Colors.grey,
//                     )
//                   : null,
//             ),

//             // Contenu du service
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Titre
//                     Text(
//                       service.title,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 4),

//                     // Description
//                     Text(
//                       service.description,
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 8),

//                     // Note et avis
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.star,
//                           color: Colors.amber,
//                           size: 16,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${service.rating.toStringAsFixed(1)}',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           '(${service.reviewCount})',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Spacer(),

//                     // Prix
//                     Row(
//                       children: [
//                         Text(
//                           service.priceType == 'fixed'
//                               ? '${service.price.toInt()}AOA'
//                               : 'Sur devis',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w700,
//                             color: service.priceType == 'fixed'
//                                 ? Colors.green
//                                 : Colors.orange,
//                           ),
//                         ),
//                         const Spacer(),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF142FE2).withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             service.businessType,
//                             style: const TextStyle(
//                               fontSize: 10,
//                               color: Color(0xFF6366F1),
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// mobile/lib/ui/widgets/service_card.dart - VERSION CORRIGÉE COMPLÈTE
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
    // ✅ PROTECTION 1: Vérifier que service n'est pas null
    if (service == null) {
      return _buildErrorCard('Service indisponible');
    }

    try {
      return Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ CORRECTION 2: Image du service avec protection complète
              _buildServiceImage(),
              
              // ✅ CORRECTION 3: Informations du service avec protection
              _buildServiceInfo(),
            ],
          ),
        ),
      );
    } catch (e) {
      print('❌ Erreur dans ServiceCard.build: $e');
      return _buildErrorCard('Erreur de chargement');
    }
  }

  // ✅ MÉTHODE PROTÉGÉE pour l'image du service
  Widget _buildServiceImage() {
    // Récupérer l'URL de l'image de manière sécurisée
    final imageUrl = service.imageUrl ?? '';
    final hasValidImage = imageUrl.isNotEmpty;

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        image: hasValidImage
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  print('Erreur chargement image: $exception');
                },
              )
            : null,
      ),
      child: !hasValidImage
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pas d\'image',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // ✅ MÉTHODE PROTÉGÉE pour les informations du service
  Widget _buildServiceInfo() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre du service
          Text(
            _getSafeString(service.title, 'Service sans titre'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 6),
          
          // Description
          Text(
            _getSafeString(service.description, 'Aucune description'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Rating et avis
          _buildRatingSection(),
          
          const SizedBox(height: 8),
          
          // Prix et type de business
          _buildPriceAndBusinessSection(),
        ],
      ),
    );
  }

  // ✅ MÉTHODE PROTÉGÉE pour la section rating
  Widget _buildRatingSection() {
    final rating = _getSafeDouble(service.rating, 0.0);
    final reviewCount = _getSafeInt(service.reviewCount, 0);

    return Row(
      children: [
        Icon(
          Icons.star,
          color: rating > 0 ? Colors.amber : Colors.grey[400],
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: rating > 0 ? Colors.black87 : Colors.grey[500],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviewCount avis)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  // ✅ MÉTHODE PROTÉGÉE pour la section prix et business
  Widget _buildPriceAndBusinessSection() {
    final priceType = _getSafeString(service.priceType, 'quote');
    final price = _getSafeDouble(service.price, 0.0);
    final businessType = _getSafeString(service.businessType, 'Entreprise');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Prix
        Expanded(
          child: Text(
            _formatPrice(priceType, price),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF142FE2),
            ),
          ),
        ),
        
        // Type de business
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            businessType,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ WIDGET D'ERREUR standardisé
  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MÉTHODES UTILITAIRES pour la sécurité des données
  String _getSafeString(String? value, String defaultValue) {
    if (value == null || value.isEmpty) {
      return defaultValue;
    }
    return value;
  }

  double _getSafeDouble(double? value, double defaultValue) {
    if (value == null || value.isNaN || value.isInfinite) {
      return defaultValue;
    }
    return value;
  }

  int _getSafeInt(int? value, int defaultValue) {
    if (value == null) {
      return defaultValue;
    }
    return value;
  }

  String _formatPrice(String priceType, double price) {
    try {
      switch (priceType.toLowerCase()) {
        case 'fixed':
          return price > 0 ? '${price.toInt()} FCFA' : 'Prix à définir';
        case 'hourly':
          return price > 0 ? '${price.toInt()} FCFA/h' : 'Tarif horaire à définir';
        case 'daily':
          return price > 0 ? '${price.toInt()} FCFA/jour' : 'Tarif journalier à définir';
        case 'negotiable':
          return 'Prix négociable';
        case 'quote':
        default:
          return 'Sur devis';
      }
    } catch (e) {
      print('Erreur formatage prix: $e');
      return 'Prix à définir';
    }
  }
}

// ✅ EXTENSION pour une utilisation encore plus sécurisée (optionnel)
extension SafeServiceCard on Service {
  bool get isValid {
    try {
      return id != null && id > 0 && 
             title != null && title.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}