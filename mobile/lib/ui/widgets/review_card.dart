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
                    backgroundImage: _getAvatarImage(),
                    child: _getAvatarImage() == null
                        ? Text(
                            _getInitials(),
                            style: const TextStyle(
                              color: Color(0xFF142FE2),
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
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
                  // ✅ SEULEMENT LA NOTE GLOBALE (pas de qualité/ponctualité/prix)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          review.rating.toString(),
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
              
              // Titre de l'avis (si disponible)
              if (review.reviewTitle?.isNotEmpty == true) ...[
                Text(
                  review.reviewTitle!,
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              
              // Images (si disponibles)
              if (review.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: review.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            review.imageUrls[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              // Badge vérifié (si applicable)
              if (review.isVerified) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
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

  // ✅ Méthode pour obtenir l'image d'avatar appropriée
  ImageProvider? _getAvatarImage() {
    if (showProvider && review.providerImageUrl?.isNotEmpty == true) {
      return NetworkImage(review.providerImageUrl!);
    } else if (showClient && review.clientImageUrl?.isNotEmpty == true) {
      return NetworkImage(review.clientImageUrl!);
    }
    return null;
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
    if (review.rating >= 4) return Colors.green;
    if (review.rating >= 3) return Colors.orange;
    return Colors.red;
  }
}