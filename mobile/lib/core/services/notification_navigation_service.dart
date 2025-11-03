// lib/core/services/notification_navigation_service.dart - VERSION CORRIGÉE
import 'package:flutter/material.dart';
import '../../ui/screens/messaging/conversation_detail_screen.dart';
import '../../ui/screens/project_detail_screen.dart';
import '../../ui/screens/service_detail_screen.dart';
import '../../ui/screens/provider/quote_requests_screen.dart';
import '../../ui/screens/client/my_quote_requests_screen.dart';
import '../../ui/screens/messaging/messages_screen.dart';
import '../../ui/screens/profile_screen.dart';
import '../../ui/screens/projects_list_screen.dart';
import '../../core/models/notification_model.dart';
import '../../core/models/conversation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../../ui/screens/disputes/dispute_detail_screen.dart';
import '../../ui/screens/disputes/disputes_screen.dart'; 

class NotificationNavigationService {
  /// Service principal pour gérer la navigation selon le type de notification
  static Future<void> navigateToNotificationTarget(
      BuildContext context, NotificationModel notification) async {
    final notificationType = notification.notificationType;
    final relatedObjectId = notification.relatedObjectId;
    final extraData = notification.extraData;

    print('🔄 Navigation notification:');
    print('   Notification: $notification');
    print('   Type: $notificationType');
    print('   RelatedObjectId: $relatedObjectId');
    print('   ExtraData: $extraData');

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
          await _navigateToQuoteRequests(context, relatedObjectId, extraData);
          break;

        case 'quote_accepted':
        case 'quote_rejected':
        case 'quote_completed':
          // Pour les clients qui voient leurs demandes
          await _navigateToMyQuoteRequests(context, relatedObjectId, extraData);
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

        // ===== NOTIFICATIONS DE PROJETS =====
        case 'project_created':
        case 'project_completed':
        case 'project_update':
          await _navigateToProject(context, relatedObjectId, extraData);
          break;

        // ===== NOTIFICATIONS DE FAVORIS =====
        case 'favorite':
        case 'favorite_added':
          await _navigateToFavorite(context, relatedObjectId, extraData);
          break;

        // ===== NOTIFICATIONS DE LITIGES =====
        case 'dispute':
        case 'dispute_created':
        case 'dispute_resolved':
          await _navigateToDispute(context, relatedObjectId, extraData);
          break;

        // ===== NOTIFICATIONS DE PROFIL =====
        case 'profile_verified':
        case 'profile_rejected':
        case 'phone_verified':
        case 'account_verified':
        case 'client_verification_approved':
        case 'client_verification_rejected':
          await _navigateToProfile(context);
          break;

        // ===== NOTIFICATIONS SYSTÈME =====
        case 'system':
        case 'payment_received':
        case 'payment_completed':
          await _navigateToProfile(context);
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
      int? conversationId, // ✅ Changé de messageId vers conversationId
      Map<String, dynamic>? extraData) async {
    print(
        '🔄 _navigateToMessage: conversationId=$conversationId, extraData=$extraData');

    // ✅ Fallback vers la liste des conversations si pas de conversationId
    if (conversationId == null) {
      print('❌ Pas de conversationId, fallback vers MessagesScreen');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MessagesScreen()),
      );
      return;
    }

    try {
      // ✅ Extraire conversation_id depuis extraData si relatedObjectId ne correspond pas
      final conversationIdFromExtra = extraData?['conversation_id'] as int?;
      final actualConversationId = conversationIdFromExtra ?? conversationId;

      final senderId = extraData?['sender_id'] as int?;
      final senderUsername = extraData?['sender_username'] as String?;
      final senderFirstName = extraData?['sender_first_name'] as String?;
      final senderLastName = extraData?['sender_last_name'] as String?;
      final senderAvatar = extraData?['sender_avatar'] as String?;
      final senderCompanyName = extraData?['sender_company_name'] as String?;

      print('🔄 Données extraites:');
      print('   ConversationId: $actualConversationId');
      print('   SenderId: $senderId');
      print('   SenderName: $senderFirstName');

      if (actualConversationId != null && senderId != null) {
        // Créer l'objet Person pour otherPerson
        final otherPerson = Person(
          id: senderId,
          username: senderUsername ?? 'user$senderId',
          firstName: senderFirstName ?? 'Utilisateur',
          lastName: senderLastName ?? '',
          profilePicture: senderAvatar,
          companyName: senderCompanyName,
        );

        print('✅ Navigation vers ConversationDetailScreen');
        // Navigation directe vers la conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversationId: actualConversationId,
              otherPerson: otherPerson,
            ),
          ),
        );
      } else {
        print('❌ Données manquantes, fallback vers MessagesScreen');
        // Fallback vers la liste des messages
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessagesScreen()),
        );
      }
    } catch (e) {
      print('❌ Erreur navigation message: $e');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MessagesScreen()),
      );
    }
  }

  /// Navigation vers les demandes de devis (prestataire)
  static Future<void> _navigateToQuoteRequests(BuildContext context,
      int? quoteId, Map<String, dynamic>? extraData) async {
    try {
      print('🔄 Navigation vers QuoteRequestsScreen (quote_id: $quoteId)');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QuoteRequestsScreen(),
        ),
      );
    } catch (e) {
      print('❌ Erreur navigation quote requests: $e');
      _showNavigationError(context);
    }
  }

  /// Navigation vers mes demandes de devis (client)
  static Future<void> _navigateToMyQuoteRequests(BuildContext context,
      int? quoteId, Map<String, dynamic>? extraData) async {
    try {
      print('🔄 Navigation vers MyQuoteRequestsScreen (quote_id: $quoteId)');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MyQuoteRequestsScreen(),
        ),
      );
    } catch (e) {
      print('❌ Erreur navigation my quote requests: $e');
      _showNavigationError(context);
    }
  }

  /// Navigation vers une offre de projet spécifique
  static Future<void> _navigateToProjectOffer(BuildContext context,
      int? offerId, Map<String, dynamic>? extraData) async {
    try {
      final projectId = extraData?['project_id'] as int? ?? offerId;

      print(
          '🔄 Navigation vers projet (project_id: $projectId, offer_id: $offerId)');

      if (projectId != null) {
        // Navigation vers le détail du projet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(
              projectId: projectId,
            ),
          ),
        );
      } else {
        // Fallback vers la liste des projets
        print('❌ Pas de project_id, fallback vers ProjectsListScreen');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProjectsListScreen(),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur navigation offre: $e');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProjectsListScreen(),
        ),
      );
    }
  }

  /// Navigation vers un projet spécifique
  static Future<void> _navigateToProject(BuildContext context, int? projectId,
      Map<String, dynamic>? extraData) async {
    try {
      final actualProjectId = extraData?['project_id'] as int? ?? projectId;

      print('🔄 Navigation vers projet (project_id: $actualProjectId)');

      if (actualProjectId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(
              projectId: actualProjectId,
            ),
          ),
        );
      } else {
        print('❌ Pas de project_id, fallback vers ProjectsListScreen');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProjectsListScreen(),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur navigation projet: $e');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProjectsListScreen(),
        ),
      );
    }
  }

  /// Navigation vers un avis spécifique
  static Future<void> _navigateToReview(BuildContext context, int? reviewId,
      Map<String, dynamic>? extraData) async {
    if (reviewId == null) {
      print('❌ Pas de reviewId');
      return;
    }

    try {
      final serviceId = extraData?['service_id'] as int?;
      final providerId = extraData?['provider_id'] as int?;

      print(
          '🔄 Navigation vers avis (review_id: $reviewId, service_id: $serviceId, provider_id: $providerId)');

      if (serviceId != null && providerId != null) {
        // Navigation vers le service concerné
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(
              serviceId: serviceId,
              providerId: providerId,
            ),
          ),
        );
      } else {
        // Fallback vers le profil pour voir les avis
        await _navigateToProfile(context);
      }
    } catch (e) {
      print('❌ Erreur navigation avis: $e');
      await _navigateToProfile(context);
    }
  }

  /// Navigation vers un favori
  static Future<void> _navigateToFavorite(BuildContext context, int? itemId,
      Map<String, dynamic>? extraData) async {
    if (itemId == null) return;

    try {
      final itemType = extraData?['item_type'] as String?;

      print('🔄 Navigation vers favori (item_id: $itemId, type: $itemType)');

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
          // Navigation vers le profil du prestataire
          // Vous pourriez avoir un ProviderDetailScreen
          print('⚠️ Navigation vers provider non implémentée');
          break;
        default:
          print('❌ Type de favori non géré: $itemType');
          break;
      }
    } catch (e) {
      print('❌ Erreur navigation favori: $e');
    }
  }

  /// Navigation vers un litige
 static Future<void> _navigateToDispute(BuildContext context, int? disputeId,
    Map<String, dynamic>? extraData) async {
  try {
    print('🔄 Navigation vers litige (dispute_id: $disputeId)');

    if (disputeId != null) {
      // Navigation vers le détail du litige
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisputeDetailScreen(disputeId: disputeId),
        ),
      );
    } else {
      // Fallback vers la liste des litiges
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DisputesScreen(), // ou ton écran de liste
        ),
      );
    }
  } catch (e) {
    print('❌ Erreur navigation litige: $e');
    _showNavigationError(context);
  }
}

  /// Navigation vers le profil
  static Future<void> _navigateToProfile(BuildContext context) async {
    try {
      print('🔄 Navigation vers ProfileScreen');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
    } catch (e) {
      print('❌ Erreur navigation profil: $e');
      _showNavigationError(context);
    }
  }

  // ===== MÉTHODES UTILITAIRES =====

  /// Afficher un message quand le type de notification n'est pas géré
  static void _showNotificationNotHandled(
      BuildContext context, String notificationType) {
    print('⚠️ Type de notification non géré: $notificationType');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Type de notification "$notificationType" non géré pour la navigation.',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Afficher un message d'erreur de navigation
  static void _showNavigationError(BuildContext context) {
    print('❌ Erreur de navigation');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erreur lors de la navigation. Veuillez réessayer.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
