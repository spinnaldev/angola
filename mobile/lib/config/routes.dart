import 'package:flutter/material.dart';
import 'package:w3_loc/ui/screens/explore_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/auth/forgot_password_screen.dart';
import '../ui/screens/auth/verify_code_screen.dart';
import '../ui/screens/auth/reset_password_screen.dart';
import '../ui/screens/home_screen.dart'; 
import '../ui/screens/messaging/messages_screen.dart';
import '../ui/screens/auth/profile_selector_screen.dart';
import '../ui/screens/provider_detail_screen.dart';
import '../ui/screens/service_detail_screen.dart';
import '../ui/screens/provider/service_management_screen.dart';
import '../ui/screens/provider/quote_requests_screen.dart';
import '../ui/screens/client/my_quote_requests_screen.dart';
class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyCode = '/verify-code';
  static const String resetPassword = '/reset-password';
  static const String profileSelector = '/profile-selector';
  static const String explore = '/explore';
  static const String messages = '/messages';
  static const String providerDetail = '/provider-detail';
   static const String serviceDetail = '/service-detail';
  static const String serviceManagement = '/service-management';
  static const String quoteRequests = '/quote-requests';
  static const String myQuoteRequests = '/my-quote-requests';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomeScreen(), 
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    verifyCode: (context) => const VerifyCodeScreen(),
    resetPassword: (context) => const ResetPasswordScreen(),
    profileSelector: (context) => const ProfileSelectorScreen(),
    explore: (context) => const ExploreScreen(),
    messages: (context) => const MessagesScreen(),
    serviceManagement: (context) => const ServiceManagementScreen(),
    quoteRequests: (context) => const QuoteRequestsScreen(),
    myQuoteRequests: (context) => const MyQuoteRequestsScreen(),
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case profileSelector:
        return MaterialPageRoute(builder: (_) => const ProfileSelectorScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        // Récupérer les arguments si nécessaire
        final args = settings.arguments;
        final initialRole = args is String ? args : null;
        return MaterialPageRoute(builder: (_) => SignupScreen(initialRole: initialRole));
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case verifyCode:
        return MaterialPageRoute(builder: (_) => const VerifyCodeScreen());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case explore:
        return MaterialPageRoute(builder: (_) => const ExploreScreen());
      case serviceManagement:
        return MaterialPageRoute(builder: (_) => const ServiceManagementScreen());
      case quoteRequests:
        return MaterialPageRoute(builder: (_) => const QuoteRequestsScreen());
      case myQuoteRequests:
        return MaterialPageRoute(builder: (_) => const MyQuoteRequestsScreen());
      case serviceDetail:
        final serviceId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(serviceId: serviceId),
        );
      case providerDetail:
        final providerId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ProviderDetailScreen(providerId: providerId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route non définie pour ${settings.name}'),
            ),
          ),
        );
    }
  }
  static Widget getHomeScreen() {
    return const HomeScreen();  // Retourner la nouvelle page d'accueil
  }
}