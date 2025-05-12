// lib/ui/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/side_menu.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'messaging/messages_screen.dart';

class BaseScreen extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final Widget? appBar;
  final bool hasBottomNavigation;

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

    switch (index) {
      case 0:
        // Accueil
        if (widget.currentIndex != 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
        break;
      case 1:
        // Explorer
        if (widget.currentIndex != 1) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ExploreScreen()),
            (route) => false,
          );
        }
        break;
      case 2:
        // Messages
        if (widget.currentIndex != 2) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MessagesScreen()),
            (route) => false,
          );
        }
        break;
      case 3:
        // Profil - Ouvrir le menu latéral
        _openMenu();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuWidth = MediaQuery.of(context).size.width * 0.85; // 85% de la largeur
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;

    return Scaffold(
      body: Stack(
        children: [
          // Contenu principal
          Column(
            children: [
              // AppBar personnalisé si fourni
              if (widget.appBar != null) widget.appBar!,
              
              // Contenu principal
              Expanded(child: widget.body),
            ],
          ),

          // Superposition semi-transparente quand le menu est ouvert
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: Container(
                  color: Colors.black54, // Fond semi-transparent
                ),
              ),
            ),

          // Menu latéral avec animation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isMenuOpen ? 0 : -menuWidth, // Position depuis la droite
            top: 0,
            bottom: 0,
            width: menuWidth,
            child: GestureDetector(
              // Empêche les taps sur le menu de fermer la superposition
              onTap: () {},
              child: isLoggedIn
                  ? SideMenu(onClose: _closeMenu)
                  : _buildGuestMenu(),
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
  }

  // Menu pour les utilisateurs non connectés
  Widget _buildGuestMenu() {
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
                  const Text(
                    'Menu',
                    style: TextStyle(
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
              text: 'Accueil',
              onTap: () {
                _closeMenu();
                _handleNavigation(0);
              },
            ),
            _buildMenuItem(
              icon: Icons.search,
              text: 'Explorer',
              onTap: () {
                _closeMenu();
                _handleNavigation(1);
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
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
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
                      child: const Text(
                        'S\'inscrire',
                        style: TextStyle(
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

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[800]),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}