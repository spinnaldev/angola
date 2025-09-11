// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../core/models/review.dart';
// import 'rating_stars.dart';

// class ReviewCard extends StatelessWidget {
//   final Review review;

//   const ReviewCard({
//     Key? key,
//     required this.review,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // En-tête avec info utilisateur
//           Row(
//             children: [
//               // Avatar utilisateur
//               CircleAvatar(
//                 radius: 20,
//                 backgroundImage: review.userImageUrl.isNotEmpty
//                     ? NetworkImage(review.userImageUrl)
//                     : null,
//                 child: review.userImageUrl.isEmpty
//                     ? Text(
//                         review.userName.substring(0, 1),
//                         style: const TextStyle(fontSize: 20),
//                       )
//                     : null,
//               ),
//               const SizedBox(width: 12),
              
//               // Nom et date
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       review.userName,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     Text(
//                       DateFormat('dd/MM/yyyy').format(review.date),
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Note
//               RatingStars(rating: review.rating),
//             ],
//           ),
          
//           const SizedBox(height: 12),
          
//           // Commentaire
//           Text(
//             review.comment,
//             style: const TextStyle(
//               fontSize: 14,
//               height: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/review.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showProvider;
  final bool showClient;
  final VoidCallback? onTap;

  const ReviewCard({
    Key? key,
    required this.review,
    this.showProvider = false,
    this.showClient = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec info client/prestataire
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF142FE2).withOpacity(0.1),
                    child: Text(
                      _getInitials(),
                      style: const TextStyle(
                        color: Color(0xFF142FE2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayName(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Note globale
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRatingColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: _getRatingColor(),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: _getRatingColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Titre de l'avis (si présent)
              if (review.title?.isNotEmpty == true) ...[
                Text(
                  review.title!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Commentaire
              Text(
                review.comment,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Détails des notes (si disponibles)
              if (review.qualityRating != null) ...[
                Row(
                  children: [
                    _buildRatingDetail('Qualité', review.qualityRating!),
                    const SizedBox(width: 16),
                    _buildRatingDetail('Ponctualité', review.punctualityRating!),
                    const SizedBox(width: 16),
                    _buildRatingDetail('Prix', review.valueRating!),
                  ],
                ),
              ],
              
              // Badge vérifié
              if (review.isVerified) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Avis vérifié',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (showProvider && review.providerName.isNotEmpty) {
      return review.providerName[0].toUpperCase();
    } else if (showClient && review.clientName.isNotEmpty) {
      return review.clientName[0].toUpperCase();
    }
    return '?';
  }

  String _getDisplayName() {
    if (showProvider && review.providerName.isNotEmpty) {
      return review.providerName;
    } else if (showClient && review.clientName.isNotEmpty) {
      return review.clientName;
    }
    return 'Utilisateur';
  }

  Color _getRatingColor() {
    if (review.rating >= 4.0) return Colors.green;
    if (review.rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRatingDetail(String label, int rating) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 12,
            );
          }),
        ),
      ],
    );
  }
}
