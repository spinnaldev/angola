// lib/ui/widgets/side_menu.dart - AJOUT DE "MES OFFRES" SANS CHANGER LE DESIGN

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:teyago/providers/language_provider.dart';
import 'package:teyago/ui/screens/help_faq_screen.dart';
import 'package:teyago/ui/widgets/language_selector.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/profile_manager.dart';
import '../../core/models/user.dart';
import '../screens/provider/service_management_screen.dart';
import '../screens/provider/quote_requests_screen.dart';
import '../screens/provider/my_offers_screen.dart'; // NOUVEAU IMPORT
import '../screens/client/client_projects_screen.dart';
import '../screens/client/my_quote_requests_screen.dart';
import '../screens/disputes/disputes_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import 'package:teyago/ui/screens/auth/profile_selector_screen.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;
  final bool allowOverflow;

  const SideMenu({Key? key, required this.onClose, this.allowOverflow = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Container(
          color: Colors.white,
          child: user != null
              ? _buildAuthenticatedMenu(context, user, l10n)
              : _buildGuestMenu(context, l10n),
        );
      },
    );
  }

  /// Menu pour les utilisateurs connectés (VOTRE CODE ORIGINAL)
  Widget _buildAuthenticatedMenu(BuildContext context, User user, AppLocalizations l10n) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec bouton fermer (VOTRE CODE ORIGINAL)
          _buildHeader(context),
          
          // Section avec photo - CONDITION ici (VOTRE CODE ORIGINAL)
          Container(
            height: 100,
            child: allowOverflow 
              ? Stack( // Menu ouvert : avec débordement
                  clipBehavior: Clip.none,
                  children: [
                    // Photo débordante (VOTRE CODE ORIGINAL)
                    Positioned(
                      left: -35,
                      top: 10,
                      child: _buildProfileAvatar(context, user),
                    ),
                    // Email aligné (VOTRE CODE ORIGINAL)
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

          // Menu principal selon le profil actuel (VOTRE CODE ORIGINAL + AJOUT)
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    if (ProfileManager.isProviderMode()) ...[
                      _buildProviderMenu(context, l10n), // MODIFIÉ POUR AJOUTER "MES OFFRES"
                    ] else ...[
                      _buildClientMenu(context, l10n),
                    ],
                    const SizedBox(height: 16),
                    _buildCommonMenu(context, l10n),
                    const SizedBox(height: 16),
                    _buildProfileSection(context, l10n),
                  ],
                ),
              ),
            ),
          ),

          // Menu de bas de page (VOTRE CODE ORIGINAL)
          Padding(
            padding: const EdgeInsets.only(left: 24.0, bottom: 24.0),
            child: _buildBottomMenu(context, l10n),
          ),
        ],
      ),
    );
  }

  /// En-tête avec juste le bouton fermer (VOTRE CODE ORIGINAL)
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

  /// Photo de profil dépassante (VOTRE CODE ORIGINAL)
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

  /// Informations utilisateur (VOTRE CODE ORIGINAL)
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

  /// Menu spécifique aux prestataires (VOTRE CODE ORIGINAL + AJOUT "MES OFFRES")
  Widget _buildProviderMenu(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuItem(
          context,
          icon: Icons.person_outline,
          text: l10n.myProfile,
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
          text: l10n.myServices,
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
          text: l10n.receivedRequests,
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
        // ✅ NOUVEAU : Ajout de "Mes offres" pour les prestataires
        _buildMenuItem(
          context,
          icon: Icons.work_outline,
          text: l10n.myOffers,
          onTap: () {
            onClose();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyOffersScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Menu spécifique aux clients (VOTRE CODE ORIGINAL)
  Widget _buildClientMenu(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuItem(
          context,
          icon: Icons.home_outlined,
          text: l10n.home,
          onTap: () {
            onClose();
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.search_outlined,
          text: l10n.explore,
          onTap: () {
            onClose();
            Navigator.pushNamed(context, '/explore');
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.person_outline,
          text: l10n.myProfile,
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
          text: l10n.messages,
          onTap: () {
            onClose();
            Navigator.pushNamed(context, '/messages');
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.work_outline,
          text: l10n.myProjects,
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
          text: l10n.quotes,
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

  /// Menu commun à tous les profils (VOTRE CODE ORIGINAL)
  Widget _buildCommonMenu(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuItem(
          context,
          icon: Icons.gavel,
          text: ProfileManager.isProviderMode()
              ? l10n.myComplaints
              : l10n.myDisputes,
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
          text: l10n.notifications,
          onTap: () {
            onClose();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.notificationsComingSoon)),
            );
          },
        ),
      ],
    );
  }

  /// Section Profil et Compte (VOTRE CODE ORIGINAL)
  Widget _buildProfileSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section vide pour l'instant
      ],
    );
  }

  /// Menu de bas de page (VOTRE CODE ORIGINAL)
  Widget _buildBottomMenu(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuItem(
          context,
          icon: Icons.settings_outlined,
          text: l10n.settings,
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
          text: l10n.helpAndFAQ,
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
          text: l10n.logout,
          onTap: () async {
            onClose();
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
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

  /// Menu pour les utilisateurs non connectés (VOTRE CODE ORIGINAL)
  Widget _buildGuestMenu(BuildContext context, AppLocalizations l10n) {
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
                    text: l10n.home,
                    onTap: () {
                      onClose();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.search,
                    text: l10n.explore,
                    onTap: () {
                      onClose();
                      Navigator.pushNamed(context, '/explore');
                    },
                  ),
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return _buildMenuItem(
                        context,
                        icon: Icons.language_outlined,
                        text: '${l10n.language} (${languageProvider.currentLanguageName})',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const LanguageSelector(),
                          );
                        },
                      );
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
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      onClose();
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(l10n.login),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      onClose();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSelectorScreen(),
                        ),
                      );
                    },
                    child: Text(l10n.register),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un élément de menu avec espacement réduit (VOTRE CODE ORIGINAL)
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