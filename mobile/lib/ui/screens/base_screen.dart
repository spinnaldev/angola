// lib/ui/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../widgets/side_menu.dart';
import '../widgets/app_bottom_navigation.dart';

class BaseScreen extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final PreferredSizeWidget? appBar; // Changé de Widget? vers PreferredSizeWidget?
  final bool hasBottomNavigation;
  final bool showProfileToggle;
  final String? customTitle; // Ajouté pour permettre un titre personnalisé

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
  }

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  /// Gère la navigation selon le profil actuel
  void _handleNavigation(int index) {
    // Éviter la navigation si on est déjà sur la page demandée
    if (index == widget.currentIndex) return;

    if (ProfileManager.isProviderMode()) {
      // Navigation prestataire
      switch (index) {
        case 0: // Demandes de devis
          Navigator.pushNamedAndRemoveUntil(context, '/quote-requests', (route) => false);
          break;
        case 1: // Projets
          Navigator.pushNamedAndRemoveUntil(context, '/projects', (route) => false);
          break;
        case 2: // Messages
          Navigator.pushNamedAndRemoveUntil(context, '/messages', (route) => false);
          break;
        case 3: // Profil
          Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
          break;
      }
    } else {
      // Navigation client
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
          // Redémarrer l'interface en naviguant vers l'accueil
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
                fontSize: 12,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Vérifie si l'utilisateur peut basculer entre les profils
  bool _canUserSwitchProfile(dynamic user) {
    // Logique pour déterminer si l'utilisateur peut basculer
    // Pour l'instant, on suppose que tous les utilisateurs peuvent basculer
    // À adapter selon votre logique métier
    return true; // ou user.canSwitchProfile ou user.role == 'both', etc.
  }

  /// Ouvre le menu latéral
  void _openMenu() {
    if (_isMenuOpen) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildMenuOverlay(),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isMenuOpen = true;
    });
  }

  /// Ferme le menu latéral
  void _closeMenu() {
    if (!_isMenuOpen) return;
    
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isMenuOpen = false;
    });
  }

  /// Construit l'overlay du menu
  Widget _buildMenuOverlay() {
    return GestureDetector(
      onTap: _closeMenu,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {}, // Empêche la fermeture quand on tape sur le menu
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: double.infinity,
                child: SideMenu(onClose: _closeMenu),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _closeMenu,
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'AppBar par défaut
  // PreferredSizeWidget _buildDefaultAppBar() {
  //   return AppBar(
  //     title: Text(widget.customTitle ?? _getAppBarTitle()),
  //     elevation: 0,
  //     backgroundColor: Theme.of(context).primaryColor,
  //     foregroundColor: Colors.white,
  //     leading: IconButton(
  //       icon: const Icon(Icons.menu),
  //       onPressed: _openMenu,
  //     ),
  //     actions: [
  //       Consumer<AuthProvider>(
  //         builder: (context, authProvider, child) {
  //           return _buildProfileToggle(authProvider);
  //         },
  //       ),
  //       const SizedBox(width: 16),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: widget.appBar ?? _buildDefaultAppBar(),
      body: widget.body,
      bottomNavigationBar: widget.hasBottomNavigation
          ? AppBottomNavigation(
              currentIndex: widget.currentIndex,
              onTap: _handleNavigation,
            )
          : null,
    );
  }

  /// Récupère le titre de l'AppBar selon le contexte
  String _getAppBarTitle() {
    if (ProfileManager.isProviderMode()) {
      switch (widget.currentIndex) {
        case 0: return 'Demandes de devis';
        case 1: return 'Projets disponibles';
        case 2: return 'Messages';
        case 3: return 'Mon profil';
        default: return 'Espace Prestataire';
      }
    } else {
      switch (widget.currentIndex) {
        case 0: return 'Accueil';
        case 1: return 'Explorer';
        case 2: return 'Messages';
        case 3: return 'Mon profil';
        default: return 'ServiceConnect';
      }
    }
  }
}