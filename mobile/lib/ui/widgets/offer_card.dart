import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/messaging/conversation_detail_screen.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/conversation.dart';

class OfferCard extends StatelessWidget {
  final dynamic offer;
  final Function(dynamic) onAccept;
  final Function(dynamic) onReject;
  final Function(dynamic)? onContact; // Nouveau callback optionnel

  const OfferCard({
    Key? key,
    required this.offer,
    required this.onAccept,
    required this.onReject,
    this.onContact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isClient = user?.role == 'client';
    
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderHeader(),
            const SizedBox(height: 12),
            _buildOfferDetails(),
            const SizedBox(height: 16),
            _buildMessage(),
            const SizedBox(height: 16),
            if (isClient) _buildActionButtons(context),
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
          backgroundColor: const Color(0xFF142FE2).withOpacity(0.1),
          backgroundImage: offer['provider_avatar'] != null
              ? NetworkImage(offer['provider_avatar'])
              : null,
          child: offer['provider_avatar'] == null
              ? Text(
                  _getInitials(offer['provider_name'] ?? 'Prestataire'),
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
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
                offer['provider_name'] ?? 'Prestataire',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_parseRating(offer['provider_rating']).toStringAsFixed(1)} (${offer['provider_reviews_count'] ?? 0} avis)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (offer['provider_verified'] == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Vérifié',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Badge de statut de l'offre
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildOfferDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prix proposé',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_parsePrice(offer['proposed_price'])}€',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1, 
            height: 30,
            color: Colors.grey[300],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Délai de livraison',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${offer['delivery_time'] ?? 30} jours',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    final message = offer['message'] ?? '';
    if (message.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Message du prestataire',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final status = offer['status']?.toString().toLowerCase() ?? 'pending';
    
    return Column(
      children: [
        if (status == 'pending') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onReject(offer),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Rejeter'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onAccept(offer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF142FE2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Accepter'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        // Bouton Contact prestataire (toujours visible)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              print('🚀 Tentative de contact prestataire');
              print('📋 Données de l\'offre: $offer');
              _contactProvider(context);
            },
            icon: const Icon(Icons.message),
            label: const Text('Contacter le prestataire'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF142FE2),
              side: const BorderSide(color: Color(0xFF142FE2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptedState(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Offre acceptée',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _contactProvider(context),
            icon: const Icon(Icons.message, size: 18),
            label: const Text('Contacter le prestataire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142FE2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cancel, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Text(
            'Offre rejetée',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = offer['status'] ?? 'pending';
    Color color;
    String text;
    
    switch (status) {
      case 'accepted':
        color = Colors.green;
        text = 'Acceptée';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejetée';
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
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // NOUVELLE MÉTHODE : Contact du prestataire
  Future<void> _contactProvider(BuildContext context) async {
    try {
      final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez être connecté pour contacter un prestataire')),
        );
        return;
      }

      // Afficher un loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // ✅ CORRECTION PRINCIPALE : Gestion correcte de l'ID du prestataire
      int? providerId;
      
      // Essayer différentes façons d'obtenir l'ID du prestataire
      if (offer['provider_id'] != null) {
        // Si provider_id existe directement
        providerId = _parseId(offer['provider_id']);
      } else if (offer['provider'] != null) {
        // Si provider est un objet avec un id
        if (offer['provider'] is Map<String, dynamic>) {
          providerId = _parseId(offer['provider']['id']);
        } else {
          // Si provider est directement l'ID
          providerId = _parseId(offer['provider']);
        }
      } else if (offer['providerId'] != null) {
        // Autre variante possible
        providerId = _parseId(offer['providerId']);
      }

      print('🔍 Provider ID trouvé: $providerId');
      print('🔍 Structure de l\'offre: ${offer.keys.toList()}');
      
      if (providerId == null) {
        Navigator.pop(context); // Fermer le loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'identifier le prestataire')),
        );
        return;
      }

      // Créer le message initial avec contexte de l'offre
      String projectTitle = 'votre projet';
      
      // Essayer d'obtenir le titre du projet
      if (offer['project_title'] != null) {
        projectTitle = offer['project_title'].toString();
      } else if (offer['project'] != null && offer['project'] is Map<String, dynamic>) {
        projectTitle = offer['project']['title']?.toString() ?? projectTitle;
      }
      
      final initialMessage = 'Bonjour, je suis intéressé(e) par votre offre pour le projet "$projectTitle". Pouvons-nous discuter des détails ?';

      // Démarrer ou récupérer la conversation
      final conversation = await messagingProvider.startConversation(
        providerId,
        initialMessage: initialMessage,
      );

      Navigator.pop(context); // Fermer le loading

      if (conversation != null) {
        // Naviguer vers l'écran de conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversationId: conversation.id,
              otherPerson: conversation.otherPerson,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'ouverture de la conversation')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Fermer le loading en cas d'erreur
      print('Erreur contact prestataire: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du contact: $e')),
      );
    }
  }

  int? _parseId(dynamic value) {
  if (value == null) return null;
  
  try {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.parse(value);
    } else if (value is double) {
      return value.toInt();
    } else {
      print('⚠️ Type inattendu pour ID: ${value.runtimeType} - $value');
      return int.tryParse(value.toString());
    }
  } catch (e) {
    print('❌ Erreur parsing ID: $e pour valeur: $value');
    return null;
  }
}

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'P';
  }
  int _parsePrice(dynamic price) {
    if (price == null) return 0;
    
    try {
      if (price is int) {
        return price;
      } else if (price is double) {
        return price.toInt();
      } else if (price is String) {
        if (price.isEmpty) return 0;
        return double.parse(price).toInt();
      } else {
        return int.tryParse(price.toString()) ?? 0;
      }
    } catch (e) {
      print('❌ Erreur parsing prix: $e pour valeur: $price');
      return 0;
    }
  }

  double _parseRating(dynamic rating) {
    if (rating == null) return 5.0;
    
    try {
      if (rating is double) {
        return rating;
      } else if (rating is int) {
        return rating.toDouble();
      } else if (rating is String) {
        if (rating.isEmpty) return 5.0;
        return double.parse(rating);
      } else {
        return double.tryParse(rating.toString()) ?? 5.0;
      }
    } catch (e) {
      print('❌ Erreur parsing rating: $e pour valeur: $rating');
      return 5.0;
    }
  }

}
