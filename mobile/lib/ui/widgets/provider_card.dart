
import 'package:flutter/material.dart';
import '../../core/models/provider_model.dart';

class ProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback? onTap; // ✅ VoidCallback simple
  final VoidCallback? onFavoriteToggle; // ✅ VoidCallback simple

  const ProviderCard({
    Key? key,
    required this.provider,
    this.onTap,
    this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        // Navigation par défaut vers le profil du prestataire
        Navigator.pushNamed(
          context,
          '/provider-detail',
          arguments: {'providerId': provider.id},
        );
      },
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
              // En-tête avec photo et favori
              Row(
                children: [
                  // Photo de profil
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF142FE2).withOpacity(0.1),
                    backgroundImage: provider.profileImageUrl.isNotEmpty
                        ? NetworkImage(provider.profileImageUrl)
                        : null,
                    child: provider.profileImageUrl.isEmpty
                        ? Text(
                            provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              color: Color(0xFF142FE2),
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Informations principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (provider.isVerified)
                              Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.businessType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              provider.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${provider.reviewCount})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Bouton favori
                  if (onFavoriteToggle != null)
                    IconButton(
                      onPressed: onFavoriteToggle,
                      icon: Icon(
                        Icons.favorite,
                        color: Colors.red, // Toujours rouge car c'est dans les favoris
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              if (provider.description.isNotEmpty) ...[
                Text(
                  provider.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Informations complémentaires
              Row(
                children: [
                  // Distance (si disponible)
                  if (provider.distance != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.distance!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  // Services
                  Icon(
                    Icons.work_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${provider.services.length} service${provider.services.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Statut de vérification
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (provider.isVerified) return Colors.green;
    return Colors.orange;
  }

  String _getStatusText() {
    if (provider.isVerified) return 'Vérifié';
    return 'Non vérifié';
  }
}
