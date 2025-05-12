// TODO Implement this library.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/provider_verification_provider.dart';
import '../../widgets/loading_indicator.dart';

class ProviderVerificationScreen extends StatefulWidget {
  const ProviderVerificationScreen({Key? key}) : super(key: key);

  @override
  _ProviderVerificationScreenState createState() =>
      _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState
    extends State<ProviderVerificationScreen> {
  bool _isBusiness = false;
  
  // Contrôleurs pour les champs de formulaire entreprise
  final _businessNameController = TextEditingController();
  final _businessNifController = TextEditingController();
  final _businessRegistrationNumberController = TextEditingController();
  
  // Fichiers pour les pièces jointes
  File? _businessRegistrationDoc;
  File? _idCardFront;
  File? _idCardBack;
  
  // Clés de formulaire pour la validation
  final _businessFormKey = GlobalKey<FormState>();
  final _individualFormKey = GlobalKey<FormState>();
  
  // État de chargement
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVerificationData();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessNifController.dispose();
    _businessRegistrationNumberController.dispose();
    super.dispose();
  }

  // Charger les données de vérification existantes, si disponibles
  Future<void> _loadVerificationData() async {
    final provider = Provider.of<ProviderVerificationProvider>(
      context,
      listen: false,
    );
    
    await provider.fetchVerificationInfo();
    
    if (provider.verification != null) {
      setState(() {
        _isBusiness = provider.verification!.isBusiness;
        
        if (_isBusiness) {
          _businessNameController.text = provider.verification!.businessName ?? '';
          _businessNifController.text = provider.verification!.businessNif ?? '';
          _businessRegistrationNumberController.text = 
              provider.verification!.businessRegistrationNumber ?? '';
        }
      });
    }
  }
  
  // Sélectionner un document depuis la galerie
  Future<File?> _pickDocument() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    
    if (image != null) {
      return File(image.path);
    }
    
    return null;
  }
  
  // Soumettre le formulaire d'entreprise
  Future<void> _submitBusinessForm() async {
    if (!_businessFormKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await Provider.of<ProviderVerificationProvider>(
        context,
        listen: false,
      ).submitBusinessVerification(
        _businessNameController.text,
        _businessNifController.text,
        _businessRegistrationNumberController.text,
        _businessRegistrationDoc,
      );
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations soumises avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<ProviderVerificationProvider>(context, listen: false)
                      .errorMessage ??
                  'Erreur lors de la soumission',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Soumettre le formulaire de particulier
  Future<void> _submitIndividualForm() async {
    if (!_individualFormKey.currentState!.validate()) {
      return;
    }
    
    if (_idCardFront == null || _idCardBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter les photos recto et verso de votre pièce d\'identité'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await Provider.of<ProviderVerificationProvider>(
        context,
        listen: false,
      ).submitIndividualVerification(
        _idCardFront!,
        _idCardBack!,
      );
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations soumises avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<ProviderVerificationProvider>(context, listen: false)
                      .errorMessage ??
                  'Erreur lors de la soumission',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification du compte'),
        elevation: 0,
      ),
      body: Consumer<ProviderVerificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !_isLoading) {
            return const Center(child: LoadingIndicator());
          }
          
          // Si le prestataire est déjà vérifié
          if (provider.isVerified) {
            return _buildVerifiedAccount();
          }
          
          // Si la vérification est en attente
          if (provider.verificationStatus == 'pending') {
            return _buildPendingVerification();
          }
          
          // Si la vérification a été rejetée
          if (provider.verificationStatus == 'rejected') {
            return _buildRejectedVerification(provider);
          }
          
          // Formulaire de vérification
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vérification du compte',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pour garantir la sécurité et la confiance sur la plateforme, nous avons besoin de vérifier votre identité.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Sélection du type de prestataire
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Type de prestataire',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RadioListTile<bool>(
                              title: const Text('Entreprise'),
                              subtitle: const Text('Pour les entreprises enregistrées'),
                              value: true,
                              groupValue: _isBusiness,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isBusiness = value ?? false;
                                });
                              },
                            ),
                            RadioListTile<bool>(
                              title: const Text('Particulier'),
                              subtitle: const Text('Pour les freelances et indépendants'),
                              value: false,
                              groupValue: _isBusiness,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isBusiness = value ?? false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Formulaire spécifique au type de prestataire
                    _isBusiness ? _buildBusinessForm() : _buildIndividualForm(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              
              // Indicateur de chargement
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: LoadingIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildBusinessForm() {
    return Form(
      key: _businessFormKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations de l\'entreprise',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'entreprise',
                  hintText: 'Entrez le nom légal de votre entreprise',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom de l\'entreprise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _businessNifController,
                decoration: const InputDecoration(
                  labelText: 'Numéro d\'identification fiscale (NIF)',
                  hintText: 'Entrez le NIF de votre entreprise',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le NIF de l\'entreprise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _businessRegistrationNumberController,
                decoration: const InputDecoration(
                  labelText: 'Numéro d\'enregistrement',
                  hintText: 'Entrez le numéro d\'enregistrement de votre entreprise',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le numéro d\'enregistrement';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Document d\'enregistrement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Veuillez fournir une copie de votre certificat d\'enregistrement ou tout autre document officiel prouvant l\'existence légale de votre entreprise.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Bouton pour sélectionner le document d'enregistrement
              InkWell(
                onTap: () async {
                  final doc = await _pickDocument();
                  if (doc != null) {
                    setState(() {
                      _businessRegistrationDoc = doc;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _businessRegistrationDoc == null
                            ? Icons.upload_file
                            : Icons.file_present,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _businessRegistrationDoc == null
                              ? 'Sélectionner un document'
                              : _businessRegistrationDoc!.path.split('/').last,
                          style: TextStyle(
                            color: _businessRegistrationDoc == null
                                ? Colors.grey[700]
                                : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_businessRegistrationDoc != null)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _businessRegistrationDoc = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitBusinessForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    'Soumettre pour vérification',
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
      ),
    );
  }
  
  Widget _buildIndividualForm() {
    return Form(
      key: _individualFormKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vérification d\'identité',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Pour compléter votre vérification en tant que particulier, nous avons besoin d\'une copie de votre pièce d\'identité (recto et verso).',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              
              // Sélection de la pièce d'identité recto
              const Text(
                'Pièce d\'identité (Recto)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              InkWell(
                onTap: () async {
                  final image = await _pickDocument();
                  if (image != null) {
                    setState(() {
                      _idCardFront = image;
                    });
                  }
                },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _idCardFront == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                color: Theme.of(context).primaryColor,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              const Text('Ajouter la photo recto'),
                            ],
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _idCardFront!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _idCardFront = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Sélection de la pièce d'identité verso
              const Text(
                'Pièce d\'identité (Verso)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              InkWell(
                onTap: () async {
                  final image = await _pickDocument();
                  if (image != null) {
                    setState(() {
                      _idCardBack = image;
                    });
                  }
                },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _idCardBack == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                color: Theme.of(context).primaryColor,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              const Text('Ajouter la photo verso'),
                            ],
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _idCardBack!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _idCardBack = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitIndividualForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    'Soumettre pour vérification',
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
            Icon(
              Icons.verified,
              size: 72,
              color: Colors.green[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'Compte vérifié',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre compte a été vérifié avec succès. Vous pouvez maintenant profiter de toutes les fonctionnalités de la plateforme.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.green[600],
              ),
              child: const Text(
                'Retour',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingVerification() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 72,
              color: Colors.amber[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'Vérification en cours',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre demande de vérification est en cours d\'examen. Nous vous notifierons dès que le processus sera terminé.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ce processus prend généralement 1 à 3 jours ouvrables.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Retour',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRejectedVerification(ProviderVerificationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 72,
              color: Colors.red[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'Vérification rejetée',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre demande de vérification a été rejetée pour la raison suivante:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.verification?.rejectionReason ?? 'Informations invalides ou incomplètes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Réinitialiser le formulaire pour permettre une nouvelle soumission
                setState(() {
                  _isBusiness = provider.verification?.isBusiness ?? false;
                  _businessRegistrationDoc = null;
                  _idCardFront = null;
                  _idCardBack = null;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Soumettre à nouveau',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}