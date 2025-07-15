// lib/ui/screens/guest_settings_screen.dart - VERSION POUR MENU LATÉRAL
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../widgets/language_selector.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'auth/login_screen.dart';

class GuestSettingsScreen extends StatefulWidget {
  const GuestSettingsScreen({Key? key}) : super(key: key);

  @override
  State<GuestSettingsScreen> createState() => _GuestSettingsScreenState();
}

class _GuestSettingsScreenState extends State<GuestSettingsScreen> {
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Authentification
            _buildAuthenticationSection(context, l10n),
            const SizedBox(height: 24),
            
            // Section Langue
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return _buildLanguageSection(context, languageProvider, l10n);
              },
            ),
            const SizedBox(height: 24),
            
            // Section Préférences
            _buildPreferencesSection(context, l10n),
            const SizedBox(height: 24),
            
            // Section Support et Aide
            _buildSupportSection(context, l10n),
            const SizedBox(height: 24),
            
            // Section Légal
            _buildLegalSection(context, l10n),
            const SizedBox(height: 24),
            
            // Section À propos
            _buildAboutSection(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.blue,
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
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildAuthenticationSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.authentication),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.login,
              title: l10n.login,
              subtitle: l10n.loginToAccessAllFeatures,
              iconColor: Colors.green,
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
              iconColor: Colors.purple,
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

  Widget _buildPreferencesSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.preferences),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.dark_mode,
              title: l10n.darkMode,
              subtitle: _darkModeEnabled ? l10n.enabled : l10n.disabled,
              iconColor: Colors.orange,
              trailing: Switch(
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                  // TODO: Implémenter la sauvegarde du mode sombre
                },
              ),
              onTap: () {
                setState(() {
                  _darkModeEnabled = !_darkModeEnabled;
                });
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
        _buildSectionTitle(l10n.supportAndHelp),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: l10n.frequentlyAskedQuestions,
              iconColor: Colors.teal,
              onTap: () {
                // Navigation vers FAQ
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpFAQScreen()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.frequentlyAskedQuestions} - ${l10n.notificationsComingSoon}')),
                );
              },
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              icon: Icons.contact_support,
              title: l10n.contactUs,
              subtitle: l10n.customerSupportAssistance,
              iconColor: Colors.teal,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.contactUs} - ${l10n.customerSupportComingSoon}')),
                );
              },
            ),
            const Divider(height: 1),
            _buildSettingsTile(
              icon: Icons.feedback,
              title: l10n.giveFeedback,
              subtitle: l10n.helpUsImproveApp,
              iconColor: Colors.teal,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.giveFeedback} - ${l10n.feedbackComingSoon}')),
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
        _buildSectionTitle(l10n.legal),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.privacy_tip,
              title: l10n.privacyPolicy,
              iconColor: Colors.indigo,
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
              title: l10n.termsOfService,
              iconColor: Colors.indigo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServiceScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.about),
        _buildSettingsCard(
          children: [
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: l10n.appName,
              subtitle: l10n.appDescription,
              iconColor: Colors.blue,
              trailing: const Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: l10n.appName,
                  applicationVersion: '1.0.0',
                  applicationIcon: const FlutterLogo(size: 48),
                  children: [
                    Text(l10n.appDescription),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}