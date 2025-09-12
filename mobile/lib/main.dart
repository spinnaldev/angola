// lib/main.dart - VERSION CORRIGÉE
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
import 'package:teyago/providers/fcm_provider.dart';
import 'package:teyago/providers/favorites_provider.dart';
import 'package:teyago/providers/realtime_messaging_provider.dart';
import 'package:teyago/providers/realtime_notification_provider.dart';
import 'package:teyago/providers/reviews_provider.dart';
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
import 'providers/language_provider.dart';
import 'config/routes.dart';
import 'core/services/profile_manager.dart';
import 'ui/screens/home_screen.dart';
import 'providers/dispute_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/location_provider.dart';
import 'providers/offers_provider.dart';
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
  await Firebase.initializeApp();
  print('📨 Message FCM en arrière-plan: ${message.notification?.title}');
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🔥 Initialisation Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Gestionnaire FCM arrière-plan configuré');
    
  } catch (e) {
    print('❌ Erreur initialisation Firebase: $e');
  }

  // Supprimer les debug elements
  if (kDebugMode) {
    debugPaintSizeEnabled = false;
  }

  // Initialiser le formatage des dates
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('pt_PT', null);

  // Charger les variables d'environnement
  try {
    await dotenv.load(fileName: "lib/.env");
  } catch (e) {
    print('⚠️ Fichier .env non trouvé, utilisation des valeurs par défaut');
  }

  // Initialiser le ProfileManager
  try {
    await ProfileManager.initialize();
    print('ProfileManager initialisé avec succès');
  } catch (e) {
    print('Erreur lors de l\'initialisation du ProfileManager: $e');
  }

  // Initialiser le provider de langue
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
    // ✅ ÉTAPE 1: Initialiser les services de base
    final apiService = ApiService(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8004/api',
      apiKey: 'your_api_key_here',
    );
    
    final apiClient = ApiClient(baseUrl: apiService.baseUrl);
    final authService = AuthService(apiClient);
    final quoteService = QuoteService(apiService);
    final reviewService = ReviewService(apiClient);
    final webSocketService = WebSocketService.instance;
    final notificationService = NotificationService(apiService);
    final fcmService = FCMService();

    return MultiProvider(
      providers: [
        // ✅ ÉTAPE 2: Services de base (aucune dépendance)
        Provider<ApiService>.value(value: apiService),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        Provider<QuoteService>.value(value: quoteService),
        Provider<ReviewService>.value(value: reviewService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<FCMService>.value(value: fcmService),
        
        Provider<WebSocketService>(
          create: (_) => WebSocketService.instance,
          dispose: (_, service) => service.dispose(),
        ),

        // ✅ ÉTAPE 3: Provider de langue
        ChangeNotifierProvider.value(value: languageProvider),

        // ✅ ÉTAPE 4: AuthProvider (dépend d'AuthService)
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService),
        ),

        // ✅ ÉTAPE 5: Providers de données (dépendent d'ApiService)
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => CategoryProvider(apiService),
        ),
        ChangeNotifierProvider<SubcategoryProvider>(
          create: (_) => SubcategoryProvider(apiService),
        ),
        ChangeNotifierProvider<ServiceProvider>(
          create: (_) => ServiceProvider(apiService),
        ),
        ChangeNotifierProvider<ProviderDetailProvider>(
          create: (_) => ProviderDetailProvider(apiService),
        ),
        ChangeNotifierProvider<ProviderListProvider>(
          create: (_) => ProviderListProvider(apiService),
        ),
        ChangeNotifierProvider<ProjectProvider>(
          create: (_) => ProjectProvider(apiService),
        ),
        ChangeNotifierProvider<FilterProvider>(
          create: (_) => FilterProvider(),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(),
        ),

        // ✅ ÉTAPE 6: Providers avec services injectés
        ChangeNotifierProvider<QuoteProvider>(
          create: (_) => QuoteProvider(quoteService),
        ),
        ChangeNotifierProvider<ReviewProvider>(
          create: (_) => ReviewProvider(reviewService),
        ),
        ChangeNotifierProvider<ReviewsProvider>(
          create: (_) => ReviewsProvider(reviewService),
        ),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider(apiService),
        ),
        ChangeNotifierProvider<DisputeProvider>(
          create: (_) => DisputeProvider(DisputeService(apiService)),
        ),

        // ✅ ÉTAPE 7: Providers de messagerie (dépendent d'ApiService)
        ChangeNotifierProvider<MessagingProvider>(
          create: (_) => MessagingProvider(apiService),
        ),

        // ✅ ÉTAPE 8: Providers de notifications (dépendent de NotificationService)
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(notificationService),
        ),
        ChangeNotifierProvider<FCMProvider>(
          create: (_) => FCMProvider(fcmService, apiService),
        ),

        // ✅ ÉTAPE 9: Providers avec ApiClient comme dépendance
        ChangeNotifierProvider<ImprovedLocationService>(
          create: (_) => ImprovedLocationService(),
        ),
        ChangeNotifierProxyProvider<ImprovedLocationService, ImprovedNearbyProvider>(
          create: (context) => ImprovedNearbyProvider(
            context.read<ImprovedLocationService>(),
            context.read<ApiService>(),
          ),
          update: (context, location, previous) => 
            previous ?? ImprovedNearbyProvider(location, context.read<ApiService>()),
        ),

        // ✅ ÉTAPE 10: Providers d'offres (dépendent d'AuthProvider et ApiService)
        ChangeNotifierProxyProvider<AuthProvider, OffersProvider>(
          create: (context) => OffersProvider(apiService),
          update: (context, authProvider, previous) =>
            previous ?? OffersProvider(apiService),
        ),

        // ✅ ÉTAPE 11: Providers de vérification
        ChangeNotifierProvider<ProviderVerificationProvider>(
          create: (_) => ProviderVerificationProvider(
            ProviderVerificationService(apiService)
          ),
        ),
        ChangeNotifierProvider<PhoneVerificationProvider>(
          create: (_) => PhoneVerificationProvider(
            PhoneVerificationService(apiService)
          ),
        ),

        // ✅ ÉTAPE 12: Providers temps réel (dépendent des providers précédents)
        ChangeNotifierProxyProvider2<MessagingProvider, WebSocketService, RealtimeMessagingProvider>(
          create: (context) => RealtimeMessagingProvider(
            context.read<MessagingProvider>(),
            context.read<WebSocketService>(),
          ),
          update: (context, messaging, websocket, previous) => 
            previous ?? RealtimeMessagingProvider(messaging, websocket),
        ),

        ChangeNotifierProxyProvider2<NotificationProvider, WebSocketService, RealtimeNotificationProvider>(
          create: (context) => RealtimeNotificationProvider(
            context.read<NotificationProvider>(),
            context.read<WebSocketService>(),
          ),
          update: (context, notification, websocket, previous) => 
            previous ?? RealtimeNotificationProvider(notification, websocket),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: false,
            checkerboardRasterCacheImages: false,
            checkerboardOffscreenLayers: false,
            showSemanticsDebugger: false,
            debugShowMaterialGrid: false,
            title: 'Teyago Services',

            // Configuration de la localisation
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('fr'),
              Locale('pt'),
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
            
            home: const AppInitializer(),
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

/// ✅ Widget AppInitializer simplifié et robuste
class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    
    // ✅ Initialisation sécurisée après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeInitializeApp();
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  /// ✅ Initialisation sécurisée avec gestion d'erreurs
  Future<void> _safeInitializeApp() async {
    try {
      await _initializeApp();
      
      setState(() {
        _isInitialized = true;
      });
      
    } catch (e) {
      print('❌ Erreur d\'initialisation: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isInitialized = true; // Continuer malgré l'erreur
      });
    }
  }

  Future<void> _initializeApp() async {
    print('🚀 Initialisation de l\'application...');
    
    try {
      // 1. Vérifier l'authentification
      final authProvider = context.read<AuthProvider>();
      await authProvider.checkAuthStatus();
      print('✅ État d\'authentification vérifié');
      
      // 2. Si utilisateur connecté, initialiser les services
      if (authProvider.isAuthenticated && authProvider.currentUser != null) {
        await _initializeConnectedUserServices(authProvider);
      } else {
        print('ℹ️ Utilisateur non connecté - services de base seulement');
      }
      
    } catch (e) {
      print('⚠️ Erreur lors de l\'initialisation (non bloquante): $e');
      // Ne pas re-throw, permettre à l'app de continuer
    }
    
    print('✅ Application initialisée avec succès');
  }

  Future<void> _initializeConnectedUserServices(AuthProvider authProvider) async {
    final userId = authProvider.currentUser!.id;
    print('🚀 Initialisation services pour user $userId');
    
    try {
      // 1. Initialiser FCM
      final fcmProvider = context.read<FCMProvider>();
      await fcmProvider.initializeFCM();
      print('✅ FCM Provider initialisé');
      
      // 2. Charger les préférences de notification
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.loadNotificationPreferences();
      print('✅ Préférences de notification chargées');
      
      // 3. Connecter WebSocket
      await _connectWebSocket();
      
      // 4. Démarrer les services temps réel
      _startRealtimeServices();
      
    } catch (e) {
      print('⚠️ Erreur services utilisateur connecté: $e');
      // Ne pas bloquer l'initialisation
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final webSocketService = context.read<WebSocketService>();
      
      if (authProvider.currentUser?.id != null) {
        await webSocketService.connect('ws://teyago/api', authProvider.currentUser!.id);
        print('✅ WebSocket connecté');
      }
    } catch (e) {
      print('⚠️ Erreur WebSocket (non bloquante): $e');
    }
  }

  void _startRealtimeServices() {
    try {
      final realtimeMessaging = context.read<RealtimeMessagingProvider>();
      final realtimeNotifications = context.read<RealtimeNotificationProvider>();
      
      realtimeMessaging.startListening();
      realtimeNotifications.startListening();
      
      print('✅ Services temps réel démarrés');
    } catch (e) {
      print('⚠️ Erreur services temps réel (non bloquante): $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App reprise');
        _safeInitializeApp();
        break;
      case AppLifecycleState.paused:
        print('📱 App en pause');
        break;
      default:
        break;
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
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF142FE2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.handyman,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: const Text(
                      'TEYAGO',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF142FE2),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Indicateur de progression
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
              );
            },
          ),
        ),
      );
    }

    // ✅ Afficher un avertissement si erreur mais continuer
    if (_hasError) {
      print('⚠️ Application démarrée avec avertissements: $_errorMessage');
    }

    return const AppEntryScreen();
  }
}