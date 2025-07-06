// lib/ui/screens/auth/profile_selector_screen.dart - VERSION MULTILINGUE COMPLÈTE
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // AJOUT
import 'login_screen.dart';
import 'signup_screen.dart';

class ProfileSelectorScreen extends StatelessWidget {
  const ProfileSelectorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // AJOUT
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),  // Votre image ici
            fit: BoxFit.cover,  // Pour couvrir tout l'écran
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  width: 120,
                  errorBuilder: (context, error, stackTrace) => const Text(
                    'LOGO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Center(
                  
                ),
                const Spacer(),
                Text(
                  l10n.signUpChooseProfile, // TRADUIT
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,  // Couleur du texte adaptée à votre image
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildProfileButton(
                  context, 
                  l10n.clientProfile, // TRADUIT
                  true, 
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignupScreen(initialRole: 'client'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileButton(
                  context, 
                  l10n.providerProfile, // TRADUIT
                  false, 
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignupScreen(initialRole: 'provider'),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.alreadyHaveAccount, // TRADUIT
                      style: const TextStyle(
                        color: Colors.white,  // Couleur du texte adaptée à votre image
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF142FE2),  // Couleur du texte adaptée à votre image
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.loginAction), // TRADUIT
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton(
    BuildContext context, 
    String text, 
    bool isPrimary, 
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
              ? const Color(0xFF142FE2)  // Votre couleur bleue spécifique
              : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: isPrimary ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPrimary ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}