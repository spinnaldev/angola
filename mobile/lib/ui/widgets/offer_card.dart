
import 'package:flutter/material.dart';
import '../../core/models/project_offer.dart';

class OfferCard extends StatelessWidget {
  final ProjectOffer offer;
  final Function(ProjectOffer)? onAccept;
  final Function(ProjectOffer)? onReject;
  final Function(ProjectOffer)? onContact;

  const OfferCard({
    Key? key,
    required this.offer,
    this.onAccept,
    this.onReject,
    this.onContact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderHeader(),
            const SizedBox(height: 16),
            _buildOfferDetails(),
            const SizedBox(height: 16),
            _buildOfferMessage(),
            const SizedBox(height: 16),
            _buildOfferOptions(),
            if (offer.isPending && (onAccept != null || onReject != null)) ...[
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: offer.providerAvatar != null
              ? NetworkImage(offer.providerAvatar!)
              : null,
          child: offer.providerAvatar == null
              ? Text(
                  offer.providerName.isNotEmpty ? offer.providerName[0] : 'P',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      offer.providerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (offer.providerVerified) ...[
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF6366F1),
                      size: 18,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                offer.providerBusinessType ?? 'Prestataire',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildRatingStars(offer.providerRating),
                  const SizedBox(width: 8),
                  Text(
                    '${offer.providerRating.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (offer.providerLocation != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        offer.providerLocation!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
                  ? Icons.star_half
                  : Icons.star_border,
          color: Colors.amber,
          size: 14,
        );
      }),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    
    switch (offer.status) {
      case 'accepted':
        color = Colors.green;
        text = 'Acceptée';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejetée';
        break;
      case 'withdrawn':
        color = Colors.grey;
        text = 'Retirée';
        break;
      default:
        color = Colors.orange;
        text = 'En attente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOfferDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.euro,
                  label: 'Prix proposé',
                  value: '${offer.proposedPrice.toStringAsFixed(0)}€',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.schedule,
                  label: 'Délai',
                  value: offer.deliveryTimeLabel,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          if (offer.warrantyPeriod != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.verified_user,
                    label: 'Garantie',
                    value: '${offer.warrantyPeriod} mois',
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Container()), // Espace vide pour l'alignement
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildOfferMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message du prestataire',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            offer.message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferOptions() {
    final options = <Widget>[];

    if (offer.includesMaterials) {
      options.add(_buildOptionChip(
        icon: Icons.inventory,
        label: 'Matériaux inclus',
        color: Colors.green,
      ));
    }

    if (offer.travelCostsIncluded) {
      options.add(_buildOptionChip(
        icon: Icons.directions_car,
        label: 'Déplacement inclus',
        color: Colors.blue,
      ));
    }

    if (offer.warrantyPeriod != null) {
      options.add(_buildOptionChip(
        icon: Icons.security,
        label: 'Avec garantie',
        color: Colors.purple,
      ));
    }

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options incluses',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options,
        ),
      ],
    );
  }

  Widget _buildOptionChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onReject != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => onReject!(offer),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Rejeter',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (onContact != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => onContact!(offer),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Contacter',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (onAccept != null) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => onAccept!(offer),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Accepter',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }
}