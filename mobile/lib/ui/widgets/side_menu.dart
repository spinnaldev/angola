// lib/ui/widgets/side_menu.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/user.dart';
import '../screens/profile_screen.dart';
import '../screens/provider/service_management_screen.dart';
import '../screens/provider/quote_requests_screen.dart';
import '../screens/client/my_quote_requests_screen.dart';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec bouton de fermeture
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
                
                // Profil utilisateur avec photo décalée à gauche
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo de profil
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Cercle de fond
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                shape: BoxShape.circle,
                              ),
                              child: user.profilePicture != null && user.profilePicture!.isNotEmpty
                                ? null
                                : Center(
                                    child: Text(
                                      user.firstName.isNotEmpty ? user.firstName[0] : 'U',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                            ),
                            
                            // Image de profil si disponible
                            if (user.profilePicture != null && user.profilePicture!.isNotEmpty)
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(user.profilePicture!),
                              ),
                          ],
                        ),
                      ),
                      
                      // Email uniquement
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
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
                      ),
                    ],
                  ),
                ),
                
                // Options du menu - première section
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
                    // Navigation vers messages
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
                        MaterialPageRoute(builder: (context) => const ServiceManagementScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    text: 'Demandes de devis',
                    onTap: () {
                      onClose();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QuoteRequestsScreen()),
                      );
                    },
                  ),
                ],
                
                if (user.role == 'client')
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    text: 'Demandes de devis',
                    onTap: () {
                      onClose();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyQuoteRequestsScreen()),
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
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 16),
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