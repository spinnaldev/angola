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
          // En-tête utilisateur
          _buildUserHeader(context, user),
          
          const Divider(),
          
          // Menu principal selon le profil actuel
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (ProfileManager.isProviderMode()) ...[
                    _buildProviderMenu(context),
                  ] else ...[
                    _buildClientMenu(context),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Menu commun à tous les profils
                  _buildCommonMenu(context),
                ],
              ),
            ),
          ),
          
          const Divider(),
          
          // Menu de bas de page
          _buildBottomMenu(context),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// En-tête avec informations utilisateur
  Widget _buildUserHeader(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.lastName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ProfileManager.isProviderMode() 
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ProfileManager.getProfileLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          color: ProfileManager.isProviderMode() 
                            ? Colors.blue[700]
                            : Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Menu spécifique aux prestataires
  Widget _buildProviderMenu(BuildContext context) {
    return Column(
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
            // Navigation vers statistiques prestataire
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
      children: [
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
          text: 'Mes devis',
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
        _buildMenuItem(
          context,
          icon: Icons.favorite_outline,
          text: 'Mes favoris',
          onTap: () {
            onClose();
            // Navigation vers favoris
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Favoris - À venir')),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.history,
          text: 'Historique',
          onTap: () {
            onClose();
            // Navigation vers historique
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Historique - À venir')),
            );
          },
        ),
      ],
    );
  }

  /// Menu commun à tous les profils
  Widget _buildCommonMenu(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          icon: Icons.gavel,
          text: ProfileManager.isProviderMode() ? 'Réclamations' : 'Litiges',
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications - À venir')),
            );
          },
        ),
      ],
    );
  }

  /// Menu de bas de page
  Widget _buildBottomMenu(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          icon: Icons.settings_outlined,
          text: 'Paramètres',
          onTap: () {
            onClose();
            // Navigation vers paramètres
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
            // Navigation vers aide
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
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
          
          // Boutons de connexion/inscription
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
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Construit un élément de menu
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey[700],
        size: 24,
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}