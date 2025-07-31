
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teyago/ui/widgets/loading_indicator.dart';
import 'dart:io';
import '../../../providers/provider_verification_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/verification/verification_status_card.dart';
import '../../widgets/verification/verification_progress_indicator.dart';
import '../../widgets/verification/file_picker_widget.dart';

class ProviderVerificationScreen extends StatefulWidget {
  const ProviderVerificationScreen({Key? key}) : super(key: key);

  @override
  State<ProviderVerificationScreen> createState() => _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState extends State<ProviderVerificationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Formulaire
  bool _isBusiness = false;
  String _documentType = 'id_card';
  final _businessNameController = TextEditingController();
  final _businessNifController = TextEditingController();
  final _businessRegistrationController = TextEditingController();
  
  // Fichiers
  File? _idCardFront;
  File? _idCardBack;
  File? _passportImage;
  File? _businessDoc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVerificationStatus();
    });
  }

  Future<void> _loadVerificationStatus() async {
    final provider = Provider.of<ProviderVerificationProvider>(context, listen: false);
    await provider.fetchVerificationStatus();
    await provider.fetchRequirements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification du profil'),
        elevation: 0,
      ),
      body: Consumer<ProviderVerificationProvider>(
        builder: (context, verificationProvider, _) {
          if (verificationProvider.isLoading && verificationProvider.verification == null) {
            return const Center(child: LoadingIndicator());
          }
          
          // Si déjà vérifié
          if (verificationProvider.isVerified) {
            return _buildVerifiedAccount();
          }
          
          // Si en attente
          if (verificationProvider.isPending) {
            return _buildPendingVerification(verificationProvider);
          }
          
          // Si rejeté
          if (verificationProvider.isRejected) {
            return _buildRejectedVerification(verificationProvider);
          }
          
          // Formulaire de vérification
          return _buildVerificationForm(verificationProvider);
        },
      ),
    );
  }

  Widget _buildVerifiedAccount() {
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
                Icons.verified_user,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Profil vérifié !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Votre profil prestataire a été vérifié avec succès. Vous pouvez maintenant profiter de toutes les fonctionnalités de la plateforme.',
              textAlign: TextAlign.center,
              style: TextStyle(
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

  Widget _buildPendingVerification(ProviderVerificationProvider provider) {
    final verification = provider.verification!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vérification en cours',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Votre demande de vérification est en cours d\'examen. Nous vous notifierons dès que le processus sera terminé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                if (verification.daysSinceSubmission != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Soumis il y a ${verification.daysSinceSubmission} jour${verification.daysSinceSubmission! > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Informations soumises
          _buildSubmittedInfo(verification),
          
          const SizedBox(height: 24),
          
          // Délai estimé
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Délai de traitement habituel : 24-48 heures ouvrées',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedVerification(ProviderVerificationProvider provider) {
    final verification = provider.verification!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cancel,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vérification rejetée',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Votre demande de vérification a été rejetée. Consultez les détails ci-dessous et soumettez de nouveaux documents.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                if (verification.rejectionReason != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Raison du rejet :',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          verification.rejectionReason!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Bouton pour soumettre de nouveaux documents
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                  // Pré-remplir avec les données existantes
                  _isBusiness = verification.isBusiness;
                  _documentType = verification.documentType;
                  if (verification.businessName != null) {
                    _businessNameController.text = verification.businessName!;
                  }
                  if (verification.businessNif != null) {
                    _businessNifController.text = verification.businessNif!;
                  }
                  if (verification.businessRegistrationNumber != null) {
                    _businessRegistrationController.text = verification.businessRegistrationNumber!;
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Soumettre de nouveaux documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm(ProviderVerificationProvider provider) {
    return Column(
      children: [
        // Indicateur de progression
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
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
                if (i < 2)
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
              _buildStep1TypeSelection(),
              _buildStep2DocumentUpload(),
              _buildStep3Review(),
            ],
          ),
        ),
        
        // Boutons de navigation
        _buildNavigationButtons(provider),
      ],
    );
  }

  Widget _buildStep1TypeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type de compte',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionnez le type de compte qui correspond à votre activité.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // Option Particulier
          GestureDetector(
            onTap: () {
              setState(() {
                _isBusiness = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: !_isBusiness ? Theme.of(context).primaryColor : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: !_isBusiness ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: !_isBusiness ? Theme.of(context).primaryColor : Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Particulier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: !_isBusiness ? Theme.of(context).primaryColor : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Je propose mes services en tant que personne physique',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isBusiness)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Option Entreprise
          GestureDetector(
            onTap: () {
              setState(() {
                _isBusiness = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isBusiness ? Theme.of(context).primaryColor : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _isBusiness ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: _isBusiness ? Theme.of(context).primaryColor : Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entreprise',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isBusiness ? Theme.of(context).primaryColor : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Je représente une entreprise ou société',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isBusiness)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
            ),
          ),
          
          if (_isBusiness) ...[
            const SizedBox(height: 24),
            const Text(
              'Informations de l\'entreprise',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nom de l'entreprise
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'entreprise *',
                border: OutlineInputBorder(),
                hintText: 'Ex: Mon Entreprise SARL',
              ),
            ),
            const SizedBox(height: 16),
            
            // NIF (optionnel)
            TextFormField(
              controller: _businessNifController,
              decoration: const InputDecoration(
                labelText: 'NIF (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Numéro d\'identification fiscale',
              ),
            ),
            const SizedBox(height: 16),
            
            // Numéro d'enregistrement
            TextFormField(
              controller: _businessRegistrationController,
              decoration: const InputDecoration(
                labelText: 'Numéro RCCM (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Numéro d\'enregistrement commercial',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2DocumentUpload() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documents d\'identité',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envoyez-nous vos documents pour vérifier votre identité.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // Sélection du type de document
          const Text(
            'Type de document',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _documentType = 'id_card';
                      _passportImage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _documentType == 'id_card' 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _documentType == 'id_card' 
                          ? Theme.of(context).primaryColor.withOpacity(0.05) 
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: _documentType == 'id_card' 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Carte d\'identité',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _documentType == 'id_card' 
                                ? Theme.of(context).primaryColor 
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _documentType = 'passport';
                      _idCardFront = null;
                      _idCardBack = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _documentType == 'passport' 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _documentType == 'passport' 
                          ? Theme.of(context).primaryColor.withOpacity(0.05) 
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.book,
                          color: _documentType == 'passport' 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Passeport',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _documentType == 'passport' 
                                ? Theme.of(context).primaryColor 
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Upload des documents selon le type
          if (_documentType == 'id_card') ...[
            FilePickerWidget(
              label: 'Carte d\'identité (recto)',
              description: 'Photo claire de la face avant de votre carte d\'identité',
              selectedFile: _idCardFront,
              onFileSelected: (file) {
                setState(() {
                  _idCardFront = file;
                });
              },
              required: true,
            ),
            const SizedBox(height: 16),
            FilePickerWidget(
              label: 'Carte d\'identité (verso)',
              description: 'Photo claire de la face arrière de votre carte d\'identité',
              selectedFile: _idCardBack,
              onFileSelected: (file) {
                setState(() {
                  _idCardBack = file;
                });
              },
              required: true,
            ),
          ] else ...[
            FilePickerWidget(
              label: 'Passeport',
              description: 'Photo claire de la page principale de votre passeport',
              selectedFile: _passportImage,
              onFileSelected: (file) {
                setState(() {
                  _passportImage = file;
                });
              },
              required: true,
            ),
          ],
          
          // Document d'entreprise si nécessaire
          if (_isBusiness) ...[
            const SizedBox(height: 24),
            FilePickerWidget(
              label: 'Document d\'entreprise (optionnel)',
              description: 'RCCM, registre de commerce ou autre document officiel',
              selectedFile: _businessDoc,
              onFileSelected: (file) {
                setState(() {
                  _businessDoc = file;
                });
              },
              allowedTypes: const ['image', 'pdf'],
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Conseils
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
                    const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Conseils pour de bonnes photos',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Prenez les photos dans un endroit bien éclairé\n'
                  '• Assurez-vous que tous les textes sont lisibles\n'
                  '• Évitez les reflets et les ombres\n'
                  '• Taille maximum : 5 MB par fichier',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vérification des informations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vérifiez vos informations avant de soumettre votre demande.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // Récapitulatif
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type de compte
                  _buildInfoRow('Type de compte', _isBusiness ? 'Entreprise' : 'Particulier'),
                  
                  if (_isBusiness) ...[
                    const Divider(),
                    _buildInfoRow('Nom de l\'entreprise', _businessNameController.text.isNotEmpty ? _businessNameController.text : 'Non renseigné'),
                    if (_businessNifController.text.isNotEmpty) ...[
                      const Divider(),
                      _buildInfoRow('NIF', _businessNifController.text),
                    ],
                    if (_businessRegistrationController.text.isNotEmpty) ...[
                      const Divider(),
                      _buildInfoRow('Numéro RCCM', _businessRegistrationController.text),
                    ],
                  ],
                  
                  const Divider(),
                  _buildInfoRow('Type de document', _documentType == 'id_card' ? 'Carte d\'identité' : 'Passeport'),
                  
                  const Divider(),
                  const Text(
                    'Documents fournis:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  
                  // Liste des documents
                  if (_documentType == 'id_card') ...[
                    _buildDocumentStatus('Carte d\'identité (recto)', _idCardFront != null),
                    _buildDocumentStatus('Carte d\'identité (verso)', _idCardBack != null),
                  ] else ...[
                    _buildDocumentStatus('Passeport', _passportImage != null),
                  ],
                  
                  if (_isBusiness && _businessDoc != null)
                    _buildDocumentStatus('Document d\'entreprise', true),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Avertissement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Important',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Assurez-vous que toutes les informations sont exactes. '
                  'Les documents fournis doivent être valides et lisibles. '
                  'Toute information erronée peut entraîner un rejet de votre demande.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatus(String document, bool provided) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            provided ? Icons.check_circle : Icons.cancel,
            color: provided ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            document,
            style: TextStyle(
              fontSize: 12,
              color: provided ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedInfo(verification) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations soumises',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildInfoRow('Type', verification.isBusiness ? 'Entreprise' : 'Particulier'),
            
            if (verification.businessName != null) ...[
              const Divider(),
              _buildInfoRow('Entreprise', verification.businessName!),
            ],
            
            const Divider(),
            _buildInfoRow('Document', verification.documentType == 'id_card' ? 'Carte d\'identité' : 'Passeport'),
            
            const Divider(),
            const Text(
              'Documents:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            
            ...verification.documentsProvided.map<Widget>((doc) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(doc, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(ProviderVerificationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Précédent'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _canProceed() 
                  ? (_currentStep < 2 ? _nextStep : () => _submitVerification(provider))
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                  : Text(_currentStep < 2 ? 'Suivant' : 'Soumettre'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        if (_isBusiness) {
          return _businessNameController.text.isNotEmpty;
        }
        return true;
      case 1:
        if (_documentType == 'id_card') {
          return _idCardFront != null && _idCardBack != null;
        } else {
          return _passportImage != null;
        }
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitVerification(ProviderVerificationProvider provider) async {
    bool success = false;
    
    if (_isBusiness) {
      success = await provider.submitBusinessVerification(
        businessName: _businessNameController.text,
        businessNif: _businessNifController.text.isNotEmpty ? _businessNifController.text : null,
        businessRegistrationNumber: _businessRegistrationController.text.isNotEmpty ? _businessRegistrationController.text : null,
        idCardFront: _idCardFront!,
        idCardBack: _idCardBack!,
        businessRegistrationDoc: _businessDoc,
      );
    } else {
      if (_documentType == 'id_card') {
        success = await provider.submitIndividualVerificationWithId(
          idCardFront: _idCardFront!,
          idCardBack: _idCardBack!,
        );
      } else {
        success = await provider.submitIndividualVerificationWithPassport(
          passportImage: _passportImage!,
        );
      }
    }
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande de vérification soumise avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erreur lors de la soumission'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _businessNifController.dispose();
    _businessRegistrationController.dispose();
    super.dispose();
  }
}