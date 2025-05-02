import 'package:flutter/material.dart';
import 'package:w3_loc/ui/screens/explore_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/auth/forgot_password_screen.dart';
import '../ui/screens/auth/verify_code_screen.dart';
import '../ui/screens/auth/reset_password_screen.dart';
import '../ui/screens/home/home_screen.dart';
import '../ui/screens/messaging/messages_screen.dart';
import '../ui/screens/profile_selector_screen.dart';


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
  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    verifyCode: (context) => const VerifyCodeScreen(),
    resetPassword: (context) => const ResetPasswordScreen(),
    home: (context) => const HomeScreen(),
    profileSelector: (context) => const ProfileSelectorScreen(),
    explore: (context) => const ExploreScreen(),
    messages: (context) => const MessagesScreen(),
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
    return const HomeScreen();
  }
}