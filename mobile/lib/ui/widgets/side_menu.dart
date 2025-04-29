// lib/ui/widgets/side_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/user.dart';
import '../screens/profile_screen.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;

  const SideMenu({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final User? user = authProvider.currentUser;
        
        if (user == null) {
          return Container(
            color: Colors.white,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        return Container(
          color: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                // En-tête avec bouton de fermeture
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Connecté',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                
                // Profil utilisateur
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                            ? NetworkImage(user.profilePicture!)
                            : null,
                        child: user.profilePicture == null || user.profilePicture!.isEmpty
                            ? Text(
                                user.firstName.isNotEmpty ? user.firstName[0] : 'U',
                                style: const TextStyle(fontSize: 28),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.firstName + ' ' + user.lastName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Options principales
                _buildMenuItem(
                  context,
                  icon: Icons.person_outline,
                  text: 'Mon profil',
                  onTap: () {
                    onClose(); // Fermer le menu
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
                    onClose(); // Fermer le menu
                    // Navigation vers les messages
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_none,
                  text: 'Notifications',
                  onTap: () {
                    onClose(); // Fermer le menu
                    // Navigation vers les notifications
                  },
                ),
                
                const Spacer(),
                
                // Options de bas de page
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  text: 'Paramètres',
                  onTap: () {
                    onClose(); // Fermer le menu
                    // Navigation vers les paramètres
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  text: 'Aide et FAQ',
                  onTap: () {
                    onClose(); // Fermer le menu
                    // Navigation vers l'aide
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  text: 'Déconnexion',
                  onTap: () async {
                    onClose(); // Fermer le menu
                    await authProvider.logout();
                    if (context.mounted) {
                      // Rediriger vers la page de connexion
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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