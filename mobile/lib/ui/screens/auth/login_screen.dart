// lib/ui/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../common/app_textfield.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../../config/routes.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _isValidEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _isValidEmail = value.isNotEmpty &&
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      try {
        final success = await authProvider.login(
          _emailController.text.trim(),  // Utiliser l'email maintenant
          _passwordController.text,
        );

        setState(() {
          _isLoading = false;
        });
        if (success && mounted) {
          // Cette méthode remplace l'écran actuel et supprime tous les écrans précédents
          Navigator.pushNamedAndRemoveUntil(
            context, 
            AppRoutes.explore,  // Utilisez les constantes de AppRoutes
            (route) => false,  // Supprime toute la pile
          );
        }
        // if (success && mounted) {
        //   Navigator.pushReplacementNamed(context, '/home');
        // }
          else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Erreur de connexion'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  // const Text(
                  //   'Se connecter',
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Champ email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _validateEmail,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _emailController.text.isNotEmpty
                              ? _isValidEmail
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : const Icon(Icons.error, color: Colors.red)
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Veuillez entrer un email valide';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Champ mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          return null;
                        },
                      ),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF142FE2),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Mot de passe oublié ?'),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF142FE2),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'SE CONNECTER',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Vous n\'avez pas de compte ?'),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF142FE2),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text('S\'inscrire'),
                                  Icon(Icons.arrow_forward, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Center(
                        child: Text(
                          'Ou connectez-vous avec un compte social.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialLoginButton('assets/images/google.png'),
                          const SizedBox(width: 20),
                          _socialLoginButton('assets/images/facebook.png'),
                        ],
                      ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     SocialLoginButton(
                      //       icon: 'assets/images/google.png',
                      //       onPressed: () {
                      //         // Implémentation de la connexion Google
                      //       },
                      //     ),
                      //     const SizedBox(width: 20),
                      //     SocialLoginButton(
                      //       icon: 'assets/images/facebook.png',
                      //       onPressed: () {
                      //         // Implémentation de la connexion Facebook
                      //       },
                      //     ),
                      //   ],
                      // ),
                      
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialLoginButton(String iconPath) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Image.asset(
          iconPath,
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) => Icon(
            iconPath.contains('google') ? Icons.g_mobiledata : Icons.facebook,
            size: 24,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final String icon;
  final VoidCallback onPressed;

  const SocialLoginButton({
    Key? key,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 30,
            height: 30,
          ),
        ),
      ),
    );
  }
}
