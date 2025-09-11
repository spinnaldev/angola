// lib/main.dart
  import 'dart:async';
import 'dart:convert';
  import 'dart:io';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/rendering.dart';
  import 'package:permission_handler/permission_handler.dart';
  import 'package:provider/provider.dart';
  import 'package:flutter_dotenv/flutter_dotenv.dart';
  import 'package:flutter_localizations/flutter_localizations.dart';
  import 'package:flutter_gen/gen_l10n/app_localizations.dart';
  import 'package:teyago/core/services/notification_service.dart';
  import 'package:teyago/core/services/phone_verification_service.dart';
  import 'package:teyago/core/services/provider_verification_service.dart';
  import 'package:teyago/core/services/websocket_service.dart';
  import 'package:teyago/providers/cm_provider.dart';
  import 'package:teyago/providers/realtime_messaging_provider.dart';
  import 'package:teyago/providers/realtime_notification_provider.dart';
  import 'package:teyago/ui/screens/app_entry_screen.dart';
  import 'package:teyago/ui/screens/home/home_screen.dart';
  import 'core/api/api_client.dart';
  import 'core/services/api_service.dart';
  import 'core/services/auth_service.dart';
  import 'core/services/dispute_service.dart';
  import 'core/services/quote_service.dart';
  import 'core/services/review_service.dart';
  import 'providers/auth_provider.dart';
  import 'providers/category_provider.dart';
  import 'providers/provider_list_provider.dart';
  import 'providers/subcategory_provider.dart';
  import 'providers/service_provider.dart';
  import 'providers/provider_detail_provider.dart';
  import 'providers/notification_provider.dart';
  import 'providers/messaging_provider.dart';
  import 'providers/filter_provider.dart';
  import 'providers/project_provider.dart';
  import 'providers/quote_provider.dart';
  import 'providers/review_provider.dart';
  import 'providers/language_provider.dart'; // NOUVEAU
  import 'config/routes.dart';
  import 'core/services/profile_manager.dart';
  import 'ui/screens/home_screen.dart'; // Nouvelle page d'accueil
  import 'providers/dispute_provider.dart';
  import 'package:intl/date_symbol_data_local.dart';
  import 'providers/location_provider.dart';
  import 'providers/offers_provider.dart';
  import 'core/services/websocket_service.dart';
  import 'core/services/improved_location_service.dart';
  import 'providers/improved_nearby_provider.dart';
  import 'providers/provider_verification_provider.dart';
  import 'providers/phone_verification_provider.dart';
  import 'core/services/fcm_service.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:firebase_messaging/firebase_messaging.dart';
  // Gestionnaire de messages en arrière-plan FCM (OBLIGATOIRE au niveau top-level)
  @pragma('vm:entry-point')
  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Initialiser Firebase si nécessaire
    await Firebase.initializeApp();
    print('📨 Message FCM en arrière-plan: ${message.notification?.title}');
  }
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  void main() async {
    // Assurer que les liaisons Flutter sont initialisées
    WidgetsFlutterBinding.ensureInitialized();

    try {
      print('🔥 Initialisation Firebase...');
      await Firebase.initializeApp();
      print('✅ Firebase initialisé');
      
      // Configurer le gestionnaire de messages en arrière-plan
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      print('✅ Gestionnaire FCM arrière-plan configuré');
      
      // *** AJOUTEZ CE CODE DE DEBUG ***
      print('🔍 === DEBUG FCM DETAILLÉ ===');
      
      // Vérifier que Firebase est bien initialisé
      try {
        final messaging = FirebaseMessaging.instance;
        print('✅ Instance FirebaseMessaging obtenue');
        
        // Essayer d'obtenir le token immédiatement pour voir s'il y a des erreurs
        final token = await messaging.getToken();
        print('🔑 Token FCM initial: ${token?.substring(0, 20)}...');
        
        // Vérifier les permissions avant l'initialisation
        final settings = await messaging.requestPermission();
        print('📝 Authorization: ${settings.authorizationStatus}');
        print('📱 Alert: ${settings.alert}');
        print('🔔 Sound: ${settings.sound}');
        print('🔢 Badge: ${settings.badge}');

        // Test permission système Android
        if (Platform.isAndroid) {
          final systemPerm = await Permission.notification.status;
          print('📱 Permission système: $systemPerm');
        }
        // final settings = await messaging.getNotificationSettings();
        // print('📝 Status permissions: ${settings.authorizationStatus}');
        // print('📱 Alert autorisé: ${settings.alert}');
        // print('🔔 Sound autorisé: ${settings.sound}');
        // print('🔢 Badge autorisé: ${settings.badge}');
        
      } catch (e) {
        print('❌ Erreur lors du debug FCM initial: $e');
      }
      
      print('🔍 === FIN DEBUG DETAILLÉ ===');
      
    } catch (e) {
      print('❌ Erreur initialisation Firebase: $e');
    }

    // Supprimer les debug elements
    if (kDebugMode) {
      debugPaintSizeEnabled = false;
    }

    // Initialiser le formatage des dates pour toutes les locales supportées
    await initializeDateFormatting('fr_FR', null);
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('pt_PT', null);

    // Charger les variables d'environnement si nécessaire
    try {
      await dotenv.load(fileName: "lib/.env");
    } catch (e) {
      print('Erreur lors du chargement des variables d\'environnement: $e');
      // Continue even if .env file is not found
    }

    // AJOUT CRUCIAL : Initialiser le ProfileManager
    try {
      await ProfileManager.initialize();
      print('ProfileManager initialisé avec succès');
    } catch (e) {
      print('Erreur lors de l\'initialisation du ProfileManager: $e');
    }

    // NOUVEAU : Initialiser le provider de langue
    final languageProvider = LanguageProvider();
    await languageProvider.initializeLanguage();
    print('LanguageProvider initialisé avec succès');

    runApp(MyApp(languageProvider: languageProvider));
  }
  
  class MyApp extends StatelessWidget {
    final LanguageProvider languageProvider;

    const MyApp({Key? key, required this.languageProvider}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      // Initialiser le service API
      final apiService = ApiService(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8004/api',
        // baseUrl: 'http://10.0.2.2:8003/api',
        // baseUrl: "https://angola.onrender.com/api",
        apiKey: 'your_api_key_here',
      );
      // final apiClient = ApiClient(baseUrl: 'http://10.0.2.2:8001/api');
      final apiClient = ApiClient(baseUrl: apiService.baseUrl);
      final authService = AuthService(apiClient);
      final quoteService = QuoteService(apiService);
      final reviewService = ReviewService(apiService);
      final webSocketService = WebSocketService.instance;
      final notificationService = NotificationService(apiService);
      final _fcmService = FCMService();

      return MultiProvider(
        providers: [
          // Fournisseurs de données
          Provider<ApiService>.value(value: apiService),

          Provider<WebSocketService>(
            create: (_) => WebSocketService.instance,
            dispose: (_, service) => service.dispose(),
          ),

          
          // NOUVEAU : Provider de langue
          ChangeNotifierProvider.value(value: languageProvider),

          ChangeNotifierProxyProvider<AuthProvider, MessagingProvider>(
            create: (context) => MessagingProvider(
              Provider.of<ApiService>(context, listen: false),
            ),
            update: (context, auth, previous) => previous ?? MessagingProvider(
              Provider.of<ApiService>(context, listen: false),
            ),
          ),

          ChangeNotifierProxyProvider2<MessagingProvider, WebSocketService, RealtimeMessagingProvider>(
            create: (context) => RealtimeMessagingProvider(
              Provider.of<MessagingProvider>(context, listen: false),
              Provider.of<WebSocketService>(context, listen: false),
            ),
            update: (context, messaging, websocket, previous) => 
              previous ?? RealtimeMessagingProvider(messaging, websocket),
          ),
          // Providers d'état
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authService),
          ),
          ChangeNotifierProvider(
            create: (_) => CategoryProvider(apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => SubcategoryProvider(apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => ProviderDetailProvider(apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => QuoteProvider(quoteService),
          ),
          ChangeNotifierProvider(
            create: (_) => ReviewProvider(reviewService),
          ),
          ChangeNotifierProvider(
            create: (_) => ServiceProvider(apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => ProviderListProvider(apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => ProviderDetailProvider(apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => FilterProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => ProjectProvider(apiService),
          ),
          ChangeNotifierProvider<NotificationProvider>(
            create: (context) => NotificationProvider(notificationService),
          ),
          ChangeNotifierProvider(
            create: (_) => MessagingProvider(apiService),
          ),
          // Providers temps réel (dépendent des providers de base)
          ChangeNotifierProvider<RealtimeNotificationProvider>(
            create: (context) => RealtimeNotificationProvider(
              context.read<NotificationProvider>(),
              webSocketService,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => FCMProvider(_fcmService, apiService),
          ),
          // ChangeNotifierProvider<RealtimeMessagingProvider>(
          //   create: (context) => RealtimeMessagingProvider(
          //     context.read<MessagingProvider>(),
          //     webSocketService,
          //   ),
          // ),
          ChangeNotifierProvider(
            create: (_) =>
                LocationProvider(), // Nouveau provider pour la localisation
          ),
          ChangeNotifierProvider(create: (_) => ImprovedLocationService()),
          ChangeNotifierProvider(
            create: (context) => ImprovedNearbyProvider(
              context.read<ImprovedLocationService>(),
              context.read<ApiService>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => DisputeProvider(
              DisputeService(apiService),
            ),
          ),
          ChangeNotifierProxyProvider<AuthProvider, OffersProvider>(
            create: (context) => OffersProvider(apiService),
            update: (context, authProvider, previous) =>
                previous ?? OffersProvider(apiService),
          ),

          ChangeNotifierProxyProvider<ApiService, ProviderVerificationProvider>(
            create: (context) => ProviderVerificationProvider(
              ProviderVerificationService(context.read<ApiService>())
            ),
            update: (context, apiService, previous) => 
                previous ?? ProviderVerificationProvider(
                  ProviderVerificationService(apiService)
                ),
          ),
          
          ChangeNotifierProxyProvider<ApiService, PhoneVerificationProvider>(
            create: (context) => PhoneVerificationProvider(
              PhoneVerificationService(context.read<ApiService>())
            ),
            update: (context, apiService, previous) => 
                previous ?? PhoneVerificationProvider(
                  PhoneVerificationService(apiService)
                ),
          ),
          // ChangeNotifierProxyProvider3<NotificationService, WebSocketService, AuthService, RealtimeNotificationProvider>(
          //   create: (context) => RealtimeNotificationProvider(
          //     Provider.of<NotificationService>(context, listen: false),
          //     Provider.of<WebSocketService>(context, listen: false),
          //     Provider.of<AuthService>(context, listen: false),
          //   ),
          //   update: (_, notificationService, webSocketService, authService, provider) =>
          //       provider ?? RealtimeNotificationProvider(notificationService, webSocketService, authService),
          // ),
        ],
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return MaterialApp(

              navigatorKey: navigatorKey,

              debugShowCheckedModeBanner: false,
              showPerformanceOverlay: false, // Supprime l'overlay de performance
              checkerboardRasterCacheImages:
                  false, // Supprime le damier des images
              checkerboardOffscreenLayers: false, // Supprime le damier des layers
              showSemanticsDebugger: false, // Supprime le debugger sémantique
              debugShowMaterialGrid: false,

              title: 'Teyago Services',

              // NOUVEAU : Configuration de la localisation
              locale: languageProvider.currentLocale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'), // Anglais
                Locale('fr'), // Français
                Locale('pt'), // Portugais
              ],

              theme: ThemeData(
                primaryColor: const Color(0xFF142FE2),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF142FE2),
                  primary: const Color(0xFF142FE2),
                ),
                scaffoldBackgroundColor: Colors.white,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  iconTheme: IconThemeData(color: Colors.black),
                  titleTextStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF142FE2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              // home: const AppEntryScreen(),
              home: const AppInitializer(),
              // home: HomeScreen(),
              routes: AppRoutes.routes,
              onGenerateRoute: AppRoutes.generateRoute,

              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  child: child!,
                );
              },
            );
          },
        ),
      );
    }
  }

  /// Widget pour initialiser l'application et gérer les WebSockets
  class AppInitializer extends StatefulWidget {
    const AppInitializer({Key? key}) : super(key: key);

    @override
    State<AppInitializer> createState() => _AppInitializerState();
  }

  class _AppInitializerState extends State<AppInitializer> 
      with WidgetsBindingObserver, TickerProviderStateMixin {
    bool _isInitialized = false;
    
    // Contrôleurs d'animation
    late AnimationController _animationController;
    late Animation<double> _scaleAnimation;
    late Animation<double> _opacityAnimation;
    late Animation<double> _rotationAnimation;

    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addObserver(this);
      _initAnimations();
      // ✅ SOLUTION : Attendre que le build soit terminé
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeApp();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeServices();
      });

      _initializeRealtimeServices();
    }

    void _initAnimations() {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );

      _scaleAnimation = Tween<double>(
        begin: 0.5,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ));

      _opacityAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ));

      _rotationAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ));

      _animationController.forward();
    }

    @override
    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      _animationController.dispose();
      super.dispose();
    }

    void _initializeServices() async {
      try {
        // Attendre que l'authentification soit prête
        await Future.delayed(Duration(seconds: 1));
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          final userId = authProvider.currentUser!.id;
          
          print('🚀 Initialisation services pour user $userId');
          
          // ✅ WebSocketService maintenant accessible via Provider
          final webSocketService = Provider.of<WebSocketService>(context, listen: false);
          await webSocketService.connect('ws://votre-domaine.com', userId);
          
          // ✅ Initialiser MessagingProvider
          final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
          messagingProvider.setCurrentUserId(userId);
          
          // ✅ Démarrer RealtimeMessagingProvider
          final realtimeProvider = Provider.of<RealtimeMessagingProvider>(context, listen: false);
          realtimeProvider.startListening();
          
          // ✅ Demander les compteurs après un délai
          Future.delayed(Duration(seconds: 2), () {
            realtimeProvider.requestInitialCounts();
          });
          
          print('✅ Services temps réel initialisés');
          
        } else {
          print('⚠️ Utilisateur non connecté');
        }
        
      } catch (e) {
        print('❌ Erreur initialisation: $e');
      }
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      super.didChangeAppLifecycleState(state);
      
      final authProvider = context.read<AuthProvider>();
      final webSocketService = context.read<WebSocketService>();
      
      switch (state) {
        case AppLifecycleState.resumed:
          // Reconnexion quand l'app revient au premier plan
          if (authProvider.isAuthenticated && authProvider.currentUser != null) {
            _connectWebSocket();
          }
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
          // Déconnecter les WebSockets quand l'app passe en arrière-plan
          webSocketService.disconnect();
          break;
        default:
          break;
      }
    }

    Future<void> _initializeApp() async {
      try {
        print('🚀 Initialisation de l\'application...');
        
        // Vérifier l'authentification
        final authProvider = context.read<AuthProvider>();
        await authProvider.checkAuthenticationStatus();
        
        // ✅ VÉRIFIER que cette section est bien présente :
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          try {
            print('🔔 === INITIALISATION FCM ===');
            print('👤 Utilisateur connecté: ${authProvider.currentUser?.email}');
            
            final fcmProvider = context.read<FCMProvider>();
            await fcmProvider.initializeFCM();
            
            print('✅ FCM Provider initialisé');
            
          } catch (fcmError) {
            print('❌ Erreur initialisation FCM: $fcmError');
          }
          
          // WebSockets après FCM  
          await _connectWebSocket();
          _startRealtimeListeners();
        } else {
          print('ℹ️ Utilisateur non connecté - FCM non initialisé');
        }
        
        setState(() {
          _isInitialized = true;
        });
        
        print('✅ Application initialisée avec succès');
        
      } catch (e) {
        print('❌ Erreur lors de l\'initialisation: $e');
        setState(() {
          _isInitialized = true;
        });
      }
    }

    void _initializeRealtimeServices() {
      // Délai pour permettre l'initialisation complète des providers
      Timer(Duration(seconds: 3), () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          final userId = authProvider.currentUser!.id;
          
          print('🚀 Initialisation services temps réel pour user $userId');
          
          try {
            // 1. Connecter WebSocket général
            final webSocketService = WebSocketService.instance;
            webSocketService.connect('ws:teyago.com/api/', userId);
            
            // 2. Initialiser le MessagingProvider avec l'ID utilisateur
            final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
            messagingProvider.setCurrentUserId(userId);
            
            // 3. Démarrer l'écoute temps réel des messages
            final realtimeMessagingProvider = Provider.of<RealtimeMessagingProvider>(context, listen: false);
            realtimeMessagingProvider.startListening();
            
            // 4. Demander les compteurs initiaux
            Timer(Duration(seconds: 1), () {
              realtimeMessagingProvider.requestInitialCounts();
            });
            
            print('✅ Services temps réel initialisés pour user $userId');
            
          } catch (e) {
            print('❌ Erreur initialisation services temps réel: $e');
          }
        } else {
          print('⚠️ Utilisateur non connecté, services temps réel non initialisés');
        }
      });
    }

    Future<void> _connectWebSocket() async {
      try {
        final authProvider = context.read<AuthProvider>();
        final webSocketService = context.read<WebSocketService>();
        
        if (authProvider.currentUser?.id != null) {
          // Obtenir l'URL de base depuis l'API client
          final apiClient = context.read<ApiClient>();
          final baseUrl = apiClient.baseUrl;
          
          await webSocketService.connect(baseUrl, authProvider.currentUser!.id);
          print('✅ WebSocket connecté pour utilisateur ${authProvider.currentUser!.id}');
        }
      } catch (e) {
        print('❌ Erreur de connexion WebSocket: $e');
      }
    }

    void _startRealtimeListeners() {
      try {
        final realtimeNotificationProvider = context.read<RealtimeNotificationProvider>();
        final realtimeMessagingProvider = context.read<RealtimeMessagingProvider>();
        
        realtimeNotificationProvider.startListening();
        realtimeMessagingProvider.startListening();
        
        print('✅ Listeners temps réel démarrés');
      } catch (e) {
        print('❌ Erreur lors du démarrage des listeners: $e');
      }
    }

    @override
    Widget build(BuildContext context) {
      if (!_isInitialized) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation du logo
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * 0.1, // Légère rotation
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: const Color(0xFF142FE2).withOpacity(0.3),
                              //     blurRadius: 20,
                              //     spreadRadius: 5,
                              //   ),
                              // ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    // color: const Color(0xFF142FE2),
                                    // borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.business,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Indicateur de progression animé
                    Opacity(
                      opacity: _opacityAnimation.value,
                      child: Column(
                        children: [
                          // Barre de progression personnalisée
                          Container(
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF142FE2).withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Texte d'initialisation avec animation
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final dots = '.' * ((_animationController.value * 3).floor() + 1);
                              return Text(
                                'Initialisation $dots',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }

      // Une fois l'initialisation terminée, passer la main à AppEntryScreen
      return const AppEntryScreen();
    }
  }