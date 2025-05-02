import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;
  int _unreadCount = 0;
  
  NotificationProvider(this._apiService);
  
  int get unreadCount => _unreadCount;
  
  // Méthode pour charger le nombre de notifications non lues
  Future<void> loadUnreadCount() async {
    try {
      final count = await _apiService.getUnreadNotificationCount();
      _unreadCount = count;
      notifyListeners();
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }
  
  // Méthode pour marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      final success = await _apiService.markAllNotificationsAsRead();
      if (success) {
        _unreadCount = 0;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error marking notifications as read: $e');
      return false;
    }
  }
  
}