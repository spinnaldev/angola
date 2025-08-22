import 'package:flutter/material.dart';
import '../../ui/screens/messaging/conversation_detail_screen.dart';
import '../../ui/screens/project_detail_screen.dart';
import '../../ui/screens/service_detail_screen.dart';
import '../../ui/screens/provider/quote_requests_screen.dart';
import '../../ui/screens/client/my_quote_requests_screen.dart';
import '../../ui/screens/messaging/messages_screen.dart';
import '../../core/models/notification_model.dart';
import '../../core/models/conversation.dart'; // Pour accéder à la classe Person

class NotificationNavigationService {
  
  /// Service principal pour gérer la navigation selon le type de notification
  static Future<void> navigateToNotificationTarget(
    BuildContext context, 
    NotificationModel notification
  ) async {
    
    final notificationType = notification.notificationType;
    final relatedObjectId = notification.relatedObjectId;
    final extraData = notification.extraData;
    
    try {
      switch (notificationType) {
        
        // ===== NOTIFICATIONS DE MESSAGES =====
        case 'new_message':
        case 'message':
          await _navigateToMessage(context, relatedObjectId, extraData);
          break;
          
        // ===== NOTIFICATIONS DE DEVIS =====
        case 'quote_request':
          // Pour les prestataires qui reçoivent des demandes
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QuoteRequestsScreen(),
            ),
          );
          break;
          
        case 'quote_accepted':
        case 'quote_rejected':
        case 'quote_completed':
          // Pour les clients qui voient leurs demandes
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyQuoteRequestsScreen(),
            ),
          );
          break;
          
        // ===== NOTIFICATIONS D'OFFRES DE PROJETS =====
        case 'new_offer':
        case 'offer_accepted':
        case 'offer_rejected':
          await _navigateToProjectOffer(context, relatedObjectId, extraData);
          break;
          
        // ===== NOTIFICATIONS D'AVIS =====
        case 'review':
        case 'new_review':
          await _navigateToReview(context, relatedObjectId, extraData);
          break;
          
        // ===== NOTIFICATIONS DE FAVORIS =====
        case 'favorite':
          await _navigateToFavorite(context, relatedObjectId, extraData);
          break;
          
        // ===== NOTIFICATIONS DE LITIGES =====
        case 'dispute':
        case 'dispute_created':
        case 'dispute_resolved':
          Navigator.pushNamed(context, '/disputes');
          break;
          
        // ===== NOTIFICATIONS SYSTÈME =====
        case 'system':
        case 'account_verified':
        case 'payment_received':
          Navigator.pushNamed(context, '/profile');
          break;
          
        // ===== CAS PAR DÉFAUT =====
        default:
          _showNotificationNotHandled(context, notificationType);
          break;
      }
    } catch (e) {
      print('❌ Erreur navigation notification: $e');
      _showNavigationError(context);
    }
  }
  
  // ===== MÉTHODES PRIVÉES DE NAVIGATION SPÉCIFIQUE =====
  
  /// Navigation vers une conversation/message spécifique
  static Future<void> _navigateToMessage(
    BuildContext context, 
    int? messageId, 
    Map<String, dynamic>? extraData
  ) async {
    if (messageId == null) {
      // Fallback vers la liste des conversations
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MessagesScreen(),
        ),
      );
      return;
    }
    
    try {
      // Extraire les informations de la conversation depuis extraData
      final conversationId = extraData?['conversation_id'] as int?;
      final senderId = extraData?['sender_id'] as int?;
      final senderUsername = extraData?['sender_username'] as String?;
      final senderFirstName = extraData?['sender_first_name'] as String?;
      final senderLastName = extraData?['sender_last_name'] as String?;
      final senderAvatar = extraData?['sender_avatar'] as String?;
      final senderCompanyName = extraData?['sender_company_name'] as String?;
      
      if (conversationId != null && senderId != null) {
        // Créer l'objet Person pour otherPerson avec votre vraie signature
        final otherPerson = Person(
          id: senderId,
          username: senderUsername ?? 'user$senderId',
          firstName: senderFirstName ?? '',
          lastName: senderLastName ?? '',
          profilePicture: senderAvatar,
          companyName: senderCompanyName,
        );
        
        // Navigation directe vers la conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversationId: conversationId,
              otherPerson: otherPerson,
            ),
          ),
        );
      } else {
        // Fallback vers la liste des messages
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MessagesScreen(),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur navigation message: $e');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MessagesScreen(),
        ),
      );
    }
  }
  
  /// Navigation vers une offre de projet spécifique
  static Future<void> _navigateToProjectOffer(
    BuildContext context, 
    int? offerId, 
    Map<String, dynamic>? extraData
  ) async {
    try {
      final projectId = extraData?['project_id'] as int?;
      
      if (projectId != null) {
        // Navigation vers le détail du projet (selon votre vraie signature)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(
              projectId: projectId,
            ),
          ),
        );
      } else if (offerId != null) {
        // Si on a que l'ID de l'offre, essayer de naviguer quand même
        // Vous pouvez créer une méthode pour récupérer le projectId depuis l'offre
        // ou naviguer vers une liste d'offres
        Navigator.pushNamed(context, '/projects');
      } else {
        Navigator.pushNamed(context, '/projects');
      }
    } catch (e) {
      print('❌ Erreur navigation offre: $e');
      Navigator.pushNamed(context, '/projects');
    }
  }
  
  /// Navigation vers un avis spécifique
  static Future<void> _navigateToReview(
    BuildContext context, 
    int? reviewId, 
    Map<String, dynamic>? extraData
  ) async {
    if (reviewId == null) return;
    
    try {
      final serviceId = extraData?['service_id'] as int?;
      final providerId = extraData?['provider_id'] as int?;
      
      if (serviceId != null && providerId != null) {
        // Navigation vers le service (selon votre vraie signature)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(
              serviceId: serviceId,
              providerId: providerId,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur navigation avis: $e');
    }
  }
  
  /// Navigation vers un favori
  static Future<void> _navigateToFavorite(
    BuildContext context, 
    int? itemId, 
    Map<String, dynamic>? extraData
  ) async {
    if (itemId == null) return;
    
    try {
      final itemType = extraData?['item_type'] as String?;
      
      switch (itemType) {
        case 'service':
          final providerId = extraData?['provider_id'] as int?;
          if (providerId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailScreen(
                  serviceId: itemId,
                  providerId: providerId,
                ),
              ),
            );
          }
          break;
        case 'project':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(
                projectId: itemId,
              ),
            ),
          );
          break;
        case 'provider':
          Navigator.pushNamed(context, '/provider-detail', arguments: itemId);
          break;
      }
    } catch (e) {
      print('❌ Erreur navigation favori: $e');
    }
  }
  
  // ===== MÉTHODES UTILITAIRES =====
  
  /// Afficher un message quand le type de notification n'est pas géré
  static void _showNotificationNotHandled(
    BuildContext context, 
    String notificationType
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Type de notification "$notificationType" non géré pour la navigation.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  /// Afficher un message d'erreur de navigation
  static void _showNavigationError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erreur lors de la navigation.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}