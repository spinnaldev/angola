// lib/ui/widgets/side_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teyago/ui/screens/help_faq_screen.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../../core/models/user.dart';
import '../screens/provider/service_management_screen.dart';
import '../screens/provider/quote_requests_screen.dart';
import '../screens/client/client_projects_screen.dart';
import '../screens/client/my_quote_requests_screen.dart';
import '../screens/disputes/disputes_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;
  final bool allowOverflow;

  const SideMenu({Key? key, required this.onClose, this.allowOverflow = false})
      : super(key: key);

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
          // En-tête avec bouton fermer
          _buildHeader(context),
          
          // Section avec photo - CONDITION ici
          Container(
            height: 100,
            child: allowOverflow 
              ? Stack( // Menu ouvert : avec débordement
                  clipBehavior: Clip.none,
                  children: [
                    // Photo débordante
                    Positioned(
                      left: -35,
                      top: 10,
                      child: _buildProfileAvatar(context, user),
                    ),
                    // Email aligné
                    Positioned(
                      top: 30,
                      left: 45,
                      right: 24,
                      child: _buildUserInfo(context, user),
                    ),
                  ],
                )
              : Row( // Menu fermé : sans débordement
                  children: [
                    const SizedBox(width: 24),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: _buildProfileAvatar(context, user),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30, right: 24),
                        child: _buildUserInfo(context, user),
                      ),
                    ),
                  ],
                ),
          ),

          // Menu principal selon le profil actuel
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    if (ProfileManager.isProviderMode()) ...[
                      _buildProviderMenu(context),
                    ] else ...[
                      _buildClientMenu(context),
                    ],
                    const SizedBox(height: 16),
                    _buildCommonMenu(context),
                    const SizedBox(height: 16),
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
          width: 3,
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
        radius: 35, // Taille optimale pour l'effet à cheval
        backgroundColor: Theme.of(context).primaryColor,
        backgroundImage:
            user.profilePicture != null && user.profilePicture!.isNotEmpty
                ? NetworkImage(user.profilePicture!)
                : null,
        child: user.profilePicture == null || user.profilePicture!.isEmpty
            ? Text(
                user.fullName?.isNotEmpty == true
                    ? user.fullName![0].toUpperCase()
                    : 'U',
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
    return Text(
      user.email ?? 'user@example.com',
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[700],
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
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
          text: 'Mes offres',
          onTap: () {
            onClose();
            Navigator.pushNamed(context, '/');
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
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
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
          text: ProfileManager.isProviderMode()
              ? 'Mes réclamations'
              : 'Mes litiges',
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.help_outline,
          text: 'Aide et FAQ',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpFAQScreen(),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.logout,
          text: 'Déconnexion',
          onTap: () async {
            // ✅ NE PAS APPELER onClose() ICI - on le fera après
            // onClose(); ← SUPPRIMER CETTE LIGNE
            
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            
            // Sauvegarder une référence au Navigator avant la déconnexion
            final navigator = Navigator.of(context);
            
            // Déconnexion (SANS passer le contexte)
            await authProvider.logout();
            
            // ✅ Fermer le menu PUIS naviguer
            navigator.pop(); // Ferme le menu/bottomSheet
            
            // Navigation vers l'accueil
            navigator.pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          },
        )
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
        padding:
            const EdgeInsets.symmetric(vertical: 12.0), // Réduit de 16 à 12
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
