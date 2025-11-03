
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teyago/ui/widgets/loading_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  //Variable pour forcer l'affichage du formulaire
  bool _forceShowForm = false;
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white, // BACKGROUND BLANC
      appBar: AppBar(
        title: Text(l10n.profileVerification),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Consumer<ProviderVerificationProvider>(
        builder: (context, verificationProvider, _) {
          if (verificationProvider.isLoading && verificationProvider.verification == null) {
            return const Center(child: LoadingIndicator());
          }
          
          // Si déjà vérifié
          if (verificationProvider.isVerified) {
            return _buildVerifiedAccount(l10n);
          }
          
          // Si en attente
          if (verificationProvider.isPending) {
            return _buildPendingVerification(l10n, verificationProvider);
          }
          
          // Si rejeté
          if (verificationProvider.isRejected && !_forceShowForm) {
            return _buildRejectedVerification(l10n, verificationProvider);
          }
          
          // Formulaire de vérification
          return _buildVerificationForm(l10n, verificationProvider);
        },
      ),
    );
  }

  Widget _buildVerifiedAccount(AppLocalizations l10n) {
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
                  Icons.verified_user,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.profileVerified,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.profileVerifiedDescription,
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

  Widget _buildPendingVerification(AppLocalizations l10n, ProviderVerificationProvider provider) {
    final verification = provider.verification!;
    
    return Container(
      color: Colors.white, // BACKGROUND BLANC
      child: SingleChildScrollView(
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
                  Text(
                    l10n.verificationInProgress,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.verificationPendingDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                        l10n.submittedDaysAgo(verification.daysSinceSubmission!),
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
            _buildSubmittedInfo(l10n, verification),
            
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
                  Expanded(
                    child: Text(
                      l10n.processingTime,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedVerification(AppLocalizations l10n, ProviderVerificationProvider provider) {
    final verification = provider.verification!;
    
    return Container(
      color: Colors.white, // BACKGROUND BLANC
      child: SingleChildScrollView(
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
                  Text(
                    l10n.verificationRejected,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.verificationRejectedDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                          Text(
                            l10n.rejectionReason,
                            style: const TextStyle(
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
                    // Forcer l'affichage du formulaire
                    _forceShowForm = true;
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
                    
                    // Réinitialiser les fichiers pour nouvelle soumission
                    _idCardFront = null;
                    _idCardBack = null;
                    _passportImage = null;
                    _businessDoc = null;
                  });
                  
                  // ✅ Plus besoin de PageController ici - le setState() va reconstruire
                  // et afficher automatiquement le formulaire à l'étape 0
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.submitNewDocuments,
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
    );
  }

  Widget _buildVerificationForm(AppLocalizations l10n, ProviderVerificationProvider provider) {
    return Container(
      color: Colors.white, // BACKGROUND BLANC
      child: Column(
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
                _buildStep1TypeSelection(l10n),
                _buildStep2DocumentUpload(l10n),
                _buildStep3Review(l10n),
              ],
            ),
          ),
          
          // Boutons de navigation
          _buildNavigationButtons(l10n, provider),
        ],
      ),
    );
  }

  Widget _buildStep1TypeSelection(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.accountType,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.selectAccountTypeDescription,
            style: const TextStyle(
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
                color: !_isBusiness ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.white,
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
                          l10n.individual,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: !_isBusiness ? Theme.of(context).primaryColor : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.individualDescription,
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
                color: _isBusiness ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.white,
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
                          l10n.business,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isBusiness ? Theme.of(context).primaryColor : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.businessDescription,
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
            Text(
              l10n.businessInformation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nom de l'entreprise
            TextFormField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: l10n.businessNameRequired,
                border: const OutlineInputBorder(),
                hintText: l10n.businessNameHint,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // NIF (optionnel)
            TextFormField(
              controller: _businessNifController,
              decoration: InputDecoration(
                labelText: l10n.nifOptional,
                border: const OutlineInputBorder(),
                hintText: l10n.nifHint,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Numéro d'enregistrement
            TextFormField(
              controller: _businessRegistrationController,
              decoration: InputDecoration(
                labelText: l10n.rccmOptional,
                border: const OutlineInputBorder(),
                hintText: l10n.rccmHint,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2DocumentUpload(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.identityDocuments,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sendDocumentsDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // Sélection du type de document
          Text(
            l10n.documentType,
            style: const TextStyle(
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
                          : Colors.white,
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
                          l10n.idCard,
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
                          : Colors.white,
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
                          l10n.passport,
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
              label: l10n.idCardFront,
              description: l10n.idCardFrontDescription,
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
              label: l10n.idCardBack,
              description: l10n.idCardBackDescription,
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
              label: l10n.passport,
              description: l10n.passportDescription,
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
              label: l10n.businessDocumentOptional,
              description: l10n.businessDocumentDescription,
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
                    Text(
                      l10n.photoTips,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.photoTipsContent.replaceAll('\\n', '\n'),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Review(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.informationReview,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.reviewDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // Récapitulatif
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type de compte
                  _buildInfoRow(l10n.accountType, _isBusiness ? l10n.business : l10n.individual),
                  
                  if (_isBusiness) ...[
                    const Divider(),
                    _buildInfoRow(l10n.businessName, _businessNameController.text.isNotEmpty ? _businessNameController.text : l10n.notProvided),
                    if (_businessNifController.text.isNotEmpty) ...[
                      const Divider(),
                      _buildInfoRow('NIF', _businessNifController.text),
                    ],
                    if (_businessRegistrationController.text.isNotEmpty) ...[
                      const Divider(),
                      _buildInfoRow('RCCM', _businessRegistrationController.text),
                    ],
                  ],
                  
                  const Divider(),
                  _buildInfoRow(l10n.documentType, _documentType == 'id_card' ? l10n.idCard : l10n.passport),
                  
                  const Divider(),
                  Text(
                    l10n.documentsProvided,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  
                  // Liste des documents
                  if (_documentType == 'id_card') ...[
                    _buildDocumentStatus(l10n.idCardFront, _idCardFront != null),
                    _buildDocumentStatus(l10n.idCardBack, _idCardBack != null),
                  ] else ...[
                    _buildDocumentStatus(l10n.passport, _passportImage != null),
                  ],
                  
                  if (_isBusiness && _businessDoc != null)
                    _buildDocumentStatus(l10n.businessDocumentOptional, true),
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
                    Text(
                      l10n.important,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.importantWarning,
                  style: const TextStyle(fontSize: 12),
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

  Widget _buildSubmittedInfo(AppLocalizations l10n, verification) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.submittedInformation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildInfoRow(l10n.accountType, verification.isBusiness ? l10n.business : l10n.individual),
            
            if (verification.businessName != null) ...[
              const Divider(),
              _buildInfoRow(l10n.businessName, verification.businessName!),
            ],
            
            const Divider(),
            _buildInfoRow(l10n.documentType, verification.documentType == 'id_card' ? l10n.idCard : l10n.passport),
            
            const Divider(),
            Text(
              '${l10n.documents}:',
              style: const TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildNavigationButtons(AppLocalizations l10n, ProviderVerificationProvider provider) {
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
                child: Text(l10n.previous),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _canProceed() 
                  ? (_currentStep < 2 ? _nextStep : () => _submitVerification(l10n, provider))
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
                  : Text(_currentStep < 2 ? l10n.next : l10n.submit),
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

  Future<void> _submitVerification(AppLocalizations l10n, ProviderVerificationProvider provider) async {
    bool success = false;
    
    if (_forceShowForm && provider.verification != null) {
      success = await provider.resendDocuments(
        idCardFront: _idCardFront,
        idCardBack: _idCardBack,
        passportImage: _passportImage,
        businessRegistrationDoc: _businessDoc,
        businessName: _isBusiness ? _businessNameController.text : null,
        businessNif: _isBusiness && _businessNifController.text.isNotEmpty ? _businessNifController.text : null,
        businessRegistrationNumber: _isBusiness && _businessRegistrationController.text.isNotEmpty ? _businessRegistrationController.text : null,
      );
    } else {
      // ✅ Logique existante pour nouvelle soumission
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
    }
    
    if (success) {
      _forceShowForm = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.verificationSubmitted),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? l10n.submissionError),
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