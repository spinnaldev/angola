// lib/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/services/profile_manager.dart';
import '../widgets/language_selector.dart';
import 'edit_profile_screen.dart';
import 'auth/login_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'help_faq_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Charger les paramètres sauvegardés
    // TODO: Implémenter le chargement depuis SharedPreferences
  }

  Future<void> _saveSettings() async {
    // Sauvegarder les paramètres
    // TODO: Implémenter la sauvegarde dans SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Profil (si connecté)
            if (isLoggedIn && currentUser != null) ...[
              _buildProfileSection(context, currentUser, l10n),
              const SizedBox(height: 24),
            ],

            // Section Langue
            _buildLanguageSection(context, languageProvider, l10n),
            const SizedBox(height: 24),

            // Section Notifications
            _buildNotificationsSection(context, l10n),
            const SizedBox(height: 24),

            // Section Préférences
            // _buildPreferencesSection(context, l10n),
            // const SizedBox(height: 24),

            // Section Support et Aide
            // _buildSupportSection(context, l10n),
            // const SizedBox(height: 24),

            // Section Légal
            _buildLegalSection(context, l10n),
            const SizedBox(height: 24),

            // Section Compte
            if (isLoggedIn) ...[
              _buildAccountSection(context, authProvider, l10n),
            ] else ...[
              _buildAuthSection(context, l10n),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF142FE2),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF142FE2)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFF142FE2),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildProfileSection(BuildContext context, dynamic user, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.profile),
        _buildSettingsCard(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF142FE2),
                backgroundImage: user.profilePicture != null
                    ? NetworkImage(user.profilePicture!)
                    : null,
                child: user.profilePicture == null
                    ? Text(
                        user.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              title: Text(
                '${user.firstName ?? ''} ${user.lastName ?? ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email ?? ''),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ProfileManager.isProviderMode()
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ProfileManager.isProviderMode() ? l10n.provider : l10n.client,
                      style: TextStyle(
                        color: ProfileManager.isProviderMode()
                            ? Colors.blue[700]
                            : Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageSection(BuildContext context, LanguageProvider languageProvider, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.language),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.language,
              title: l10n.language,
              subtitle: languageProvider.currentLanguageName,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const LanguageSelector(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.notifications),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.notifications,
              title: l10n.notifications,
              subtitle: _notificationsEnabled ? 'Activées' : 'Désactivées',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _saveSettings();
                },
                activeColor: const Color(0xFF142FE2),
              ),
              onTap: () {
                setState(() {
                  _notificationsEnabled = !_notificationsEnabled;
                });
                _saveSettings();
              },
            ),
            if (_notificationsEnabled) ...[
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.email,
                title: 'Notifications par email',
                trailing: Switch(
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                    _saveSettings();
                  },
                  activeColor: const Color(0xFF142FE2),
                ),
                onTap: () {
                  setState(() {
                    _emailNotifications = !_emailNotifications;
                  });
                  _saveSettings();
                },
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.phone_android,
                title: 'Notifications push',
                trailing: Switch(
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                    _saveSettings();
                  },
                  activeColor: const Color(0xFF142FE2),
                ),
                onTap: () {
                  setState(() {
                    _pushNotifications = !_pushNotifications;
                  });
                  _saveSettings();
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Préférences'),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.dark_mode,
              title: 'Mode sombre',
              subtitle: _darkModeEnabled ? 'Activé' : 'Désactivé',
              trailing: Switch(
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                  _saveSettings();
                  // TODO: Implémenter le changement de thème
                },
                activeColor: const Color(0xFF142FE2),
              ),
              onTap: () {
                setState(() {
                  _darkModeEnabled = !_darkModeEnabled;
                });
                _saveSettings();
              },
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              icon: Icons.location_on,
              title: l10n.location,
              subtitle: 'Gérer vos préférences de localisation',
              onTap: () {
                // TODO: Ouvrir les paramètres de localisation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paramètres de localisation - À venir'),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Support et Aide'),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Aide et FAQ',
              subtitle: 'Questions fréquemment posées',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpFAQScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              icon: Icons.contact_support,
              title: 'Nous contacter',
              subtitle: 'Support client et assistance',
              onTap: () {
                // TODO: Ouvrir le support client
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support client - À venir'),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              icon: Icons.feedback,
              title: 'Donner un avis',
              subtitle: 'Aidez-nous à améliorer l\'application',
              onTap: () {
                // TODO: Ouvrir le formulaire de feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feedback - À venir'),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegalSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Légal'),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.privacy_tip,
              title: 'Politique de confidentialité',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              icon: Icons.description,
              title: 'Conditions d\'utilisation',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServiceScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'À propos',
              subtitle: 'Version 1.0.0',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Angola Services',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.home_repair_service,
                    size: 48,
                    color: Color(0xFF142FE2),
                  ),
                  children: [
                    const Text('Plateforme de mise en relation entre clients et prestataires de services.'),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, AuthProvider authProvider, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Compte'),
        _buildSettingsCard(
          children: [
            // _buildSettingsTile(
            //   icon: Icons.lock_outline,
            //   title: 'Changer le mot de passe',
            //   onTap: () {
            //     // TODO: Implémenter le changement de mot de passe
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(
            //         content: Text('Changement de mot de passe - À venir'),
            //       ),
            //     );
            //   },
            // ),
            const Divider(height: 1),
            _buildSettingsTile(
              icon: Icons.logout,
              title: 'Déconnexion',
              iconColor: Colors.red,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
              onTap: () {
                _showLogoutDialog(context, authProvider);
              },
            ),
            // const Divider(height: 1),
            // _buildSettingsTile(
            //   icon: Icons.delete_outline,
            //   title: 'Supprimer le compte',
            //   iconColor: Colors.red,
            //   trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
            //   onTap: () {
            //     _showDeleteAccountDialog(context);
            //   },
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuthSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Authentification'),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.login,
              title: l10n.login,
              subtitle: 'Connectez-vous pour accéder à toutes les fonctionnalités',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Supprimer le compte',
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            'Cette action est irréversible. Toutes vos données seront définitivement supprimées.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implémenter la suppression du compte
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Suppression de compte - À implémenter'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}