// lib/main.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

void main() async {
  // Assurer que les liaisons Flutter sont initialisées
  WidgetsFlutterBinding.ensureInitialized();

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

    return MultiProvider(
      providers: [
        // Fournisseurs de données
        Provider<ApiService>.value(value: apiService),

        // NOUVEAU : Provider de langue
        ChangeNotifierProvider.value(value: languageProvider),

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
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => MessagingProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              LocationProvider(), // Nouveau provider pour la localisation
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
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
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
            home: const AppEntryScreen(),
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
