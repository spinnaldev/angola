// lib/core/services/fcm_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8004/api',
    apiKey: 'your_api_key_here',
  );

  String? _fcmToken;
  bool _isInitialized = false;

  /// Initialiser FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔔 Initialisation FCM...');

      // 1. Demander les permissions
      await _requestPermissions();

      // 2. Initialiser les notifications locales
      await _initializeLocalNotifications();

      // 3. Obtenir le token FCM
      await _getFCMToken();

      // 4. Configurer les gestionnaires de messages
      _setupMessageHandlers();

      // 5. S'abonner aux topics par défaut
      await _subscribeToTopics();

      _isInitialized = true;
      print('✅ FCM initialisé avec succès');
    } catch (e) {
      print('❌ Erreur initialisation FCM: $e');
    }
  }

  /// Demander les permissions de notification
  Future<void> _requestPermissions() async {
    print('📝 Demande des permissions...');

    // Permission Firebase Messaging
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('📝 Status FCM: ${settings.authorizationStatus}');
    print('📱 Alert: ${settings.alert}');
    print('🔔 Sound: ${settings.sound}');
    print('🔢 Badge: ${settings.badge}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permissions FCM accordées');
    } else {
      print('❌ Permissions FCM refusées');
    }

    // Permission système (Android)
    if (Platform.isAndroid) {
      final permission = await Permission.notification.request();
      print('📱 Permission système Android: ${permission}');

      if (!permission.isGranted) {
        print('❌ Permission système Android refusée');
        // Demander à l'utilisateur d'aller dans les paramètres
        bool opened = await openAppSettings();
        print('⚙️ Paramètres ouverts: $opened');
      }
    }
    // if (!kIsWeb) {
    //   final permission = await Permission.notification.request();
    //   if (permission.isGranted) {
    //     print('✅ Permissions système accordées');
    //   } else {
    //     print('❌ Permissions système refusées');
    //   }
    // }
  }

  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // ID
        'High Importance Notifications', // Nom
        description: 'Canal pour notifications importantes',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print('✅ Canal de notification Android créé');
    }
  }

  
  /// Modifier _initializeLocalNotifications pour ajouter le canal
 
 
  /// Ajouter méthode de test de notification locale
  Future<void> testLocalNotification() async {
    print('🧪 Test notification locale...');
    
    await _localNotifications.show(
      999, // ID unique
      '🎉 Test Teyago',
      'Si tu vois cette notification, le système fonctionne !',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel', // Même ID que le canal créé
          'Notifications importantes',
          channelDescription: 'Canal pour toutes les notifications importantes',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Test Notification',
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
    
    print('✅ Notification locale envoyée');
  }

  /// Améliorer _showLocalNotification pour utiliser le bon canal
  Future<void> _showLocalNotification(RemoteMessage message) async {
    print('📱 Affichage notification locale: ${message.notification?.title}');
    
    await _localNotifications.show(
      message.hashCode, // ID unique basé sur le message
      message.notification?.title ?? 'Nouvelle notification',
      message.notification?.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel', // 🔥 Utiliser le canal créé
          'Notifications importantes',
          channelDescription: 'Canal pour toutes les notifications importantes',
          importance: Importance.max,
          priority: Priority.high,
          ticker: message.notification?.title,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  /// Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    print('🔔 Initialisation notifications locales...');

    _createNotificationChannel();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('✅ Notifications locales initialisées');
  }

  /// Obtenir le token FCM
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('🔑 Token FCM: ${_fcmToken?.substring(0, 20)}...');

      if (_fcmToken != null) {
        // Envoyer le token au backend
        await _sendTokenToBackend(_fcmToken!);
      }

      return _fcmToken;
    } catch (e) {
      print('❌ Erreur obtention token FCM: $e');
      return null;
    }
  }

  /// Envoyer le token au backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      print('📤 Envoi du token FCM au backend...');

      await _apiService.updateFCMToken(token);
      print('✅ Token FCM envoyé au backend');
    } catch (e) {
      print('❌ Erreur envoi token FCM: $e');
    }
  }

  /// Configurer les gestionnaires de messages
  void _setupMessageHandlers() {
    print('⚙️ Configuration des gestionnaires FCM...');

    // Messages reçus quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Messages reçus quand l'app est en arrière-plan et qu'on clique dessus
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Vérifier si l'app a été ouverte depuis une notification
    _checkInitialMessage();

    // Écouter les changements de token
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 Nouveau token FCM: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      _sendTokenToBackend(newToken);
    });
  }

  /// Gérer les messages quand l'app est au premier plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Message FCM reçu (app ouverte): ${message.notification?.title}');
    print('🔥 === MESSAGE FCM REÇU ===');
    print('📱 App au premier plan: OUI');
    print('📄 Title: ${message.notification?.title}');
    print('📝 Body: ${message.notification?.body}');
    print('🏷️ Data: ${message.data}');
    print('========================');
    // Afficher une notification locale
    await _showLocalNotification(message);

    // Traiter les données du message
    await _processMessageData(message);
  }

  /// Gérer les messages quand l'app est en arrière-plan
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📨 Message FCM ouvert (app fermée): ${message.notification?.title}');

    // Traiter les données du message
    await _processMessageData(message);

    // Naviguer vers l'écran approprié si nécessaire
    await _navigateFromNotification(message);
  }

  /// Vérifier si l'app a été ouverte depuis une notification
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      print(
          '📨 App ouverte depuis notification: ${initialMessage.notification?.title}');
      await _handleBackgroundMessage(initialMessage);
    }
  }

  
  /// Traiter les données du message
  Future<void> _processMessageData(RemoteMessage message) async {
    try {
      final data = message.data;
      print('📊 Données du message: $data');

      // Selon le type de notification, effectuer différentes actions
      final notificationType = data['type'] ?? '';

      switch (notificationType) {
        case 'new_message':
          // Mettre à jour les conversations
          await _handleNewMessageNotification(data);
          break;
        case 'new_offer':
          // Mettre à jour les offres
          await _handleNewOfferNotification(data);
          break;
        case 'project_update':
          // Mettre à jour les projets
          await _handleProjectUpdateNotification(data);
          break;
        default:
          print('🔔 Type de notification non géré: $notificationType');
      }
    } catch (e) {
      print('❌ Erreur traitement données message: $e');
    }
  }

  /// Gérer les notifications de nouveaux messages
  Future<void> _handleNewMessageNotification(Map<String, dynamic> data) async {
    print('💬 Nouvelle notification de message');
    // Ici vous pouvez mettre à jour votre MessagingProvider
    // par exemple: messagingProvider.refreshConversations();
  }

  /// Gérer les notifications de nouvelles offres
  Future<void> _handleNewOfferNotification(Map<String, dynamic> data) async {
    print('💼 Nouvelle notification d\'offre');
    // Ici vous pouvez mettre à jour votre OffersProvider
  }

  /// Gérer les notifications de mise à jour de projet
  Future<void> _handleProjectUpdateNotification(
      Map<String, dynamic> data) async {
    print('📋 Nouvelle notification de projet');
    // Ici vous pouvez mettre à jour votre ProjectProvider
  }

  /// Naviguer depuis une notification
  Future<void> _navigateFromNotification(RemoteMessage message) async {
    final data = message.data;
    final notificationType = data['type'] ?? '';

    // Navigation selon le type
    switch (notificationType) {
      case 'new_message':
        final conversationId = data['conversation_id'];
        if (conversationId != null) {
          // Naviguer vers la conversation
          print('🧭 Navigation vers conversation: $conversationId');
        }
        break;
      case 'new_offer':
        final projectId = data['project_id'];
        if (projectId != null) {
          // Naviguer vers le projet
          print('🧭 Navigation vers projet: $projectId');
        }
        break;
    }
  }

  /// Gestionnaire de clic sur notification locale
  void _onNotificationTapped(NotificationResponse response) async {
    print('👆 Notification cliquée: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        // Traiter les données et naviguer
        await _processNotificationTap(data);
      } catch (e) {
        print('❌ Erreur traitement clic notification: $e');
      }
    }
  }

  /// Traiter le clic sur notification
  Future<void> _processNotificationTap(Map<String, dynamic> data) async {
    // Similar à _navigateFromNotification mais pour les notifications locales
    print('📱 Traitement clic notification locale: $data');
  }

  /// S'abonner aux topics
  Future<void> _subscribeToTopics() async {
    try {
      print('📢 Abonnement aux topics...');

      // Topics généraux
      await _firebaseMessaging.subscribeToTopic('all_users');
      await _firebaseMessaging.subscribeToTopic('general_updates');

      print('✅ Abonné aux topics');
    } catch (e) {
      print('❌ Erreur abonnement topics: $e');
    }
  }

  /// S'abonner à un topic spécifique
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Abonné au topic: $topic');
    } catch (e) {
      print('❌ Erreur abonnement topic $topic: $e');
    }
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Désabonné du topic: $topic');
    } catch (e) {
      print('❌ Erreur désabonnement topic $topic: $e');
    }
  }

  /// Obtenir le token FCM actuel
  String? get currentToken => _fcmToken;

  /// Vérifier si FCM est initialisé
  bool get isInitialized => _isInitialized;
}

// Gestionnaire de messages en arrière-plan (obligatoire au niveau top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Message FCM en arrière-plan: ${message.notification?.title}');
}
