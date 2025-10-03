// mobile/lib/ui/screens/verification/client_verification_screen.dart
// VERSION TRADUITE - Utilise AppLocalizations

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/client_verification_provider.dart';
import '../../../providers/auth_provider.dart';

class ClientVerificationScreen extends StatefulWidget {
  const ClientVerificationScreen({Key? key}) : super(key: key);

  @override
  State<ClientVerificationScreen> createState() => _ClientVerificationScreenState();
}

class _ClientVerificationScreenState extends State<ClientVerificationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  String _documentType = 'id_card';
  
  File? _idCardFront;
  File? _idCardBack;
  File? _passportImage;
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVerificationStatus();
    });
  }
  
  Future<void> _loadVerificationStatus() async {
    final provider = context.read<ClientVerificationProvider>();
    await provider.fetchVerificationStatus();
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileVerification),
        elevation: 0,
      ),
      body: Consumer<ClientVerificationProvider>(
        builder: (context, verificationProvider, child) {
          if (verificationProvider.isVerified) {
            return _buildVerifiedScreen(context, l10n);
          }
          
          if (verificationProvider.isPending) {
            return _buildPendingScreen(context, l10n, verificationProvider);
          }
          
          if (verificationProvider.isRejected) {
            return _buildRejectedScreen(context, l10n, verificationProvider);
          }
          
          return _buildVerificationForm(context, l10n, verificationProvider);
        },
      ),
    );
  }
  
  Widget _buildVerifiedScreen(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, size: 100, color: Colors.green),
            SizedBox(height: 24),
            Text(
              l10n.profileVerified,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              l10n.profileVerifiedDescription,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.backToProfile),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingScreen(BuildContext context, AppLocalizations l10n, ClientVerificationProvider provider) {
    final verification = provider.verification;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_outlined, size: 100, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              l10n.verificationInProgress,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              verification?.detailedMessage ?? l10n.verificationPendingDescription,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              l10n.processingTime,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.backToProfile),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRejectedScreen(BuildContext context, AppLocalizations l10n, ClientVerificationProvider provider) {
    final verification = provider.verification;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.cancel_outlined, size: 100, color: Colors.red),
          SizedBox(height: 24),
          Text(
            l10n.verificationRejected,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          if (verification?.rejectionReason != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.rejectionReason}:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    verification!.rejectionReason!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
          Text(
            l10n.verificationRejectedDescription,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          _buildVerificationForm(context, l10n, provider),
        ],
      ),
    );
  }
  
  Widget _buildVerificationForm(BuildContext context, AppLocalizations l10n, ClientVerificationProvider provider) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            children: [
              _buildStep1DocumentTypeSelection(context, l10n),
              _buildStep2DocumentUpload(context, l10n),
              _buildStep3Review(context, l10n),
            ],
          ),
        ),
        _buildNavigationButtons(context, l10n, provider),
      ],
    );
  }
  
  Widget _buildStep1DocumentTypeSelection(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.documentType,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            l10n.documentTypeDescription ?? 'Choisissez le type de document',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          
          _buildDocumentTypeCard(
            context,
            title: l10n.idCard,
            subtitle: l10n.idCardFrontDescription ?? 'Recto et verso de votre carte d\'identité',
            icon: Icons.credit_card,
            value: 'id_card',
            isSelected: _documentType == 'id_card',
            onTap: () {
              setState(() {
                _documentType = 'id_card';
              });
            },
          ),
          
          SizedBox(height: 16),
          
          _buildDocumentTypeCard(
            context,
            title: l10n.passport,
            subtitle: l10n.passportDescription ?? 'Page principale de votre passeport',
            icon: Icons.book,
            value: 'passport',
            isSelected: _documentType == 'passport',
            onTap: () {
              setState(() {
                _documentType = 'passport';
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.blue, size: 28),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStep2DocumentUpload(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.identityDocuments,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          
          if (_documentType == 'id_card') ...[
            _buildDocumentUploadCard(
              context,
              l10n,
              title: l10n.idCardFront,
              subtitle: l10n.idCardFrontDescription,
              file: _idCardFront,
              onTap: () => _pickImage('id_card_front'),
            ),
            SizedBox(height: 16),
            
            _buildDocumentUploadCard(
              context,
              l10n,
              title: l10n.idCardBack,
              subtitle: l10n.idCardBackDescription,
              file: _idCardBack,
              onTap: () => _pickImage('id_card_back'),
            ),
          ] else ...[
            _buildDocumentUploadCard(
              context,
              l10n,
              title: l10n.passport,
              subtitle: l10n.passportDescription,
              file: _passportImage,
              onTap: () => _pickImage('passport'),
            ),
          ],
          
          SizedBox(height: 24),
          _buildPhotoTips(context, l10n),
        ],
      ),
    );
  }
  
  Widget _buildDocumentUploadCard(
    BuildContext context,
    AppLocalizations l10n, {
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: file != null ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.add_photo_alternate,
                  color: file != null ? Colors.green : Colors.grey,
                  size: 32,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (file != null) ...[
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhotoTips(BuildContext context, AppLocalizations l10n) {
    final provider = context.read<ClientVerificationProvider>();
    final tips = provider.getPhotoTips();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                l10n.photoTips,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            l10n.photoTipsContent,
            style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep3Review(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.informationReview,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            l10n.reviewDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow(l10n.documentType, _documentType == 'id_card' ? l10n.idCard : l10n.passport),
                SizedBox(height: 12),
                _buildReviewRow(l10n.documentsProvided, _getDocumentsCount()),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.important,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        l10n.importantWarning,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  String _getDocumentsCount() {
    int count = 0;
    if (_documentType == 'id_card') {
      if (_idCardFront != null) count++;
      if (_idCardBack != null) count++;
      return '$count/2 ${AppLocalizations.of(context)!.documents}';
    } else {
      if (_passportImage != null) count++;
      return '$count/1 ${AppLocalizations.of(context)!.documents}';
    }
  }
  
  Widget _buildNavigationButtons(BuildContext context, AppLocalizations l10n, ClientVerificationProvider provider) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
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
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text(l10n.previous),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () => _handleNextOrSubmit(context, l10n, provider),
              child: provider.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == 2 ? l10n.submit : l10n.next),
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleNextOrSubmit(BuildContext context, AppLocalizations l10n, ClientVerificationProvider provider) async {
    if (_currentStep < 2) {
      if (_currentStep == 1 && !_areDocumentsValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseSelectFile ?? 'Veuillez ajouter tous les documents requis'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _submitVerification(context, l10n, provider);
    }
  }
  
  bool _areDocumentsValid() {
    if (_documentType == 'id_card') {
      return _idCardFront != null && _idCardBack != null;
    } else {
      return _passportImage != null;
    }
  }
  
  Future<void> _submitVerification(BuildContext context, AppLocalizations l10n, ClientVerificationProvider provider) async {
    bool success = false;
    
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
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.verificationSubmitted ?? 'Documents soumis avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? l10n.errorOccurred ?? 'Erreur'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _pickImage(String type) async {
    final provider = context.read<ClientVerificationProvider>();
    
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.selectImageSource ?? 'Choisir une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text(l10n.camera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text(l10n.gallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    
    if (source == null) return;
    
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      
      final isValid = await provider.isFileValid(file);
      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Fichier invalide'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        if (type == 'id_card_front') {
          _idCardFront = file;
        } else if (type == 'id_card_back') {
          _idCardBack = file;
        } else if (type == 'passport') {
          _passportImage = file;
        }
      });
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}