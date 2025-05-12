// lib/core/services/menu_service.dart
import 'package:flutter/material.dart';
import '../../ui/widgets/side_menu.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/auth/profile_selector_screen.dart';

class MenuService {
  // Singleton pattern
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;
  MenuService._internal();
  
  // État du menu
  bool _isMenuOpen = false;
  
  // Getter pour l'état du menu
  bool get isMenuOpen => _isMenuOpen;
  
  // Méthode pour ouvrir le menu
  void openMenu() {
    _isMenuOpen = true;
  }
  
  // Méthode pour fermer le menu
  void closeMenu() {
    _isMenuOpen = false;
  }
  
  // Méthode pour basculer l'état du menu
  void toggleMenu() {
    _isMenuOpen = !_isMenuOpen;
  }
  
  // Méthode pour afficher le menu approprié selon l'état d'authentification
  Widget buildMenu(BuildContext context, bool isLoggedIn, VoidCallback onClose) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: _isMenuOpen ? 0 : -MediaQuery.of(context).size.width * 0.85,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: GestureDetector(
        // Empêche les taps sur le menu de fermer la superposition
        onTap: () {},
        child: isLoggedIn 
          ? SideMenu(onClose: onClose)
          : _buildGuestMenu(context, onClose),
      ),
    );
  }
  
  // Menu pour les utilisateurs non connectés
  Widget _buildGuestMenu(BuildContext context, VoidCallback onClose) {
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
                    onPressed: onClose,
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
                onClose();
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/home', 
                  (route) => false
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.search,
              text: 'Explorer',
              onTap: () {
                onClose();
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
                        onClose();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF142FE2),
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
                        onClose();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileSelectorScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF142FE2),
                        side: const BorderSide(color: Color(0xFF142FE2)),
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
  
  // Méthode pour construire l'overlay semi-transparent
  Widget buildOverlay(VoidCallback onTap) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.black54,
        ),
      ),
    );
  }
}