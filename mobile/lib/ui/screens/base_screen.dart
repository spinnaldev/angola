// lib/ui/screens/base_screen.dart - VERSION CORRIGÉE AVEC LOCALISATION COMPLÈTE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../widgets/side_menu.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'messaging/messages_screen.dart';
import 'profile_screen.dart';
import 'projects_list_screen.dart';

class BaseScreen extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final PreferredSizeWidget? appBar;
  final bool hasBottomNavigation;
  static AuthProvider? _authProvider;
  const BaseScreen({
    Key? key,
    required this.body,
    this.currentIndex = 0,
    this.appBar,
    this.hasBottomNavigation = true,
  }) : super(key: key);

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  bool _isMenuOpen = false;

  void _openMenu() {
    setState(() {
      _isMenuOpen = true;
    });
  }

  void _closeMenu() {
    setState(() {
      _isMenuOpen = false;
    });
  }

  void _handleNavigation(int index) {
    // Fermer le menu si ouvert
    if (_isMenuOpen) {
      _closeMenu();
    }

    // ✅ CORRECTION : Si on clique sur Profil (index 3), ouvrir le menu au lieu de naviguer
    if (index == 3) {
      _openMenu();
      return;
    }

    // Éviter la navigation si on est déjà sur la page demandée
    if (index == widget.currentIndex) return;

    // Vérifier si l'utilisateur est connecté
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;

    // Navigation selon le profil de l'utilisateur
    if (isAuthenticated && ProfileManager.isProviderMode()) {
      // Navigation pour prestataires : Accueil, Projets, Messages, [Menu]
      _handleProviderNavigation(index);
    } else {
      // Navigation pour clients ou utilisateurs non connectés : Accueil, Explorer, Messages, [Menu]
      _handleClientNavigation(index);
    }
  }

  void _handleProviderNavigation(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;

    switch (index) {
      case 0: // Accueil
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1: // Projets
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProjectsListScreen()),
          (route) => false,
        );
        break;
      case 2: // Messages
        if (authProvider.isAuthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MessagesScreen()),
            (route) => false,
          );
        } else {
          _redirectToLogin();
        }
        break;
      // case 3 est géré plus haut pour ouvrir le menu
    }
  }

  void _handleClientNavigation(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (index) {
      case 0: // Accueil
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1: // Explorer
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ExploreScreen()),
          (route) => false,
        );
        break;
      case 2: // Messages
        if (authProvider.isAuthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MessagesScreen()),
            (route) => false,
          );
        } else {
          _redirectToLogin();
        }
        break;
      // case 3 est géré plus haut pour ouvrir le menu
    }
  }

  void _redirectToLogin() {
    final l10n = AppLocalizations.of(context)!;

    // Afficher un message informatif
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n
            .loginToAccessAllFeatures), // ✅ CORRIGÉ - Enlevé le ?? 'fallback'
        backgroundColor: const Color(0xFF142FE2),
        action: SnackBarAction(
          label: l10n
              .loginButton, // ✅ CORRIGÉ - Utilisé loginButton au lieu de login
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: widget.appBar,
      body: Stack(
        children: [
          widget.body,
          // Overlay pour le menu latéral
          if (_isMenuOpen)
            GestureDetector(
              onTap: _closeMenu,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Stack(
                  children: [
                    // Zone vide pour fermer le menu
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _closeMenu,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    // Menu latéral
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: SideMenu(
                        onClose: _closeMenu,
                        allowOverflow:
                            _isMenuOpen, // ✅ Passer l'état du menu pour l'effet débordant
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: widget.hasBottomNavigation
          ? _buildFixedHeightBottomNav(context)
          : null,
    );

    //   bottomNavigationBar: widget.hasBottomNavigation
    //       ? AppBottomNavigation(
    //           currentIndex: widget.currentIndex,
    //           onTap: _handleNavigation,
    //         )
    //       : null,
    // );
  }

  // Menu pour les utilisateurs non connectés (utilisé par le SideMenu si besoin)
  Widget _buildGuestMenu() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec bouton de fermeture
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.menu, // ✅ CORRIGÉ - Utilisé l10n au lieu de 'Menu'
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _closeMenu,
                  ),
                ],
              ),
            ),

            const Divider(),

            // Options de menu pour les invités
            _buildMenuItem(
              icon: Icons.home_outlined,
              text: l10n.home, // ✅ CORRIGÉ - Utilisé l10n au lieu de 'Accueil'
              onTap: () {
                _closeMenu();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false);
              },
            ),
            _buildMenuItem(
              icon: Icons.search,
              text: l10n
                  .explore, // ✅ CORRIGÉ - Utilisé l10n au lieu de 'Explorer'
              onTap: () {
                _closeMenu();
                Navigator.pushNamed(context, '/explore');
              },
            ),

            const Spacer(),

            // Boutons de connexion et inscription
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _closeMenu();
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        l10n.loginButton, // ✅ CORRIGÉ - Utilisé l10n au lieu de 'Se connecter'
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _closeMenu();
                        Navigator.pushNamed(context, '/profile-selector');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        l10n.signUp, // ✅ CORRIGÉ - Utilisé l10n au lieu de "S'inscrire"
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Construit un élément de menu
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getBottomNavHeight(BuildContext context) {
    const double navHeight = 85.0; // Votre hauteur souhaitée
    final double systemPadding = MediaQuery.of(context).padding.bottom;
    return navHeight + systemPadding;
  }

// 🎯 Widget de navigation avec hauteur fixe
  Widget _buildFixedHeightBottomNav(BuildContext context) {
    const double fixedNavHeight = 85.0; // Hauteur que vous voulez
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // Hauteur totale = nav + zones de sécurité système
      height: fixedNavHeight + systemBottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Zone de navigation avec votre hauteur exacte
          Container(
            height: fixedNavHeight,
            child: AppBottomNavigation(
              currentIndex: widget.currentIndex,
              onTap: _handleNavigation,
            ),
          ),
          // Espace pour les boutons système (iPhone home indicator, Android nav)
          SizedBox(height: systemBottomPadding),
        ],
      ),
    );
  }

  Widget _buildSimpleFixedNav(BuildContext context) {
    return Container(
      height: 85.0, // Votre hauteur fixe
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom, // Padding système
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AppBottomNavigation(
        currentIndex: widget.currentIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}
