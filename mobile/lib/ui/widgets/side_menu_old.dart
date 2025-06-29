// lib/ui/widgets/side_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../../core/models/user.dart';
import '../screens/provider/service_management_screen.dart';
import '../screens/provider/quote_requests_screen.dart';
import '../screens/client/client_projects_screen.dart';
import '../screens/client/my_quote_requests_screen.dart';
import '../screens/disputes/disputes_screen.dart';
import '../screens/profile_screen.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;

  const SideMenu({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        return Container(
          color: Colors.white,
          child: user != null 
            ? _buildAuthenticatedMenu(context, user)
            : _buildGuestMenu(context),
        );
      },
    );
  }

  /// Menu pour les utilisateurs connectés
  Widget _buildAuthenticatedMenu(BuildContext context, User user) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec bouton fermer séparé - NOUVEAU DESIGN
          _buildHeader(context),
          
          // Profile utilisateur - NOUVEAU DESIGN  
          _buildUserProfile(context, user),
          
          // Menu principal selon le profil actuel
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 24.0), // Marge à gauche pour tous les menus
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32), // Espacement après le profil
                    
                    if (ProfileManager.isProviderMode()) ...[
                      _buildProviderMenu(context),
                    ] else ...[
                      _buildClientMenu(context),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Menu commun à tous les profils
                    _buildCommonMenu(context),
                    
                    const SizedBox(height: 24),
                    
                    // Section Profil et Compte
                    _buildProfileSection(context),
                  ],
                ),
              ),
            ),
          ),
          
          // Menu de bas de page avec marge
          Padding(
            padding: const EdgeInsets.only(left: 24.0, bottom: 24.0),
            child: _buildBottomMenu(context),
          ),
        ],
      ),
    );
  }

  /// NOUVEAU : En-tête avec juste le bouton fermer
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            iconSize: 24,
          ),
        ],
      ),
    );
  }

  /// NOUVEAU : Section profil utilisateur selon le design Figma
  Widget _buildUserProfile(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de profil plus volumineuse
          CircleAvatar(
            radius: 40, // Plus grand (était 20)
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              user.fullName?.isNotEmpty == true ? user.fullName![0].toUpperCase() : 'U',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontSize: 32, // Plus grand texte pour la plus grande image
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Email de l'utilisateur seulement (pas le nom)
          Text(
            user.email ?? 'user@example.com',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Menu spécifique aux prestataires
  Widget _buildProviderMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuItem(
          context,
          icon: Icons.home_repair_service_outlined,
          text: 'Mes services',
          onTap: () {
            onClose();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ServiceManagementScreen(),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.request_quote_outlined,
          text: 'Demandes reçues',
          onTap: () {
            onClose();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuoteRequestsScreen(),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.work_outline,
          text: 'Projets disponibles',
          onTap: () {
            onClose();
            Navigator.pushNamed(context, '/projects');
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.analytics_outlined,
          text: 'Statistiques',
          onTap: () {
            onClose();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Statistiques - À venir')),
            );
          },
        ),
      ],
    );
  }

  /// Menu spécifique aux clients
  Widget _buildClientMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuItem(
          context,
          icon: Icons.home_outlined,
          text: 'Accueil',
          onTap: () {
            onClose();
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.search_outlined,
          text: 'Explorer',
          onTap: () {
            onClose();
            Navigator.pushNamed(context, '/explore');
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
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
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
                builder: (context) => const MyQuoteRequestsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Menu commun à tous les profils
  Widget _buildCommonMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuItem(
          context,
          icon: Icons.gavel,
          text: ProfileManager.isProviderMode() ? 'Mes réclamations' : 'Mes litiges',
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications - À venir')),
            );
          },
        ),
      ],
    );
  }

  /// Section Profil et Compte
  Widget _buildProfileSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plus besoin de divider ici selon le design Figma
        // Pas de "Mon Profil" car déjà dans le menu principal
      ],
    );
  }

  /// Menu de bas de page
  Widget _buildBottomMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuItem(
          context,
          icon: Icons.settings_outlined,
          text: 'Paramètres',
          onTap: () {
            onClose();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paramètres - À venir')),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.help_outline,
          text: 'Aide et FAQ',
          onTap: () {
            onClose();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Aide et FAQ - À venir')),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.logout,
          text: 'Déconnexion',
          onTap: () async {
            onClose();
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
      ],
    );
  }

  /// Menu pour les utilisateurs non connectés
  Widget _buildGuestMenu(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec bouton de fermeture
          _buildHeader(context),
          
          // Options de menu pour les invités avec marge
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildMenuItem(
                    context,
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
                    context,
                    icon: Icons.search,
                    text: 'Explorer',
                    onTap: () {
                      onClose();
                      Navigator.pushNamed(context, '/explore');
                    },
                  ),
                  
                  const Spacer(),
                ],
              ),
            ),
          ),
          
          // Boutons de connexion/inscription
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      onClose();
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Se connecter'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      onClose();
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('S\'inscrire'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un élément de menu - STYLE SIMPLIFIÉ selon Figma
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0), // Plus d'espacement vertical
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 24,
            ),
            const SizedBox(width: 20), // Espacement entre l'icône et le texte
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
}