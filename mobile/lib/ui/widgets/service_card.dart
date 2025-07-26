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
// mobile/lib/ui/widgets/service_card.dart
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
    final imageUrl = _getSafeString(service.imageUrl, '');
    final hasValidImage = imageUrl.isNotEmpty && _isValidUrl(imageUrl);

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: hasValidImage
            ? _buildNetworkImage(imageUrl)
            : _buildDefaultImage(),
      ),
    );
  }

  // ✅ MÉTHODE pour construire l'image réseau avec gestion d'erreur
  Widget _buildNetworkImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 120,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          height: 120,
          width: double.infinity,
          color: Colors.grey[100],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Erreur chargement image: $error');
        return _buildDefaultImage();
      },
    );
  }

  // ✅ MÉTHODE pour construire l'image par défaut
  Widget _buildDefaultImage() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.blue[100]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[200]!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.business_center,
              size: 32,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Service',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
          '($reviewCount)',
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
    final price = _getSafeDouble(service.price, 0.0);
    final businessType = _getSafeString(service.businessType, 'Non spécifié');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessType,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (price > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${price.toStringAsFixed(0)} AOA',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
      ],
    );
  }

  // ✅ MÉTHODE PROTÉGÉE pour construire une card d'erreur
  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red[200]!, width: 1),
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
                color: Colors.red[400],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MÉTHODES UTILITAIRES pour la protection des données
  String _getSafeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    return value.toString().isEmpty ? defaultValue : value.toString();
  }

  double _getSafeDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  int _getSafeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (e) {
      return false;
    }
  }
}