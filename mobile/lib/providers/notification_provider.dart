import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../core/models/notification_model.dart';
import '../core/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService;
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;
  Timer? _refreshTimer;
  bool _disposed = false;

  NotificationProvider(this._notificationService) {
    _startPeriodicRefresh();
  }

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;
  bool get hasError => _errorMessage != null;

  /// Charger les notifications
  Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (_disposed) return;
    
    if (_isLoading && !forceRefresh) return;
    
    _setLoading(true);
    _clearError();

    try {
      print('🔔 Chargement des notifications...');
      
      final fetchedNotifications = await _notificationService.getNotifications();
      
      if (!_disposed) {
        _notifications = fetchedNotifications;
        _updateUnreadCount();
        print('✅ ${_notifications.length} notifications chargées');
      }
      
    } catch (e) {
      if (!_disposed) {
        print('❌ Erreur lors du chargement des notifications: $e');
        _setError('Erreur lors du chargement des notifications: $e');
      }
    } finally {
      if (!_disposed) {
        _setLoading(false);
      }
    }
  }

  /// Charger le nombre de notifications non lues
  Future<void> loadUnreadCount() async {
    if (_disposed) return;
    
    try {
      final count = await _notificationService.getUnreadCount();
      if (!_disposed) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du compteur: $e');
    }
  }

  /// Marquer une notification comme lue
  Future<bool> markAsRead(int notificationId) async {
    if (_disposed) return false;
    
    try {
      print('✅ Marquage de la notification $notificationId comme lue...');
      
      final success = await _notificationService.markAsRead(notificationId);
      
      if (success && !_disposed) {
        _updateNotificationReadStatus(notificationId, true);
        print('✅ Notification marquée comme lue');
      }
      
      return success;
      
    } catch (e) {
      print('❌ Erreur lors du marquage comme lu: $e');
      if (!_disposed) {
        _setError('Erreur lors du marquage comme lu: $e');
      }
      return false;
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    if (_disposed) return false;
    
    try {
      print('✅ Marquage de toutes les notifications comme lues...');
      
      final success = await _notificationService.markAllAsRead();
      
      if (success && !_disposed) {
        // Marquer toutes les notifications comme lues localement
        for (int i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].isRead) {
            _notifications[i] = _notifications[i].copyWith(isRead: true);
          }
        }
        _unreadCount = 0;
        notifyListeners();
        print('✅ Toutes les notifications marquées comme lues');
      }
      
      return success;
      
    } catch (e) {
      print('❌ Erreur lors du marquage global comme lu: $e');
      if (!_disposed) {
        _setError('Erreur lors du marquage global comme lu: $e');
      }
      return false;
    }
  }

  /// Supprimer une notification
  Future<bool> deleteNotification(int notificationId) async {
    if (_disposed) return false;
    
    try {
      print('🗑️ Suppression de la notification $notificationId...');
      
      final success = await _notificationService.deleteNotification(notificationId);
      
      if (success && !_disposed) {
        final removedNotification = _notifications.firstWhere(
          (n) => n.id == notificationId,
          orElse: () => throw Exception('Notification not found'),
        );
        
        _notifications.removeWhere((n) => n.id == notificationId);
        
        if (!removedNotification.isRead) {
          _unreadCount = math.max(0, _unreadCount - 1);
        }
        
        notifyListeners();
        print('✅ Notification supprimée');
      }
      
      return success;
      
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      if (!_disposed) {
        _setError('Erreur lors de la suppression: $e');
      }
      return false;
    }
  }

  /// Obtenir une notification par ID
  NotificationModel? getNotificationById(int id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Ajouter une nouvelle notification (pour les websockets par exemple)
  void addNotification(NotificationModel notification) {
    if (_disposed) return;
    
    // Éviter les doublons
    if (_notifications.any((n) => n.id == notification.id)) {
      return;
    }
    
    _notifications.insert(0, notification);
    
    if (!notification.isRead) {
      _unreadCount++;
    }
    
    print('✅ Added new notification: ${notification.title}');
    notifyListeners();
  }
  
  /// Mettre à jour le statut de lecture d'une notification
  void _updateNotificationReadStatus(int notificationId, bool isRead) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _notifications[index];
      
      if (notification.isRead != isRead) {
        _notifications[index] = notification.copyWith(isRead: isRead);
        
        if (isRead && !notification.isRead) {
          _unreadCount = math.max(0, _unreadCount - 1);
        } else if (!isRead && notification.isRead) {
          _unreadCount++;
        }
        
        notifyListeners();
      }
    }
  }

  /// Mettre à jour le compteur de notifications non lues
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  /// Effacer les erreurs
  void clearError() {
    if (_disposed) return;
    _clearError();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Démarrer le rafraîchissement périodique
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_disposed) {
        loadUnreadCount();
      }
    });
    print('🔔 Started periodic refresh');
  }

  /// Arrêter le rafraîchissement périodique
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('🔔 Stopped periodic refresh');
  }

  /// Rafraîchir manuellement
  Future<void> refresh() async {
    await loadNotifications(forceRefresh: true);
  }

  /// Vérifier s'il y a de nouvelles notifications
  Future<bool> hasNewNotifications() async {
    try {
      final currentCount = await _notificationService.getUnreadCount();
      return currentCount > _unreadCount;
    } catch (e) {
      print('❌ Error checking for new notifications: $e');
      return false;
    }
  }

  // ========================================
  // MÉTHODES POUR LES TEMPS RÉEL
  // ========================================

  /// Marquer comme lu localement (pour WebSocket)
  void markAsReadLocally(int notificationId) {
    _updateNotificationReadStatus(notificationId, true);
  }

  /// Supprimer localement (pour WebSocket)
  void removeNotificationLocally(int notificationId) {
    if (_disposed) return;
    
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications.removeAt(index);
      
      if (!notification.isRead) {
        _unreadCount = math.max(0, _unreadCount - 1);
      }
      
      notifyListeners();
    }
  }

  /// Mettre à jour le compteur localement (pour WebSocket)
  void updateUnreadCountLocally(int count) {
    if (_disposed) return;
    
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  /// Mettre à jour une notification localement
  void updateNotificationLocally(NotificationModel updatedNotification) {
    if (_disposed) return;
    
    final index = _notifications.indexWhere((n) => n.id == updatedNotification.id);
    if (index != -1) {
      final oldNotification = _notifications[index];
      _notifications[index] = updatedNotification;
      
      // Mettre à jour le compteur si le statut de lecture a changé
      if (oldNotification.isRead != updatedNotification.isRead) {
        if (updatedNotification.isRead && !oldNotification.isRead) {
          _unreadCount = math.max(0, _unreadCount - 1);
        } else if (!updatedNotification.isRead && oldNotification.isRead) {
          _unreadCount++;
        }
      }
      
      notifyListeners();
    }
  }

  /// Nettoyer les données
  void clearNotifications() {
    if (_disposed) return;
    
    _notifications.clear();
    _unreadCount = 0;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    print('🔔 NotificationProvider disposing...');
    _disposed = true;
    stopPeriodicRefresh();
    super.dispose();
  }
}
// mobile/lib/ui/screens/notifications_screen.dart - Écran des notifications
