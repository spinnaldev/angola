import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  // Récupérer toutes les notifications de l'utilisateur
  Future<List<NotificationModel>> getNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/notifications/?page=$page&page_size=$pageSize'),
        headers: headers,
      );

      print('🔔 Notifications API Response: ${response.statusCode}');
      print('🔔 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Support pour pagination ou liste simple
        List<dynamic> results;
        if (data is Map && data.containsKey('results')) {
          results = data['results'] as List<dynamic>;
        } else if (data is List) {
          results = data;
        } else {
          print('⚠️ Format de réponse inattendu: $data');
          return [];
        }
        
        return results.map((item) => NotificationModel.fromJson(item)).toList();
      } else {
        print('❌ Erreur API notifications: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getNotifications: $e');
      rethrow;
    }
  }

  // Obtenir le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/notifications/unread_count/'),
        headers: headers,
      );

      print('🔔 Unread count API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['count'] ?? 0;
        print('🔔 Unread notifications count: $count');
        return count;
      } else {
        print('⚠️ Failed to get unread count: ${response.statusCode} - ${response.body}');
        return 0;
      }
    } catch (e) {
      print('❌ Error in getUnreadCount: $e');
      return 0;
    }
  }

  // Marquer une notification comme lue
  Future<bool> markAsRead(int notificationId) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/notifications/$notificationId/mark_as_read/'),
        headers: headers,
      );

      print('🔔 Mark as read API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Notification $notificationId marked as read');
        return true;
      } else {
        print('❌ Failed to mark notification as read: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error in markAsRead: $e');
      return false;
    }
  }

  // Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/notifications/mark_all_as_read/'),
        headers: headers,
      );

      print('🔔 Mark all as read API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['count'] ?? 0;
        print('✅ $count notifications marked as read');
        return true;
      } else {
        print('❌ Failed to mark all notifications as read: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error in markAllAsRead: $e');
      return false;
    }
  }

  // Supprimer une notification (si l'API le supporte)
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.delete(
        Uri.parse('${_apiService.baseUrl}/notifications/$notificationId/'),
        headers: headers,
      );

      print('🔔 Delete notification API Response: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Notification $notificationId deleted');
        return true;
      } else {
        print('❌ Failed to delete notification: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error in deleteNotification: $e');
      return false;
    }
  }

  // Récupérer une notification spécifique
  Future<NotificationModel?> getNotification(int notificationId) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/notifications/$notificationId/'),
        headers: headers,
      );

      print('🔔 Get notification API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NotificationModel.fromJson(data);
      } else {
        print('❌ Failed to get notification: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error in getNotification: $e');
      return null;
    }
  }

  // Filtrer les notifications par type
  Future<List<NotificationModel>> getNotificationsByType(String type) async {
    try {
      final headers = await _apiService.getHeaders();
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/notifications/?notification_type=$type'),
        headers: headers,
      );

      print('🔔 Get notifications by type API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> results;
        if (data is Map && data.containsKey('results')) {
          results = data['results'] as List<dynamic>;
        } else if (data is List) {
          results = data;
        } else {
          return [];
        }
        
        return results.map((item) => NotificationModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get notifications by type: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getNotificationsByType: $e');
      rethrow;
    }
  }
}
