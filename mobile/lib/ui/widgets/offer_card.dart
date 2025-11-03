import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/messaging/conversation_detail_screen.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../core/models/conversation.dart';
import '../screens/provider_detail_screen.dart';

class OfferCard extends StatefulWidget {
  final dynamic offer;
  final VoidCallback? onOfferUpdated;
  
  const OfferCard({
    Key? key,
    required this.offer,
    this.onOfferUpdated,
  }) : super(key: key);

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            _buildProviderHeader(l10n),
            const SizedBox(height: 12),
            _buildOfferDetails(l10n),
            const SizedBox(height: 12),
            _buildMessage(l10n),
            const SizedBox(height: 12),
            _buildOptions(l10n),
            const SizedBox(height: 12),
            _buildProjectButton(l10n),
            if (isClient) ...[
              const SizedBox(height: 12),
              _buildActionButtons(context, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderHeader(AppLocalizations l10n) {
    return Row(
      children: [
        // Avatar cliquable pour aller au profil
        GestureDetector(
          onTap: () => _navigateToProviderProfile(context),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF142FE2).withOpacity(0.1),
            backgroundImage: widget.offer['provider_avatar'] != null
                ? NetworkImage(widget.offer['provider_avatar'])
                : null,
            child: widget.offer['provider_avatar'] == null
                ? Text(
                    _getInitials(widget.offer['provider_name'] ?? l10n.provider),
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToProviderProfile(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.offer['provider_name'] ?? l10n.provider,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    Flexible(
                      child: Text(
                        '${_parseRating(widget.offer['provider_rating']).toStringAsFixed(1)} (${widget.offer['provider_reviews_count'] ?? 0})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.offer['provider_verified'] == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.verified,
                          style: const TextStyle(
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
        ),
        const SizedBox(width: 8),
        _buildStatusBadge(l10n),
      ],
    );
  }

  Widget _buildOfferDetails(AppLocalizations l10n) {
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
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.proposedPrice,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_parsePrice(widget.offer['proposed_price'])} AOA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.grey[300],
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deliveryTime,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${widget.offer['delivery_time'] ?? 30} ${l10n.days}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(AppLocalizations l10n) {
    final message = widget.offer['message'] ?? '';
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
          Text(
            l10n.messageForClient,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 80),
            child: SingleChildScrollView(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(AppLocalizations l10n) {
    final materialsIncluded = widget.offer['materials_included'] ?? false;
    final travelCostsIncluded = widget.offer['travel_costs_included'] ?? false;
    
    if (!materialsIncluded && !travelCostsIncluded) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (materialsIncluded)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF142FE2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.materialsIncluded,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (travelCostsIncluded)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF142FE2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.travelCostsIncluded,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProjectButton(AppLocalizations l10n) {
    final projectTitle = widget.offer['project_title'] ?? '';
    if (projectTitle.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(
          Icons.access_time,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _getTimeAgo(widget.offer['created_at']),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: OutlinedButton(
            onPressed: () => _viewProject(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF142FE2),
              side: const BorderSide(color: Color(0xFF142FE2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              l10n.viewProject,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    final status = widget.offer['status']?.toString().toLowerCase() ?? 'pending';

    switch (status) {
      case 'pending':
        return _buildPendingState(context, l10n);
      case 'accepted':
        return _buildAcceptedState(context, l10n);
      case 'rejected':
        return _buildRejectedState(l10n);
      default:
        return _buildPendingState(context, l10n);
    }
  }

  Widget _buildPendingState(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isUpdating ? null : () => _handleOfferAction(context, 'rejected', l10n),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isUpdating 
                  ? const SizedBox(
                      height: 16,
                      width: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : Text(l10n.reject),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isUpdating ? null : () => _handleOfferAction(context, 'accepted', l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142FE2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isUpdating 
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      )
                    )
                  : Text(l10n.accept),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _contactProvider(context, l10n),
            icon: const Icon(Icons.message, size: 18),
            label: Text(
              l10n.contactProvider,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

  Widget _buildAcceptedState(BuildContext context, AppLocalizations l10n) {
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
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.acceptedOffers,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _contactProvider(context, l10n),
            icon: const Icon(Icons.message, size: 18),
            label: Text(
              l10n.contactProvider,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

  Widget _buildRejectedState(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.rejectedOffers,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppLocalizations l10n) {
    final status = widget.offer['status'] ?? 'pending';
    Color color;
    String text;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        text = l10n.accepted;
        break;
      case 'rejected':
        color = Colors.red;
        text = l10n.rejected;
        break;
      default:
        color = Colors.orange;
        text = l10n.pending;
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

  // Navigation vers le profil du prestataire
  void _navigateToProviderProfile(BuildContext context) {
    final providerId = _parseId(widget.offer['provider_id']);
    print('🔍 Navigation vers profil prestataire: $providerId');
    
    if (providerId != null) {
      print('✅ Navigating to provider $providerId');
      // ✅ Passer l'int directement, pas un Map
      Navigator.pushNamed(
        context,
        '/provider-detail',
        arguments: providerId, // ← int directement
      ).then((value) {
        print('🔙 Retour de provider-detail');
      });
    } else {
      print('❌ providerId est null, impossible de naviguer');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'afficher le profil du prestataire'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Voir le projet
  void _viewProject(BuildContext context) {
    final projectId = _parseId(widget.offer['project_id']);
    if (projectId != null) {
      Navigator.pushNamed(
        context,
        '/project-detail',
        arguments: {'projectId': projectId},
      );
    }
  }

  // Méthode pour gérer accepter/rejeter
  Future<void> _handleOfferAction(BuildContext context, String action, AppLocalizations l10n) async {
    final bool? confirm = await _showConfirmationDialog(context, action, l10n);
    if (confirm != true) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final offersProvider = Provider.of<OffersProvider>(context, listen: false);
      final success = await offersProvider.updateOfferStatus(
        widget.offer['id'] as int, 
        action,
      );
      
      if (success) {
        setState(() {
          widget.offer['status'] = action;
          _isUpdating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'accepted' 
                ? l10n.offerAcceptedSuccessfully
                : l10n.offerRejectedSuccessfully
            ),
            backgroundColor: action == 'accepted' ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        
        if (widget.onOfferUpdated != null) {
          widget.onOfferUpdated!();
        }
        
      } else {
        throw Exception(l10n.updateFailed);
      }
      
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Dialog de confirmation
  Future<bool?> _showConfirmationDialog(BuildContext context, String action, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(action == 'accepted' ? l10n.acceptOfferTitle : l10n.rejectOfferTitle),
          content: Text(
            action == 'accepted' 
              ? l10n.acceptOfferConfirmation
              : l10n.rejectOfferConfirmation
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'accepted' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(action == 'accepted' ? l10n.accept : l10n.reject),
            ),
          ],
        );
      },
    );
  }

  // Contact du prestataire
  Future<void> _contactProvider(BuildContext context, AppLocalizations l10n) async {
    try {
      final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mustBeLoggedInToContact)),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      int? providerId = _parseId(widget.offer['provider_id']);

      if (providerId == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cannotIdentifyProvider)),
        );
        return;
      }

      final conversation = await messagingProvider.startConversation(providerId, null);

      Navigator.pop(context);

      if (conversation != null) {
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
          SnackBar(content: Text(l10n.conversationOpenError)),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.contactError}: $e')),
      );
    }
  }

  // Utilitaires
  int? _parseId(dynamic value) {
    if (value == null) return null;
    try {
      if (value is int) return value;
      if (value is String) return int.parse(value);
      if (value is double) return value.toInt();
      return int.tryParse(value.toString());
    } catch (e) {
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
      if (price is int) return price;
      if (price is double) return price.toInt();
      if (price is String) return double.parse(price).toInt();
      return int.tryParse(price.toString()) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    try {
      if (rating is double) return rating;
      if (rating is int) return rating.toDouble();
      if (rating is String) return double.parse(rating);
      return double.tryParse(rating.toString()) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Il y a quelques instants';
    
    try {
      DateTime dateTime;
      if (createdAt is String) {
        dateTime = DateTime.parse(createdAt);
      } else if (createdAt is DateTime) {
        dateTime = createdAt;
      } else {
        return 'Il y a quelques instants';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return 'Il y a $years ${years == 1 ? 'an' : 'ans'}';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return 'Il y a $months mois';
      } else if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays} ${difference.inDays == 1 ? 'jour' : 'jours'}';
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes}min';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return 'Il y a quelques instants';
    }
  }
}