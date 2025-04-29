import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';

class ProfileSelectorScreen extends StatelessWidget {
  const ProfileSelectorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                const Center(
                  child: Text(
                    'LOGO',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,  // Couleur du texte adaptée à votre image
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Inscrivez vous en choisissant votre profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,  // Couleur du texte adaptée à votre image
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildProfileButton(
                  context, 
                  'CLIENT', 
                  true, 
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignupScreen(initialRole: 'client'),
                    ),
                  ),
                ),
                // _buildProfileButton(
                //   context, 
                //   'CLIENT', 
                //   true, 
                //   () => Navigator.pushNamed(context, '/signup', arguments: 'client'),
                // ),
                const SizedBox(height: 16),
                // _buildProfileButton(
                //   context, 
                //   'PRESTATAIRE', 
                //   false, 
                //   () => Navigator.pushNamed(context, '/signup', arguments: 'provider'),
                // ),
                _buildProfileButton(
                  context, 
                  'PRESTATAIRE', 
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
                    const Text(
                      'Vous avez déjà un compte ?',
                      style: TextStyle(
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Se connecter'),
                          Icon(Icons.arrow_forward, size: 16),
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