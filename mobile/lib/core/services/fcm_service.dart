// lib/core/services/fcm_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:teyago/core/models/notification_model.dart';
import 'package:teyago/core/services/notification_navigation_service.dart';
import '../../main.dart';
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
    print('🔥 === MESSAGE FCM BACKGROUND ===');
    print('📱 App fermée/arrière-plan: OUI');
    print('📄 Title: ${message.notification?.title}');
    print('📝 Body: ${message.notification?.body}');
    print('🏷️ Data: ${message.data}');
    print('===============================');

    // ← SUPPRIMER cette ligne car elle fait double emploi
    // await _processMessageData(message);

    // Navigation directe
    await _navigateFromNotification(message);
  }

  /// Vérifier si l'app a été ouverte depuis une notification
  Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

      if (initialMessage != null) {
        print('🚀 === APP OUVERTE DEPUIS NOTIFICATION ===');
        print('📄 Title: ${initialMessage.notification?.title}');
        print('🏷️ Data: ${initialMessage.data}');
        
        // ← NOUVEAU : NAVIGUER IMMÉDIATEMENT
        await _navigateFromNotification(initialMessage);
      } else {
        print('📱 App ouverte normalement (pas depuis notification)');
      }
    } catch (e) {
      print('❌ Erreur _checkInitialMessage: $e');
    }
  }

  
  /// Traiter les données du message
  Future<void> _processMessageData(RemoteMessage message) async {
    try {
      final data = message.data;
      print('📊 Données du message: $data');

      // Selon le type de notification, effectuer différentes actions
      final notificationType = data['type'] ?? '';

      // switch (notificationType) {
      //   case 'new_message':
      //     // Mettre à jour les conversations
      //     await _handleNewMessageNotification(data);
      //     break;
      //   case 'new_offer':
      //     // Mettre à jour les offres
      //     await _handleNewOfferNotification(data);
      //     break;
      //   case 'project_update':
      //     // Mettre à jour les projets
      //     await _handleProjectUpdateNotification(data);
      //     break;
      //   default:
      //     print('🔔 Type de notification non géré: $notificationType');
      // }
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
    try {
      final data = message.data;
      final notificationType = data['type'] ?? data['notification_type'] ?? '';
      
      print('🧭 === NAVIGATION NOTIFICATION ===');
      print('📱 Type: $notificationType');
      print('🏷️ Data: $data');
      
      // Attendre un peu pour que l'app soit complètement chargée
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Obtenir le context depuis la navigation key
      final context = navigatorKey.currentContext;
      if (context == null) {
        print('❌ Pas de context disponible, retry dans 1 seconde...');
        // Retry une fois après 1 seconde
        await Future.delayed(const Duration(seconds: 1));
        final retryContext = navigatorKey.currentContext;
        if (retryContext == null) {
          print('❌ Toujours pas de context après retry');
          return;
        }
        await _performNavigation(retryContext, message);
      } else {
        await _performNavigation(context, message);
      }

    } catch (e) {
      print('❌ Erreur navigation notification: $e');
    }
  }

  Future<void> _performNavigation(BuildContext context, RemoteMessage message) async {
    try {
      final data = message.data;
      final notificationType = data['type'] ?? data['notification_type'] ?? '';
      
      // Créer un NotificationModel temporaire pour utiliser votre système existant
      final notification = NotificationModel(
        id: 0, // ID temporaire
        title: message.notification?.title ?? data['title'] ?? '',
        message: message.notification?.body ?? data['body'] ?? data['message'] ?? '',
        notificationType: notificationType,
        relatedObjectId: _extractIntFromData(data, 'related_object_id'),
        isRead: false,
        createdAt: DateTime.now(),
        extraData: _extractExtraData(data),
      );
      
      print('✅ NotificationModel créé pour navigation');
      print('   Type: ${notification.notificationType}');
      print('   RelatedId: ${notification.relatedObjectId}');
      print('   ExtraData: ${notification.extraData}');
      
      // ← UTILISER VOTRE SYSTÈME EXISTANT
      await NotificationNavigationService.navigateToNotificationTarget(
        context,
        notification,
      );
      
    } catch (e) {
      print('❌ Erreur _performNavigation: $e');
      // Fallback : navigation simple vers Messages
      Navigator.pushNamed(context, '/messages');
    }
  }
  /// Gestionnaire de clic sur notification locale
  void _onNotificationTapped(NotificationResponse response) async {
    print('👆 Notification cliquée: ${response.payload}');

    if (response.payload != null) {
      try {
        // ✅ NOUVEAU : Parser avec gestion des erreurs
        final data = _parseNotificationPayload(response.payload!);
        
        if (data != null) {
          // Traiter les données et naviguer
          await _processNotificationTap(data);
        } else {
          print('❌ Impossible de parser les données de notification');
        }
      } catch (e) {
        print('❌ Erreur traitement clic notification: $e');
        // ✅ FALLBACK : Navigation simple vers Messages
        await _fallbackNavigation();
      }
    }
  }

  /// ✅ NOUVELLE MÉTHODE : Parser le payload avec gestion d'erreurs
  Map<String, dynamic>? _parseNotificationPayload(String payload) {
    try {
      print('🔍 Payload brut: $payload');
      
      // Première tentative : JSON standard
      try {
        return jsonDecode(payload) as Map<String, dynamic>;
      } catch (e) {
        print('⚠️ Échec JSON standard, tentative de nettoyage...');
      }
      
      // Deuxième tentative : Nettoyer le format Python
      String cleanedPayload = _cleanPythonFormat(payload);
      print('🧹 Payload nettoyé: $cleanedPayload');
      
      return jsonDecode(cleanedPayload) as Map<String, dynamic>;
      
    } catch (e) {
      print('❌ Échec total du parsing: $e');
      return null;
    }
  }


  /// ✅ NOUVELLE MÉTHODE : Nettoyer le format Python pour le rendre JSON valide
  String _cleanPythonFormat(String dartString) {
    String cleaned = dartString;
    
    print('🔧 Nettoyage format Dart: $cleaned');
    
    // 1. Remplacer None par null
    cleaned = cleaned.replaceAll('None', 'null');
    
    // 2. Remplacer True par true  
    cleaned = cleaned.replaceAll('True', 'true');
    
    // 3. Remplacer False par false
    cleaned = cleaned.replaceAll('False', 'false');
    
    // 4. Ajouter des guillemets autour des clés
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\s*)([a-zA-Z_][a-zA-Z0-9_]*)\s*:'),
      (match) => '${match.group(1)}"${match.group(2)}":',
    );
    
    // 5. ✅ REGEX CORRIGÉE : Gérer les guillemets simples existants d'ABORD
    cleaned = cleaned.replaceAllMapped(
      RegExp(r"'([^']*)'"),
      (match) {
        String content = match.group(1)!;
        // Échapper les guillemets doubles dans le contenu
        content = content.replaceAll('"', '\\"');
        return '"$content"';
      },
    );
    
    // 6. ✅ NOUVELLE REGEX PLUS LARGE : Quoter TOUTES les valeurs non-quotées qui ne sont pas des nombres
    // Cette regex trouve : ": " suivi de n'importe quel contenu jusqu'à la virgule ou accolade fermante,
    // SAUF si c'est déjà entre guillemets, ou si c'est un nombre, null, true, false
    cleaned = cleaned.replaceAllMapped(
      RegExp(r':\s*(?!")([^",}]+?)(?=\s*[,}])'),
      (match) {
        String value = match.group(1)!.trim();
        
        // Ne pas quoter les nombres (entiers ou décimaux)
        if (RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
          return ': $value';
        }
        
        // Ne pas quoter les mots-clés JSON
        if (value == 'null' || value == 'true' || value == 'false') {
          return ': $value';
        }
        
        // Quoter tout le reste (strings, URLs, etc.)
        return ': "$value"';
      },
    );
    
    print('✅ Format nettoyé final: $cleaned');
    return cleaned;
  }

  /// ✅ NOUVELLE MÉTHODE : Navigation de secours
  Future<void> _fallbackNavigation() async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        print('🔄 Navigation de secours vers MessagesScreen');
        Navigator.pushNamed(context, '/messages');
      }
    } catch (e) {
      print('❌ Erreur navigation de secours: $e');
    }
  }
  /// Extraire un entier depuis les données
  int? _extractIntFromData(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    
    return null;
  }

  /// Extraire les données supplémentaires
  Map<String, dynamic>? _extractExtraData(Map<String, dynamic> data) {
    Map<String, dynamic> extraData = {};
    
    // Copier toutes les données pertinentes
    final relevantKeys = [
      'conversation_id', 'sender_id', 'sender_first_name', 'sender_last_name',
      'sender_username', 'sender_avatar', 'sender_company_name',
      'project_id', 'offer_id', 'provider_id', 'service_id', 'quote_id',
      'review_id', 'dispute_id', 'item_type', 'item_id'
    ];
    
    for (String key in relevantKeys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value is String && int.tryParse(value) != null) {
          extraData[key] = int.parse(value);
        } else {
          extraData[key] = value;
        }
      }
    }
    
    return extraData.isNotEmpty ? extraData : null;
  }

  /// Traiter le clic sur notification
  Future<void> _processNotificationTap(Map<String, dynamic> data) async {
    try {
      print('📱 Traitement clic notification locale: $data');
      
      // Obtenir le context de navigation
      final context = navigatorKey.currentContext;
      if (context == null) {
        print('❌ Pas de context disponible pour navigation');
        return;
      }
      
      final notification = NotificationModel(
        id: 0,
        title: '',
        message: '',
        notificationType: data['type'] ?? '',
        relatedObjectId: _extractIntFromData(data, 'conversation_id') ?? 
                        _extractIntFromData(data, 'related_object_id'),
        isRead: false,
        createdAt: DateTime.now(),
        extraData: data,
      );
      
      // ✅ Utiliser votre service existant
      await NotificationNavigationService.navigateToNotificationTarget(context, notification);
      
      
    } catch (e) {
      print('❌ Erreur _processNotificationTap: $e');
      // Navigation de secours simple
      try {
        final context = navigatorKey.currentContext;
        if (context != null) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        }
      } catch (fallbackError) {
        print('❌ Erreur navigation de secours: $fallbackError');
      }
    }
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
