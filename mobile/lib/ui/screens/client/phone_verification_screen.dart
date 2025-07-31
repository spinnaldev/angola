
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:teyago/ui/widgets/loading_indicator.dart';
import '../../../providers/phone_verification_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/verification/verification_status_card.dart';
import '../../widgets/verification/countdown_timer_widget.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({Key? key}) : super(key: key);

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final PageController _pageController = PageController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  int _currentStep = 0;
  String _selectedCountryCode = '+229'; // Bénin par défaut

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVerificationStatus();
    });
  }

  Future<void> _loadVerificationStatus() async {
    final provider = Provider.of<PhoneVerificationProvider>(context, listen: false);
    await provider.fetchVerificationStatus();
    
    // Si déjà vérifié ou en cours, aller directement à l'étape appropriée
    if (provider.verification != null) {
      if (provider.isVerified || provider.isPending) {
        setState(() {
          _currentStep = 1;
          _phoneController.text = provider.phoneNumber;
        });
        _pageController.jumpToPage(1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification téléphone'),
        elevation: 0,
      ),
      body: Consumer<PhoneVerificationProvider>(
        builder: (context, verificationProvider, _) {
          if (verificationProvider.isLoading && verificationProvider.verification == null) {
            return const Center(child: LoadingIndicator());
          }
          
          // Si déjà vérifié
          if (verificationProvider.isVerified) {
            return _buildVerifiedPhone();
          }
          
          // Processus de vérification
          return _buildVerificationProcess(verificationProvider);
        },
      ),
    );
  }

  Widget _buildVerifiedPhone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.verified,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Téléphone vérifié !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<PhoneVerificationProvider>(
              builder: (context, provider, _) {
                return Text(
                  'Votre numéro ${provider.phoneNumber} a été vérifié avec succès. Vous pouvez maintenant utiliser toutes les fonctionnalités de la plateforme.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Retour au profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationProcess(PhoneVerificationProvider provider) {
    return Column(
      children: [
        // Indicateur de progression
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              for (int i = 0; i < 2; i++) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: i <= _currentStep ? Theme.of(context).primaryColor : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i <= _currentStep ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (i < 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < _currentStep ? Theme.of(context).primaryColor : Colors.grey[300],
                    ),
                  ),
              ],
            ],
          ),
        ),
        
        // Contenu des étapes
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            children: [
              _buildPhoneInputStep(provider),
              _buildCodeVerificationStep(provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputStep(PhoneVerificationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre numéro de téléphone',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nous allons envoyer un code de vérification à ce numéro.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            
            // Sélection du pays
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('🇧🇯', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Bénin $_selectedCountryCode',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Saisie du numéro
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '61234567',
                prefixText: '$_selectedCountryCode ',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre numéro de téléphone';
                }
                if (value.length < 8) {
                  return 'Numéro trop court';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Bouton d'envoi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _sendCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Envoyer le code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Informations de sécurité
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Pourquoi vérifier votre téléphone ?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Protège votre compte contre les accès non autorisés\n'
                    '• Permet de récupérer votre compte si nécessaire\n'
                    '• Garantit la confiance entre utilisateurs\n'
                    '• Requis pour publier des projets et laisser des avis',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeVerificationStep(PhoneVerificationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saisir le code de vérification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Un code à 6 chiffres a été envoyé au ${provider.phoneNumber}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          
          // Saisie du code
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              labelText: 'Code de vérification',
              hintText: '000000',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            maxLength: 6,
            onChanged: (value) {
              if (value.length == 6) {
                _verifyCode(provider);
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Timer et bouton renvoyer
          Center(
            child: CountdownTimerWidget(
              timeRemaining: provider.verification?.timeRemaining ?? 0,
              canResend: provider.verification?.canResend ?? false,
              isLoading: provider.isLoading,
              onResendPressed: () => _resendCode(provider),
            ),
          ),
          const SizedBox(height: 24),
          
          // Bouton de vérification
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.isLoading || _codeController.text.length != 6 
                  ? null 
                  : () => _verifyCode(provider),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                        'Vérifier le code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bouton retour
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                  _codeController.clear();
                });
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Modifier le numéro'),
            ),
          ),
          
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Informations sur les tentatives
          if (provider.verification != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Tentatives restantes: ${provider.attemptsRemaining}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    
    final provider = Provider.of<PhoneVerificationProvider>(context, listen: false);
    final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text}';
    
    final success = await provider.sendVerificationCode(fullPhoneNumber);
    
    if (success) {
      setState(() {
        _currentStep = 1;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code de vérification envoyé !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _verifyCode(PhoneVerificationProvider provider) async {
    if (_codeController.text.length != 6) return;
    
    final success = await provider.verifyCode(_codeController.text);
    
    if (success) {
      // Rafraîchir les données utilisateur
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshVerificationStatuses();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléphone vérifié avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resendCode(PhoneVerificationProvider provider) async {
    final success = await provider.resendCode();
    
    if (success) {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nouveau code envoyé !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}