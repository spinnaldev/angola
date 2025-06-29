// lib/ui/screens/disputes/create_dispute_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/dispute_provider.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/provider_list_provider.dart';
import '../../../core/services/profile_manager.dart';
import '../../widgets/loading_indicator.dart';
import '../../../core/models/service.dart';
import '../../../core/models/provider_model.dart';

class CreateDisputeScreen extends StatefulWidget {
  final int? providerId;
  final int? serviceId;

  const CreateDisputeScreen({
    Key? key,
    this.providerId,
    this.serviceId,
  }) : super(key: key);

  @override
  _CreateDisputeScreenState createState() => _CreateDisputeScreenState();
}

class _CreateDisputeScreenState extends State<CreateDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs de texte
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientInfoController = TextEditingController(); // Pour les prestataires
  
  bool _isSubmitting = false;
  int? _selectedProviderId;
  int? _selectedServiceId;
  List<Service> _services = [];
  List<ProviderModel> _providers = [];
  bool _loadingServices = false;
  bool _loadingProviders = false;

  // Liste des raisons courantes selon le profil
  List<String> get _commonReasons {
    if (ProfileManager.isProviderMode()) {
      return [
        'Client ne répond pas aux messages',
        'Paiement en retard ou refusé',
        'Demandes excessives hors contrat',
        'Comportement irrespectueux',
        'Annulation abusive du contrat',
        'Fausses accusations',
        'Autre problème avec le client',
      ];
    } else {
      return [
        'Service non conforme à la description',
        'Retard important dans l\'exécution',
        'Travail de mauvaise qualité',
        'Facturation incorrecte ou injustifiée',
        'Comportement impoli ou non professionnel',
        'Non-respect des conditions convenues',
        'Prestataire injoignable',
        'Autre problème',
      ];
    }
  }

  String? _selectedReason;

  @override
  void initState() {
    super.initState();
    _selectedProviderId = widget.providerId;
    _selectedServiceId = widget.serviceId;
    
    if (ProfileManager.isClientMode()) {
      _loadProviders();
      if (_selectedProviderId != null) {
        _loadServicesForProvider(_selectedProviderId!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _clientInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _loadingProviders = true;
    });
    
    try {
      await Provider.of<ProviderListProvider>(context, listen: false).fetchProviders();
      final providerListProvider = Provider.of<ProviderListProvider>(context, listen: false);
      setState(() {
        _providers = providerListProvider.providers;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des prestataires: $e')),
        );
      }
    } finally {
      setState(() {
        _loadingProviders = false;
      });
    }
  }

  Future<void> _loadServicesForProvider(int providerId) async {
    setState(() {
      _loadingServices = true;
      _selectedServiceId = null;
      _services = [];
    });
    
    try {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      await serviceProvider.fetchProviderServices(providerId);
      setState(() {
        _services = serviceProvider.services; // Changé de providerServices vers services
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des services: $e')),
        );
      }
    } finally {
      setState(() {
        _loadingServices = false;
      });
    }
  }

  void _selectReason(String? reason) {
    setState(() {
      _selectedReason = reason;
      if (reason != null && reason != 'Autre problème' && reason != 'Autre problème avec le client') {
        _titleController.text = reason;
      } else {
        _titleController.clear();
      }
    });
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validation supplémentaire selon le profil
    if (ProfileManager.isClientMode() && _selectedProviderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un prestataire')),
      );
      return;
    }
    
    if (ProfileManager.isProviderMode() && _clientInfoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner les informations du client')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final disputeProvider = Provider.of<DisputeProvider>(context, listen: false);
      
      bool success;
      if (ProfileManager.isClientMode()) {
        success = await disputeProvider.createDispute(
          _selectedProviderId!, // Gestion du null avec !
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          serviceId: _selectedServiceId,
        );
      } else {
        // Pour les prestataires, utiliser la méthode createDispute avec des paramètres adaptés
        // Comme createProviderComplaint n'existe pas, on utilise createDispute avec des valeurs spéciales
        success = await disputeProvider.createDispute(
          0, // ID spécial pour les réclamations de prestataires
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          serviceId: null,
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ProfileManager.isProviderMode() 
              ? 'Réclamation créée avec succès' 
              : 'Litige créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(disputeProvider.errorMessage ?? 'Erreur lors de la création'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ProfileManager.isProviderMode() 
          ? 'Créer une réclamation' 
          : 'Signaler un problème'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête explicatif
              _buildHeaderCard(),
              
              const SizedBox(height: 16),
              
              // Sélection selon le profil
              if (ProfileManager.isClientMode()) ...[
                _buildProviderSelection(),
                const SizedBox(height: 16),
                if (_selectedProviderId != null) ...[
                  _buildServiceSelection(),
                  const SizedBox(height: 16),
                ],
              ] else ...[
                _buildClientInfoSection(),
                const SizedBox(height: 16),
              ],
              
              // Sélection de la raison
              _buildReasonSelection(),
              
              const SizedBox(height: 16),
              
              // Détails du litige/réclamation
              _buildDisputeForm(),
              
              const SizedBox(height: 24),
              
              // Bouton de soumission
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ProfileManager.isProviderMode() ? Icons.report_outlined : Icons.gavel,
                  color: Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  ProfileManager.isProviderMode() 
                    ? 'Réclamation contre un client'
                    : 'Signalement d\'un problème',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ProfileManager.isProviderMode()
                ? 'Utilisez ce formulaire pour signaler un problème avec un client. Notre équipe examinera votre réclamation.'
                : 'Signalez un problème avec un prestataire. Notre équipe de modération examinera votre demande.',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelection() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Étape 1: Sélectionner le prestataire concerné',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_loadingProviders)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<int>(
                value: _selectedProviderId,
                decoration: InputDecoration(
                  labelText: 'Prestataire concerné',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person_search),
                ),
                items: _providers.map((provider) {
                  return DropdownMenuItem<int>(
                    value: provider.id,
                    child: Text(provider.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProviderId = value;
                    _selectedServiceId = null;
                  });
                  if (value != null) {
                    _loadServicesForProvider(value);
                  }
                },
                validator: (value) => value == null ? 'Veuillez sélectionner un prestataire' : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Étape 2: Service concerné (optionnel)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_loadingServices)
              const Center(child: CircularProgressIndicator())
            else if (_services.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Aucun service trouvé pour ce prestataire',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedServiceId,
                decoration: InputDecoration(
                  labelText: 'Service concerné (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.work_outline),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Aucun service spécifique'),
                  ),
                  ..._services.map((service) {
                    return DropdownMenuItem<int>(
                      value: service.id,
                      child: Text(service.title),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedServiceId = value;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoSection() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Étape 1: Informations sur le client',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientInfoController,
              decoration: InputDecoration(
                labelText: 'Nom du client ou email',
                hintText: 'Ex: Jean Dupont ou jean.dupont@email.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Veuillez renseigner les informations du client';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSelection() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ProfileManager.isProviderMode() 
                ? 'Étape 2: Nature de la réclamation'
                : 'Étape 3: Nature du problème',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                labelText: 'Sélectionner la raison',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.list),
              ),
              items: _commonReasons.map((reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: _selectReason,
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner une raison';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeForm() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ProfileManager.isProviderMode() 
                ? 'Étape 3: Détails de la réclamation'
                : 'Étape 4: Détails du litige',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: ProfileManager.isProviderMode() 
                  ? 'Titre de la réclamation'
                  : 'Titre du litige',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              maxLength: 100,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Veuillez saisir un titre';
                }
                if (value!.length < 10) {
                  return 'Le titre doit contenir au moins 10 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description détaillée',
                hintText: ProfileManager.isProviderMode()
                  ? 'Décrivez le comportement problématique du client...'
                  : 'Décrivez le problème rencontré avec le prestataire...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 1000,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Veuillez décrire le problème';
                }
                if (value!.length < 20) {
                  return 'La description doit contenir au moins 20 caractères';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitDispute,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Création en cours...'),
                ],
              )
            : Text(
                ProfileManager.isProviderMode() 
                  ? 'Créer la réclamation'
                  : 'Créer le litige',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}