// lib/providers/fcm_provider.dart
import 'package:flutter/material.dart';
import '../core/services/fcm_service.dart';
import '../core/services/api_service.dart';

class FCMProvider extends ChangeNotifier {
  final FCMService _fcmService;
  final ApiService _apiService;

  FCMProvider(this._fcmService, this._apiService);

  // État
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _fcmToken;
  Map<String, bool> _notificationPreferences = {
    'messages': true,
    'offers': true,
    'projects': true,
    'reviews': true,
    'system': true,
  };

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get fcmToken => _fcmToken;
  Map<String, bool> get notificationPreferences => Map.from(_notificationPreferences);

  /// Initialiser FCM
  Future<void> initializeFCM() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    _clearError();

    try {
      print('🔔 Initialisation FCM via Provider...');
      
      // Initialiser le service FCM
      await _fcmService.initialize();
      
      // Récupérer le token
      _fcmToken = _fcmService.currentToken;
      
      // Charger les préférences de notification
      await _loadNotificationPreferences();
      
      _isInitialized = true;
      print('✅ FCM Provider initialisé');
      
    } catch (e) {
      _errorMessage = 'Erreur initialisation notifications: $e';
      print('❌ Erreur FCM Provider: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  /// Charger les préférences de notification depuis le backend
  Future<void> _loadNotificationPreferences() async {
    try {
      print('📥 Chargement des préférences de notification...');
      
      // Ici vous pouvez appeler votre API pour récupérer les préférences
      // Pour l'instant, on utilise les valeurs par défaut
      
      print('✅ Préférences de notification chargées');
      
    } catch (e) {
      print('❌ Erreur chargement préférences: $e');
      // Utiliser les valeurs par défaut en cas d'erreur
    }
  }

  /// Mettre à jour une préférence de notification
  Future<void> updateNotificationPreference(String type, bool enabled) async {
    _setLoading(true);
    _clearError();

    try {
      print('⚙️ Mise à jour préférence $type: $enabled');
      
      // Mettre à jour localement
      _notificationPreferences[type] = enabled;
      notifyListeners();
      
      // Envoyer au backend
      final success = await _apiService.updateNotificationPreferences(_notificationPreferences);
      
      if (success) {
        print('✅ Préférence mise à jour');
        
        // S'abonner/désabonner des topics FCM selon la préférence
        await _updateTopicSubscription(type, enabled);
        
      } else {
        // Annuler le changement local en cas d'échec
        _notificationPreferences[type] = !enabled;
        _errorMessage = 'Erreur mise à jour préférence';
      }
      
    } catch (e) {
      // Annuler le changement local en cas d'erreur
      _notificationPreferences[type] = !enabled;
      _errorMessage = 'Erreur mise à jour préférence: $e';
      print('❌ Erreur mise à jour préférence: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Gérer les abonnements aux topics selon les préférences
  Future<void> _updateTopicSubscription(String type, bool enabled) async {
    try {
      final topic = _getTopicForType(type);
      if (topic != null) {
        if (enabled) {
          await _fcmService.subscribeToTopic(topic);
        } else {
          await _fcmService.unsubscribeFromTopic(topic);
        }
      }
    } catch (e) {
      print('❌ Erreur mise à jour topic: $e');
    }
  }

  /// Obtenir le nom du topic pour un type de notification
  String? _getTopicForType(String type) {
    switch (type) {
      case 'messages':
        return 'user_messages';
      case 'offers':
        return 'user_offers';
      case 'projects':
        return 'user_projects';
      case 'reviews':
        return 'user_reviews';
      case 'system':
        return 'system_notifications';
      default:
        return null;
    }
  }

  /// Envoyer une notification de test
  Future<void> sendTestNotification() async {
    _setLoading(true);
    _clearError();

    try {
      print('🧪 Envoi notification de test...');
      
      final success = await _apiService.sendTestNotification();
      
      if (success) {
        print('✅ Notification de test envoyée');
      } else {
        _errorMessage = 'Erreur envoi notification de test';
      }
      
    } catch (e) {
      _errorMessage = 'Erreur envoi notification de test: $e';
      print('❌ Erreur test notification: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Rafraîchir le token FCM
  Future<void> refreshFCMToken() async {
    try {
      print('🔄 Rafraîchissement token FCM...');
      
      // Le service FCM gère automatiquement le refresh des tokens
      _fcmToken = _fcmService.currentToken;
      notifyListeners();
      
      print('✅ Token FCM rafraîchi');
      
    } catch (e) {
      print('❌ Erreur rafraîchissement token: $e');
    }
  }

  /// S'abonner à un topic personnalisé
  Future<void> subscribeToCustomTopic(String topic) async {
    try {
      await _fcmService.subscribeToTopic(topic);
      print('✅ Abonné au topic personnalisé: $topic');
    } catch (e) {
      print('❌ Erreur abonnement topic personnalisé: $e');
    }
  }

  /// Se désabonner d'un topic personnalisé
  Future<void> unsubscribeFromCustomTopic(String topic) async {
    try {
      await _fcmService.unsubscribeFromTopic(topic);
      print('✅ Désabonné du topic personnalisé: $topic');
    } catch (e) {
      print('❌ Erreur désabonnement topic personnalisé: $e');
    }
  }

  /// Vérifier si les notifications sont activées pour un type
  bool isNotificationEnabled(String type) {
    return _notificationPreferences[type] ?? false;
  }

  /// Activer toutes les notifications
  Future<void> enableAllNotifications() async {
    _setLoading(true);
    try {
      final newPreferences = <String, bool>{};
      for (String key in _notificationPreferences.keys) {
        newPreferences[key] = true;
      }
      
      _notificationPreferences = newPreferences;
      notifyListeners();
      
      await _apiService.updateNotificationPreferences(_notificationPreferences);
      
      // S'abonner à tous les topics
      for (String type in _notificationPreferences.keys) {
        await _updateTopicSubscription(type, true);
      }
      
      print('✅ Toutes les notifications activées');
      
    } catch (e) {
      _errorMessage = 'Erreur activation notifications: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Désactiver toutes les notifications
  Future<void> disableAllNotifications() async {
    _setLoading(true);
    try {
      final newPreferences = <String, bool>{};
      for (String key in _notificationPreferences.keys) {
        newPreferences[key] = false;
      }
      
      _notificationPreferences = newPreferences;
      notifyListeners();
      
      await _apiService.updateNotificationPreferences(_notificationPreferences);
      
      // Se désabonner de tous les topics
      for (String type in _notificationPreferences.keys) {
        await _updateTopicSubscription(type, false);
      }
      
      print('✅ Toutes les notifications désactivées');
      
    } catch (e) {
      _errorMessage = 'Erreur désactivation notifications: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Nettoyer lors de la déconnexion
  Future<void> cleanup() async {
    try {
      print('🧹 Nettoyage FCM Provider...');
      
      if (_fcmToken != null) {
        await _apiService.removeFCMToken(_fcmToken!);
      }
      
      _isInitialized = false;
      _fcmToken = null;
      _notificationPreferences.clear();
      
      print('✅ FCM Provider nettoyé');
      
    } catch (e) {
      print('❌ Erreur nettoyage FCM: $e');
    }
  }

  // Méthodes utilitaires
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}