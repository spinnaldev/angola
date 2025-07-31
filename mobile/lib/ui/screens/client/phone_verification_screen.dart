// mobile/lib/ui/screens/provider/phone_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:teyago/ui/widgets/loading_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/phone_verification_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/verification/verification_status_card.dart';
import '../../widgets/verification/countdown_timer_widget.dart';
import '../../widgets/country_picker_widget.dart';
import '../../../core/models/country.dart';
import '../../../core/data/countries_data.dart';

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
  Country _selectedCountry = CountriesData.defaultCountry; // Angola par défaut

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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white, // BACKGROUND BLANC
      appBar: AppBar(
        title: Text(l10n.phoneVerification),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Consumer<PhoneVerificationProvider>(
        builder: (context, verificationProvider, _) {
          if (verificationProvider.isLoading && verificationProvider.verification == null) {
            return const Center(child: LoadingIndicator());
          }
          
          // Si déjà vérifié
          if (verificationProvider.isVerified) {
            return _buildVerifiedPhone(l10n, verificationProvider);
          }
          
          // Processus de vérification
          return _buildVerificationProcess(l10n, verificationProvider);
        },
      ),
    );
  }

  Widget _buildVerifiedPhone(AppLocalizations l10n, PhoneVerificationProvider provider) {
    return Container(
      color: Colors.white, // BACKGROUND BLANC
      child: Center(
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
              Text(
                l10n.phoneVerified,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.codeDescription(provider.phoneNumber),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
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
                  child: Text(
                    l10n.backToProfile,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationProcess(AppLocalizations l10n, PhoneVerificationProvider provider) {
    return Container(
      color: Colors.white, // BACKGROUND BLANC
      child: Column(
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
                _buildPhoneInputStep(l10n, provider),
                _buildCodeVerificationStep(l10n, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInputStep(AppLocalizations l10n, PhoneVerificationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.yourPhoneNumber,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sendCodeDescription,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            
            // Sélection du pays
            Text(
              l10n.country,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            CountryPickerWidget(
              selectedCountry: _selectedCountry,
              onCountrySelected: (country) {
                setState(() {
                  _selectedCountry = country;
                });
              },
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
                labelText: l10n.phoneNumber,
                hintText: _getPhoneHint(),
                prefixText: '${_selectedCountry.dialCode} ',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterPhoneNumber;
                }
                if (value.length < _getMinPhoneLength()) {
                  return l10n.phoneNumberTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Bouton d'envoi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : () => _sendCode(l10n),
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
                    : Text(
                        l10n.sendCode,
                        style: const TextStyle(
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
                      Text(
                        l10n.whyVerifyPhone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.phoneVerificationBenefits.replaceAll('\\n', '\n'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeVerificationStep(AppLocalizations l10n, PhoneVerificationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.enterVerificationCode,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.codeDescription(provider.phoneNumber),
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
            decoration: InputDecoration(
              labelText: l10n.verificationCode,
              hintText: '000000',
              border: const OutlineInputBorder(),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
            ),
            maxLength: 6,
            onChanged: (value) {
              if (value.length == 6) {
                _verifyCode(l10n, provider);
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
              onResendPressed: () => _resendCode(l10n, provider),
            ),
          ),
          const SizedBox(height: 24),
          
          // Bouton de vérification
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.isLoading || _codeController.text.length != 6 
                  ? null 
                  : () => _verifyCode(l10n, provider),
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
                  : Text(
                        l10n.verifyCode,
                        style: const TextStyle(
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
              child: Text(l10n.changeNumber),
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
                    l10n.attemptsRemaining(provider.attemptsRemaining),
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

  Future<void> _sendCode(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    
    final provider = Provider.of<PhoneVerificationProvider>(context, listen: false);
    final fullPhoneNumber = '${_selectedCountry.dialCode}${_phoneController.text}';
    
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
        SnackBar(
          content: Text(l10n.codeSent),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Obtient l'exemple de numéro selon le pays
  String _getPhoneHint() {
    switch (_selectedCountry.code) {
      case 'AO': // Angola
        return '912345678';
      case 'BJ': // Bénin
        return '61234567';
      case 'BF': // Burkina Faso
        return '70123456';
      case 'CM': // Cameroun
        return '671234567';
      case 'CI': // Côte d'Ivoire
        return '07123456';
      case 'GA': // Gabon
        return '06123456';
      case 'GH': // Ghana
        return '201234567';
      case 'GN': // Guinée
        return '601234567';
      case 'ML': // Mali
        return '71234567';
      case 'NE': // Niger
        return '91234567';
      case 'NG': // Nigéria
        return '8012345678';
      case 'SN': // Sénégal
        return '771234567';
      case 'TG': // Togo
        return '90123456';
      case 'FR': // France
        return '612345678';
      case 'PT': // Portugal
        return '912345678';
      case 'US': // États-Unis
      case 'CA': // Canada
        return '2025551234';
      case 'BR': // Brésil
        return '11987654321';
      default:
        return '123456789';
    }
  }

  /// Obtient la longueur minimale selon le pays
  int _getMinPhoneLength() {
    switch (_selectedCountry.code) {
      case 'AO': return 9; // Angola
      case 'BJ': return 8; // Bénin
      case 'BF': return 8; // Burkina Faso
      case 'CM': return 9; // Cameroun
      case 'CI': return 8; // Côte d'Ivoire
      case 'GA': return 8; // Gabon
      case 'GH': return 9; // Ghana
      case 'GN': return 9; // Guinée
      case 'ML': return 8; // Mali
      case 'NE': return 8; // Niger
      case 'NG': return 10; // Nigéria
      case 'SN': return 9; // Sénégal
      case 'TG': return 8; // Togo
      case 'FR': return 9; // France
      case 'PT': return 9; // Portugal
      case 'US': 
      case 'CA': return 10; // États-Unis/Canada
      case 'BR': return 10; // Brésil (minimum)
      default: return 7; // Par défaut
    }
  }

  Future<void> _verifyCode(AppLocalizations l10n, PhoneVerificationProvider provider) async {
    if (_codeController.text.length != 6) return;
    
    final success = await provider.verifyCode(_codeController.text);
    
    if (success) {
      // Rafraîchir les données utilisateur
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshVerificationStatuses();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.verificationSuccess),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resendCode(AppLocalizations l10n, PhoneVerificationProvider provider) async {
    final success = await provider.resendCode();
    
    if (success) {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.newCodeSent),
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