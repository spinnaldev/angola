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
      child: Stack(
        children: [
          // Contenu principal du menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec bouton fermer
              _buildHeader(context),
              
              // Espace pour la photo de profil qui dépasse
              const SizedBox(height: 50), // Réduit pour s'adapter
              
              // Informations utilisateur (nom, email, badge)
              _buildUserInfo(context, user),
              
              // Menu principal selon le profil actuel
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20), // Réduit de 32 à 20
                        
                        if (ProfileManager.isProviderMode()) ...[
                          _buildProviderMenu(context),
                        ] else ...[
                          _buildClientMenu(context),
                        ],
                        
                        const SizedBox(height: 16), // Réduit de 24 à 16
                        
                        // Menu commun à tous les profils
                        _buildCommonMenu(context),
                        
                        const SizedBox(height: 16), // Réduit de 24 à 16
                        
                        // Section Profil et Compte
                        _buildProfileSection(context),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Menu de bas de page
              Padding(
                padding: const EdgeInsets.only(left: 24.0, bottom: 24.0),
                child: _buildBottomMenu(context),
              ),
            ],
          ),
          
          // Photo de profil positionnée au-dessus du menu (dépassante)
          Positioned(
            top: 50, // Position depuis le haut ajustée
            left: -20, // Position moins négative pour être plus visible
            child: _buildProfileAvatar(context, user),
          ),
        ],
      ),
    );
  }

  /// En-tête avec juste le bouton fermer
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

  /// Photo de profil dépassante (positionnée avec Positioned)
  Widget _buildProfileAvatar(BuildContext context, User user) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 30, // Réduit pour s'adapter au layout
        backgroundColor: Theme.of(context).primaryColor,
        backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
            ? NetworkImage(user.profilePicture!)
            : null,
        child: user.profilePicture == null || user.profilePicture!.isEmpty
            ? Text(
                user.fullName?.isNotEmpty == true ? user.fullName![0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 24,
                ),
              )
            : null,
      ),
    );
  }

  /// Informations utilisateur (email et badge uniquement)
  Widget _buildUserInfo(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.only(left: 70.0, right: 24.0, top: 8.0), // Marge à gauche pour l'avatar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email et badge prestataire sur la même ligne
          Row(
            children: [
              // Email de l'utilisateur
              Expanded(
                child: Text(
                  user.email ?? 'user@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Badge prestataire/client
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.role == 'provider' 
                      ? const Color(0xFF142FE2).withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.role == 'provider' ? 'Prestataire' : 'Client',
                  style: TextStyle(
                    color: user.role == 'provider' 
                        ? const Color(0xFF142FE2)
                        : Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        // _buildMenuItem(
        //   context,
        //   icon: Icons.analytics_outlined,
        //   text: 'Statistiques',
        //   onTap: () {
        //     onClose();
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(content: Text('Statistiques - À venir')),
        //     );
        //   },
        // ),
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
        // Section vide pour l'instant
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
          
          // Options de menu pour les invités
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20), // Réduit
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

  /// Construit un élément de menu avec espacement réduit
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
        padding: const EdgeInsets.symmetric(vertical: 12.0), // Réduit de 16 à 12
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 24,
            ),
            const SizedBox(width: 16), // Réduit de 20 à 16
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