// lib/providers/realtime_notification_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/services/websocket_service.dart';
import '../core/models/notification_model.dart';
import 'notification_provider.dart';

class RealtimeNotificationProvider with ChangeNotifier {
  final NotificationProvider _notificationProvider;
  final WebSocketService _webSocketService;
  
  StreamSubscription<Map<String, dynamic>>? _webSocketSubscription;
  bool _isListening = false;
  
  RealtimeNotificationProvider(this._notificationProvider, this._webSocketService);

  // Getters
  bool get isListening => _isListening;
  
  /// Démarrer l'écoute des notifications en temps réel
  void startListening() {
    if (_isListening) {
      print('🔔 Déjà en écoute des notifications en temps réel');
      return;
    }

    print('🔔 Démarrage de l\'écoute des notifications en temps réel');
    
    _webSocketSubscription = _webSocketService.messageStream?.listen(
      _handleWebSocketMessage,
      onError: (error) {
        print('❌ Erreur WebSocket notifications: $error');
      },
    );
    
    _isListening = true;
    print('✅ Écoute des notifications en temps réel activée');
  }

  /// Arrêter l'écoute des notifications en temps réel
  void stopListening() {
    if (!_isListening) return;

    print('🔔 Arrêt de l\'écoute des notifications en temps réel');
    
    _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    _isListening = false;
    
    print('✅ Écoute des notifications en temps réel désactivée');
  }

  /// Gérer les messages WebSocket
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    
    switch (type) {
      case 'notification_message':
        _handleNewNotification(message);
        break;
      case 'notification_update':
        _handleNotificationUpdate(message);
        break;
      case 'unread_count_update':
        _handleUnreadCountUpdate(message);
        break;
      case 'counts_update':
        _handleCountsUpdate(message);
        break;
      case 'connection_established':
        _handleConnectionEstablished(message);
        break;
      default:
        // Ignorer les autres types de messages
        break;
    }
  }

  /// Gérer une nouvelle notification
  void _handleNewNotification(Map<String, dynamic> message) {
    try {
      final notificationData = message['notification'] as Map<String, dynamic>?;
      if (notificationData == null) return;

      print('📨 Nouvelle notification reçue: ${notificationData['title']}');

      // Créer l'objet notification
      final notification = NotificationModel.fromJson(notificationData);
      
      // Ajouter la notification au provider
      _notificationProvider.addNotification(notification);
      
      // Notifier les listeners
      notifyListeners();
      
    } catch (e) {
      print('❌ Erreur lors du traitement de la nouvelle notification: $e');
    }
  }

  /// Gérer les mises à jour de notifications
  void _handleNotificationUpdate(Map<String, dynamic> message) {
    try {
      final eventType = message['event_type'] as String?;
      
      switch (eventType) {
        case 'new_notification':
          _handleNewNotification(message);
          break;
        case 'notification_read':
          _handleNotificationRead(message);
          break;
        case 'notification_deleted':
          _handleNotificationDeleted(message);
          break;
        default:
          print('🔔 Type d\'événement de notification non géré: $eventType');
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de la mise à jour de notification: $e');
    }
  }

  /// Gérer une notification marquée comme lue
  void _handleNotificationRead(Map<String, dynamic> message) {
    try {
      final notificationId = message['notification_id'] as int?;
      if (notificationId == null) return;

      print('✅ Notification marquée comme lue: $notificationId');
      
      // Mettre à jour la notification dans le provider
      _notificationProvider.markAsReadLocally(notificationId);
      
      notifyListeners();
      
    } catch (e) {
      print('❌ Erreur lors du marquage de la notification comme lue: $e');
    }
  }

  /// Gérer une notification supprimée
  void _handleNotificationDeleted(Map<String, dynamic> message) {
    try {
      final notificationId = message['notification_id'] as int?;
      if (notificationId == null) return;

      print('🗑️ Notification supprimée: $notificationId');
      
      // Supprimer la notification du provider
      _notificationProvider.removeNotificationLocally(notificationId);
      
      notifyListeners();
      
    } catch (e) {
      print('❌ Erreur lors de la suppression de la notification: $e');
    }
  }

  /// Gérer la mise à jour du compteur de notifications non lues
  void _handleUnreadCountUpdate(Map<String, dynamic> message) {
    try {
      final count = message['count'] as int?;
      if (count == null) return;

      print('🔢 Mise à jour du compteur de notifications: $count');
      
      // Mettre à jour le compteur dans le provider
      _notificationProvider.updateUnreadCountLocally(count);
      
      notifyListeners();
      
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du compteur: $e');
    }
  }

  /// Gérer les mises à jour générales de compteurs
  void _handleCountsUpdate(Map<String, dynamic> message) {
    try {
      final eventType = message['event_type'] as String?;
      
      switch (eventType) {
        case 'notification_count_update':
          final notificationCount = message['notification_count'] as int?;
          if (notificationCount != null) {
            _notificationProvider.updateUnreadCountLocally(notificationCount);
            notifyListeners();
          }
          break;
        default:
          print('🔔 Type d\'événement de compteur non géré: $eventType');
      }
    } catch (e) {
      print('❌ Erreur lors du traitement de la mise à jour des compteurs: $e');
    }
  }

  /// Gérer la confirmation de connexion
  void _handleConnectionEstablished(Map<String, dynamic> message) {
    print('✅ Connexion WebSocket établie pour les notifications');
    
    // Demander les notifications non lues
    _webSocketService.requestUnreadCount();
  }

  /// Marquer une notification comme lue via WebSocket
  void markNotificationAsRead(int notificationId) {
    if (!_webSocketService.isConnected) {
      print('❌ WebSocket non connecté, impossible de marquer la notification comme lue');
      return;
    }
    
    _webSocketService.markNotificationAsRead(notificationId);
  }

  /// Marquer toutes les notifications comme lues via WebSocket
  void markAllNotificationsAsRead() {
    if (!_webSocketService.isConnected) {
      print('❌ WebSocket non connecté, impossible de marquer toutes les notifications comme lues');
      return;
    }
    
    _webSocketService.markAllNotificationsAsRead();
  }

  /// Demander une mise à jour du compteur de notifications
  void requestUnreadCount() {
    if (!_webSocketService.isConnected) {
      print('❌ WebSocket non connecté, impossible de demander le compteur');
      return;
    }
    
    _webSocketService.requestUnreadCount();
  }

  @override
  void dispose() {
    print('🔔 RealtimeNotificationProvider disposing...');
    stopListening();
    super.dispose();
  }
}