// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/api/api_client.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/quote_service.dart';
import 'core/services/review_service.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/subcategory_provider.dart';
import 'providers/service_provider.dart';
import 'providers/provider_detail_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/project_provider.dart';
import 'providers/quote_provider.dart';
import 'providers/review_provider.dart';
import 'config/routes.dart';
import 'ui/screens/home_screen.dart';  // Nouvelle page d'accueil

void main() async {
  // Assurer que les liaisons Flutter sont initialisées
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger les variables d'environnement si nécessaire
  try {
    await dotenv.load(fileName: "lib/.env");
  } catch (e) {
    print('Erreur lors du chargement des variables d\'environnement: $e');
    // Continue even if .env file is not found
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialiser le service API
    final apiService = ApiService(
      baseUrl: 'http://10.0.2.2:8001/api',
      apiKey: 'your_api_key_here',
    );
    final apiClient = ApiClient(baseUrl: 'http://10.0.2.2:8001/api');
    final authService = AuthService(apiClient);
    final quoteService = QuoteService(apiService);
    final reviewService = ReviewService(apiService);
    
    return MultiProvider(
      providers: [
        // Fournisseurs de données
        Provider<ApiService>.value(value: apiService),
        
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
      ],
      child: MaterialApp(
        title: 'Angola Services',
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
        home: const HomeScreen(), // Utiliser notre nouvelle page d'accueil comme écran principal
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}