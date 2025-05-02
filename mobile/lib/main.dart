import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:w3_loc/core/api/api_client.dart';
import 'core/services/api_service.dart';
import 'providers/category_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/subcategory_provider.dart';
import 'core/services/auth_service.dart';
import 'providers/service_provider.dart';
import 'providers/provider_detail_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/project_provider.dart';
import 'ui/screens/explore_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ui/screens/profile_selector_screen.dart';
import 'config/routes.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialiser le service API
    final apiService = ApiService(
      baseUrl:'http://10.0.2.2:8001/api',
      apiKey: 'your_api_key_here',
    );
    final apiClient = ApiClient(baseUrl:'http://10.0.2.2:8001/api');
    // final authService = AuthService(apiService);
    final authService = AuthService(apiClient);
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
        ),
        // home: const ExploreScreen(),
        home: const ProfileSelectorScreen(),
        routes: AppRoutes.routes,  // Utilisez les routes définies dans AppRoutes
        // OU utilisez onGenerateRoute au lieu de routes:
        // onGenerateRoute: AppRoutes.generateRoute,
        // initialRoute: AppRoutes.profileSelector,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}