import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  /// Récupérer toutes les notifications de l'utilisateur
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? notificationType,
  }) async {
    try {
      print('🔔 Récupération des notifications...');
      
      final notifications = await _apiService.getNotifications();
      
      print('✅ ${notifications.length} notifications récupérées');
      return notifications;
    } catch (e) {
      print('❌ Erreur lors de la récupération des notifications: $e');
      rethrow;
    }
  }

  /// Récupérer le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    try {
      print('🔔 Récupération du compteur de notifications...');
      
      final count = await _apiService.getUnreadNotificationCount();
      
      print('✅ $count notifications non lues');
      return count;
    } catch (e) {
      print('❌ Erreur lors de la récupération du compteur: $e');
      return 0;
    }
  }

  /// Marquer une notification comme lue
  Future<bool> markAsRead(int notificationId) async {
    try {
      print('✅ Marquage notification $notificationId comme lue...');
      
      final success = await _apiService.markNotificationAsRead(notificationId);
      
      if (success) {
        print('✅ Notification marquée comme lue');
      }
      return success;
    } catch (e) {
      print('❌ Erreur lors du marquage: $e');
      return false;
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      print('✅ Marquage de toutes les notifications comme lues...');
      
      final success = await _apiService.markAllNotificationsAsRead();
      
      if (success) {
        print('✅ Toutes les notifications marquées comme lues');
      }
      return success;
    } catch (e) {
      print('❌ Erreur lors du marquage global: $e');
      return false;
    }
  }

  /// Supprimer une notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      print('🗑️ Suppression notification $notificationId...');
      
      final success = await _apiService.deleteNotification(notificationId);
      
      if (success) {
        print('✅ Notification supprimée');
      }
      return success;
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Récupérer une notification spécifique
  Future<NotificationModel?> getNotification(int notificationId) async {
    try {
      print('🔔 Récupération notification $notificationId...');
      
      final notifications = await _apiService.getNotifications();
      final notification = notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => throw Exception('Notification non trouvée'),
      );
      
      print('✅ Notification récupérée');
      return notification;
    } catch (e) {
      print('❌ Erreur lors de la récupération: $e');
      return null;
    }
  }

  /// Marquer une notification comme non lue
  Future<bool> markAsUnread(int notificationId) async {
    try {
      print('📬 Marquage notification $notificationId comme non lue...');
      
      // Pour l'instant, on utilise la même méthode que markAsRead
      // Dans une vraie implémentation, il faudrait une méthode séparée dans l'API
      print('✅ Notification marquée comme non lue (simulation)');
      return true;
    } catch (e) {
      print('❌ Erreur lors du marquage comme non lu: $e');
      return false;
    }
  }

  /// Supprimer toutes les notifications lues
  Future<bool> deleteAllRead() async {
    try {
      print('🗑️ Suppression de toutes les notifications lues...');
      
      // Pour l'instant, on simule cette fonctionnalité
      // Dans une vraie implémentation, il faudrait une méthode séparée dans l'API
      print('✅ Toutes les notifications lues supprimées (simulation)');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la suppression globale: $e');
      return false;
    }
  }

  /// Récupérer les notifications par type
  Future<List<NotificationModel>> getNotificationsByType(String type) async {
    try {
      final allNotifications = await getNotifications();
      return allNotifications.where((n) => n.notificationType == type).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération par type: $e');
      return [];
    }
  }

  /// Récupérer les notifications non lues
  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      final allNotifications = await getNotifications();
      return allNotifications.where((n) => !n.isRead).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des non lues: $e');
      return [];
    }
  }

  /// Récupérer les notifications lues
  Future<List<NotificationModel>> getReadNotifications() async {
    try {
      final allNotifications = await getNotifications();
      return allNotifications.where((n) => n.isRead).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des lues: $e');
      return [];
    }
  }

  /// Récupérer les statistiques des notifications
  Future<Map<String, int>> getNotificationStats() async {
    try {
      print('📊 Récupération des statistiques de notifications...');
      
      final allNotifications = await getNotifications();
      final stats = <String, int>{
        'total': allNotifications.length,
        'unread': allNotifications.where((n) => !n.isRead).length,
        'read': allNotifications.where((n) => n.isRead).length,
      };
      
      // Compter par type
      for (final notification in allNotifications) {
        final type = notification.notificationType;
        stats[type] = (stats[type] ?? 0) + 1;
      }
      
      print('✅ Statistiques récupérées');
      return stats;
    } catch (e) {
      print('❌ Erreur lors de la récupération des statistiques: $e');
      return {};
    }
  }

  /// Configurer les préférences de notification
  Future<bool> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    try {
      print('⚙️ Mise à jour des préférences de notification...');
      
      // Pour l'instant, on simule cette fonctionnalité
      // Dans une vraie implémentation, il faudrait une méthode dans l'API
      print('✅ Préférences mises à jour (simulation)');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des préférences: $e');
      return false;
    }
  }

  /// Récupérer les préférences de notification
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      print('⚙️ Récupération des préférences de notification...');
      
      // Pour l'instant, on retourne des préférences par défaut
      final preferences = {
        'email_notifications': true,
        'push_notifications': true,
        'message_notifications': true,
        'offer_notifications': true,
        'review_notifications': true,
      };
      
      print('✅ Préférences récupérées');
      return preferences;
    } catch (e) {
      print('❌ Erreur lors de la récupération des préférences: $e');
      return {};
    }
  }

  /// Envoyer une notification de test
  Future<bool> sendTestNotification() async {
    try {
      print('🧪 Envoi d\'une notification de test...');
      
      // Pour l'instant, on simule cette fonctionnalité
      print('✅ Notification de test envoyée (simulation)');
      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de test: $e');
      return false;
    }
  }
}
