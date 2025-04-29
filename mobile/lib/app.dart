import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/themes.dart';
import 'config/routes.dart';
import 'core/api/api_client.dart';
import 'core/services/auth_service.dart';
import 'providers/auth_provider.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(
            baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api',
          ),
        ),
        ProxyProvider<ApiClient, AuthService>(
          update: (context, apiClient, _) => AuthService(apiClient),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
          update: (context, authService, authProvider) => 
              authProvider ?? AuthProvider(authService),
        ),
      ],
      child: MaterialApp(
        title: 'Angola App',
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.profileSelector,
        routes: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}