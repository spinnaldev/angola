// lib/ui/screens/base_screen.dart - Navigation différente selon le profil
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:w3_loc/ui/screens/projects_list_screen.dart';
import 'package:w3_loc/ui/screens/provider/quote_requests_screen.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../widgets/side_menu.dart';
import '../widgets/app_bottom_navigation.dart';

class BaseScreen extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final PreferredSizeWidget? appBar;
  final bool hasBottomNavigation;
  final bool showProfileToggle;
  final String? customTitle;

  const BaseScreen({
    Key? key,
    required this.body,
    this.currentIndex = 0,
    this.appBar,
    this.hasBottomNavigation = true,
    this.showProfileToggle = true,
    this.customTitle,
  }) : super(key: key);

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _overlayEntry = null;
    
    // S'assurer que le ProfileManager est initialisé
    _ensureProfileManagerInitialized();
  }

  /// S'assure que le ProfileManager est initialisé
  Future<void> _ensureProfileManagerInitialized() async {
    if (!ProfileManager.isInitialized) {
      print("BaseScreen: ProfileManager pas initialisé, initialisation en cours...");
      await ProfileManager.initialize();
      if (mounted) {
        setState(() {}); // Rafraîchir l'interface après initialisation
      }
    }
  }

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  void _openMenu() {
    setState(() {
      _isMenuOpen = true;
    });
  }

  void _closeMenu() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    setState(() {
      _isMenuOpen = false;
    });
  }

  /// Gère la navigation selon le profil actuel
  void _handleNavigation(int index) {
    // Éviter la navigation si on est déjà sur la page demandée
    if (index == widget.currentIndex) return;

    print("Navigation demandée - Index: $index, Mode prestataire: ${ProfileManager.isProviderMode()}");

    if (ProfileManager.isProviderMode()) {
      // Navigation PRESTATAIRE : Projets, Demandes de devis, Messages, Profil
      _handleProviderNavigation(index);
    } else {
      // Navigation CLIENT : Accueil, Explorer, Messages, Profil
      _handleClientNavigation(index);
    }
  }

  void _handleProviderNavigation(int index) {
    switch (index) {
      case 0: // Projets
        _navigateToProjectsList();
        break;
      case 1: // Demandes de devis
        _navigateToQuoteRequests();
        break;
      case 2: // Messages
        Navigator.pushNamedAndRemoveUntil(context, '/messages', (route) => false);
        break;
      case 3: // Profil
        Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
        break;
    }
  }

  void _handleClientNavigation(int index) {
    switch (index) {
      case 0: // Accueil
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1: // Explorer
        Navigator.pushNamedAndRemoveUntil(context, '/explore', (route) => false);
        break;
      case 2: // Messages
        Navigator.pushNamedAndRemoveUntil(context, '/messages', (route) => false);
        break;
      case 3: // Profil
        Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
        break;
    }
  }

  /// Navigation vers la liste des projets pour prestataires
  void _navigateToProjectsList() {
    try {
      // Essayer d'abord la route nommée
      Navigator.pushNamedAndRemoveUntil(context, '/projects-list', (route) => false);
    } catch (e) {
      print("Route nommée '/projects-list' non trouvée, utilisation de MaterialPageRoute");
      // Si la route nommée n'existe pas, naviguer directement
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const ProjectsListScreen(), // Votre écran de liste des projets
        ),
        (route) => false,
      );
    }
  }

  /// Navigation vers les demandes de devis pour prestataires
  void _navigateToQuoteRequests() {
    try {
      // Essayer d'abord la route nommée
      Navigator.pushNamedAndRemoveUntil(context, '/quote-requests', (route) => false);
    } catch (e) {
      print("Route nommée '/quote-requests' non trouvée, utilisation de MaterialPageRoute");
      // Si la route nommée n'existe pas, naviguer directement
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const QuoteRequestsScreen(), // Votre écran de demandes de devis
        ),
        (route) => false,
      );
    }
  }

  /// Construit le bouton de bascule de profil
  Widget _buildProfileToggle(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user == null || !widget.showProfileToggle) return const SizedBox();
    
    // Vérifier si l'utilisateur peut basculer entre les profils
    final canSwitchProfile = _canUserSwitchProfile(user);
    if (!canSwitchProfile) return const SizedBox();
    
    return PopupMenuButton<String>(
      onSelected: (String value) async {
        try {
          await ProfileManager.setCurrentProfile(value);
          // Redémarrer l'interface en naviguant vers la page d'accueil appropriée
          if (mounted) {
            if (value == 'provider') {
              // Prestataire -> aller vers liste des projets
              _navigateToProjectsList();
            } else {
              // Client -> aller vers accueil
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            }
          }
        } catch (e) {
          // Gérer l'erreur de changement de profil
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors du changement de profil: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'client',
          child: Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 8),
              const Text('Mode Client'),
              if (ProfileManager.isClientMode()) 
                const Icon(Icons.check, color: Colors.green, size: 16),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'provider',
          child: Row(
            children: [
              const Icon(Icons.work, size: 20),
              const SizedBox(width: 8),
              const Text('Mode Prestataire'),
              if (ProfileManager.isProviderMode()) 
                const Icon(Icons.check, color: Colors.green, size: 16),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ProfileManager.isProviderMode() ? Icons.work : Icons.person,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              ProfileManager.getProfileLabel(),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Vérifie si l'utilisateur peut changer de profil
  bool _canUserSwitchProfile(user) {
    // Ici vous pouvez ajouter votre logique métier
    // Par exemple, vérifier si l'utilisateur a les deux rôles
    return true; // Pour l'instant, on autorise tout le monde
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: widget.appBar ?? AppBar(
            title: Text(widget.customTitle ?? 'W3 Loc'),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            titleTextStyle: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            actions: [
              _buildProfileToggle(authProvider),
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: _openMenu,
              ),
            ],
          ),
          body: Stack(
            children: [
              widget.body,
              if (_isMenuOpen)
                GestureDetector(
                  onTap: _closeMenu,
                  child: Container(
                    color: Colors.black54,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SideMenu(onClose: _closeMenu),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: widget.hasBottomNavigation
              ? AppBottomNavigation(
                  currentIndex: widget.currentIndex,
                  onTap: _handleNavigation,
                )
              : null,
        );
      },
    );
  }
}

// NOTE: Vous devez importer ces écrans selon votre structure de fichiers
// import 'projects_list_screen.dart';
// import 'provider/quote_requests_screen.dart';