// lib/ui/screens/app_entry_screen.dart - Point d'entrée avec redirection automatique
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import 'home_screen.dart';
import 'projects_list_screen.dart';
import 'base_screen.dart';

class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({Key? key}) : super(key: key);

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAndRedirect();
  }

  Future<void> _initializeAndRedirect() async {
    try {
      // Attendre que le ProfileManager soit initialisé
      await ProfileManager.initialize();
      
      // Attendre un frame pour que le Provider soit prêt
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Si utilisateur non connecté, afficher l'écran d'accueil client
        if (!authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        // Utilisateur connecté - rediriger selon le profil
        if (ProfileManager.isProviderMode()) {
          // PRESTATAIRE -> Afficher la liste des projets (index 0)
          return const ProjectsListScreen();
        } else {
          // CLIENT -> Afficher l'accueil (index 0)
          return const HomeScreen();
        }
      },
    );
  }
}