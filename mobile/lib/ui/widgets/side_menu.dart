// lib/ui/widgets/side_menu.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:w3_loc/ui/screens/client/client_projects_screen.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/user.dart';
import '../screens/disputes/disputes_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/provider/service_management_screen.dart';
import '../screens/provider/quote_requests_screen.dart';
import '../screens/client/my_quote_requests_screen.dart';
import '../screens/home_screen.dart';
import '../screens/explore_screen.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;

  const SideMenu({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Utiliser MediaQuery pour obtenir la largeur de l'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = screenWidth * 0.85; // 85% de la largeur d'écran

    return Container(
      width: menuWidth, // Définir explicitement la largeur
      color: Colors.white,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final User? user = authProvider.currentUser;
          final bool isLoggedIn = user != null;

          if (isLoggedIn) {
            return _buildUserMenu(context, user, authProvider);
          } else {
            return _buildGuestMenu(context);
          }
        },
      ),
    );
  }

  // Menu pour les utilisateurs connectés
  Widget _buildUserMenu(
      BuildContext context, User user, AuthProvider authProvider) {
    return SafeArea(
      bottom: false, // Permettre au contenu de déborder en bas
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec bouton de fermeture et image de profil
          Stack(
            clipBehavior:
                Clip.none, // Important pour permettre au cercle de déborder
            children: [
              // En-tête avec bouton de fermeture
              Padding(
                padding: const EdgeInsets.fromLTRB(65.0, 16.0, 16.0,
                    16.0), // Plus de padding à gauche pour l'avatar
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            user.username.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),

              // Photo de profil positionnée à moitié en dehors
              Positioned(
                left: -25, // Position négative pour déborder sur la gauche
                top: 16,
                child: Container(
                  padding: const EdgeInsets.all(3), // Bordure blanche externe
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2), // Bordure bleue interne
                    decoration: const BoxDecoration(
                      color: Color(0xFF142FE2), // Couleur bleue primaire
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: user.profilePicture != null &&
                              user.profilePicture!.isNotEmpty
                          ? NetworkImage(user.profilePicture!)
                          : null,
                      child: user.profilePicture == null ||
                              user.profilePicture!.isEmpty
                          ? Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 1), // Ligne de séparation après l'en-tête

          // Options du menu - première section
          _buildMenuItem(
            context,
            icon: Icons.home_outlined,
            text: 'Accueil',
            onTap: () {
              onClose();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.search_outlined,
            text: 'Explorer',
            onTap: () {
              onClose();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExploreScreen()),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            text: 'Mon profil',
            onTap: () {
              onClose();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.chat_bubble_outline,
            text: 'Message',
            onTap: () {
              onClose();
              Navigator.pushNamed(context, '/messages');
            },
          ),

          // Options spécifiques selon le rôle
          if (user.role == 'provider') ...[
            _buildMenuItem(
              context,
              icon: Icons.home_repair_service_outlined,
              text: 'Mes services',
              onTap: () {
                onClose();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ServiceManagementScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.receipt_long_outlined,
              text: 'Devis',
              onTap: () {
                onClose();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const QuoteRequestsScreen()),
                );
              },
            ),
          ],

          if (user.role == 'client')
            _buildMenuItem(
              context,
              icon: Icons.work_outline,
              text: 'Mes projets',
              onTap: () {
                onClose();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientProjectsScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.receipt_long_outlined,
              text: 'Devis',
              onTap: () {
                onClose();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyQuoteRequestsScreen()),
                );
              },
            ),
          
          _buildMenuItem(
            context,
            icon: Icons.gavel,
            text: 'Mes litiges',
            onTap: () {
              onClose();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DisputesScreen(),
                ),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.notifications_none,
            text: 'Notifications',
            onTap: () {
              onClose();
              // Navigation vers notifications
            },
          ),

          const Spacer(),

          // Options de bas de page
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            text: 'Paramètres',
            onTap: () {
              onClose();
              // Navigation vers paramètres
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            text: 'Aide et FAQ',
            onTap: () {
              onClose();
              // Navigation vers aide
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            text: 'Déconnexion',
            onTap: () async {
              onClose();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              }
            },
          ),

          const SizedBox(height: 24), // Plus d'espace en bas
        ],
      ),
    );
  }

  // Menu pour les utilisateurs non connectés
  Widget _buildGuestMenu(BuildContext context) {
    return SafeArea(
      bottom: false, // Permettre au contenu de déborder en bas
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

          const Divider(height: 1),

          // Options de menu pour les invités
          _buildMenuItem(
            context,
            icon: Icons.home_outlined,
            text: 'Accueil',
            onTap: () {
              onClose();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            },
          ),
          _buildMenuItem(
            context,
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
                      Navigator.pushNamed(context, '/login');
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
                      Navigator.pushNamed(context, '/profile-selector');
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
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
