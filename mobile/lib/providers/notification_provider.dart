import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;
import '../core/services/notification_service.dart';
import '../core/models/notification.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService;
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;
  bool _disposed = false;
  
  NotificationProvider(this._notificationService) {
    print('🔔 NotificationProvider initialized');
    
    // Charger les notifications au démarrage
    _initializeNotifications();
    
    // Démarrer le rafraîchissement périodique
    _startPeriodicRefresh();
  }
  
  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Notifications non lues
  List<NotificationModel> get unreadNotifications => 
    _notifications.where((n) => !n.isRead).toList();
  
  // Notifications lues
  List<NotificationModel> get readNotifications => 
    _notifications.where((n) => n.isRead).toList();
  
  // Notifications récentes (24h)
  List<NotificationModel> get recentNotifications {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    return _notifications.where((n) => n.createdAt.isAfter(yesterday)).toList();
  }
  
  // Initialiser les notifications
  Future<void> _initializeNotifications() async {
    try {
      await loadUnreadCount();
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }
  
  // Charger toutes les notifications
  Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (_disposed) return;
    
    if (_isLoading && !forceRefresh) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🔔 Loading notifications...');
      final notifications = await _notificationService.getNotifications();
      
      if (_disposed) return;
      
      _notifications = notifications;
      
      // Mettre à jour le compteur non lu
      _updateUnreadCount();
      
      print('✅ Loaded ${notifications.length} notifications');
      _setLoading(false);
    } catch (e) {
      print('❌ Error loading notifications: $e');
      if (_disposed) return;
      
      _setLoading(false);
      _setError('Erreur lors du chargement des notifications: $e');
    }
  }
  
  // Charger uniquement le compteur de notifications non lues
  Future<void> loadUnreadCount() async {
    if (_disposed) return;
    
    try {
      print('🔔 Loading unread count...');
      final count = await _notificationService.getUnreadCount();
      
      if (_disposed) return;
      
      _unreadCount = count;
      print('✅ Unread count: $count');
      notifyListeners();
    } catch (e) {
      print('❌ Error loading notification count: $e');
    }
  }
  
  // Marquer une notification comme lue
  Future<bool> markAsRead(int notificationId) async {
    if (_disposed) return false;
    
    try {
      print('🔔 Marking notification $notificationId as read...');
      final success = await _notificationService.markAsRead(notificationId);
      
      if (_disposed) return success;
      
      if (success) {
        // Mettre à jour localement
        _updateNotificationReadStatus(notificationId, true);
        print('✅ Notification $notificationId marked as read');
      }
      
      return success;
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }
  
  // Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    if (_disposed) return false;
    
    try {
      print('🔔 Marking all notifications as read...');
      final success = await _notificationService.markAllAsRead();
      
      if (_disposed) return success;
      
      if (success) {
        // Mettre à jour toutes les notifications localement
        _notifications = _notifications.map((notification) => 
          notification.copyWith(isRead: true)
        ).toList();
        
        _unreadCount = 0;
        print('✅ All notifications marked as read');
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return false;
    }
  }
  
  // Supprimer une notification
  Future<bool> deleteNotification(int notificationId) async {
    if (_disposed) return false;
    
    try {
      print('🔔 Deleting notification $notificationId...');
      final success = await _notificationService.deleteNotification(notificationId);
      
      if (_disposed) return success;
      
      if (success) {
        // Supprimer localement
        final notification = _notifications.firstWhere(
          (n) => n.id == notificationId,
          orElse: () => throw StateError('Notification not found'),
        );
        
        _notifications.removeWhere((n) => n.id == notificationId);
        
        if (!notification.isRead) {
          _unreadCount = math.max(0, _unreadCount - 1);
        }
        
        print('✅ Notification $notificationId deleted');
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }
  
  // Filtrer les notifications par type
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.notificationType == type).toList();
  }
  
  // Obtenir une notification par ID
  NotificationModel? getNotificationById(int id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Ajouter une nouvelle notification (pour les websockets par exemple)
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
  
  // Mettre à jour le statut de lecture d'une notification
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
  
  // Mettre à jour le compteur de notifications non lues
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }
  
  // Effacer les erreurs
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
  
  // Démarrer le rafraîchissement périodique
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_disposed) {
        loadUnreadCount();
      }
    });
    print('🔔 Started periodic refresh');
  }
  
  // Arrêter le rafraîchissement périodique
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('🔔 Stopped periodic refresh');
  }
  
  // Rafraîchir manuellement
  Future<void> refresh() async {
    await loadNotifications(forceRefresh: true);
  }
  
  // Vérifier s'il y a de nouvelles notifications
  Future<bool> hasNewNotifications() async {
    try {
      final currentCount = await _notificationService.getUnreadCount();
      return currentCount > _unreadCount;
    } catch (e) {
      print('❌ Error checking for new notifications: $e');
      return false;
    }
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
