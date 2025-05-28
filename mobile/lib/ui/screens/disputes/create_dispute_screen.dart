// lib/ui/screens/disputes/create_dispute_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/dispute_provider.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/provider_list_provider.dart';
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
  bool _isSubmitting = false;
  int? _selectedProviderId;
  int? _selectedServiceId;
  List<Service> _services = [];
  List<ProviderModel> _providers = [];
  bool _loadingServices = false;
  bool _loadingProviders = false;

  // Liste des raisons courantes pour un litige
  final List<String> _commonReasons = [
    'Service non conforme à la description',
    'Retard important dans l\'exécution',
    'Travail de mauvaise qualité',
    'Facturation incorrecte ou injustifiée',
    'Comportement impoli ou non professionnel',
    'Non-respect des conditions convenues',
    'Autre problème',
  ];

  String? _selectedReason;

  @override
  void initState() {
    super.initState();
    // First load providers
    _loadProviders().then((_) {
      // After providers are loaded, set selected provider if valid
      if (widget.providerId != null && 
          _providers.any((p) => p.id == widget.providerId)) {
        setState(() {
          _selectedProviderId = widget.providerId;
        });
        // Then load services for this provider
        _loadServices().then((_) {
          // Only set selected service if it exists in loaded services
          if (widget.serviceId != null &&
              _services.any((s) => s.id == widget.serviceId)) {
            setState(() {
              _selectedServiceId = widget.serviceId;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  // Charger la liste des prestataires depuis l'API
  Future<void> _loadProviders() async {
    setState(() {
      _loadingProviders = true;
    });
    
    try {
      final providerListProvider = Provider.of<ProviderListProvider>(
        context, 
        listen: false
      );
      
      await providerListProvider.fetchProviders();
      
      setState(() {
        _providers = providerListProvider.providers;
        _loadingProviders = false;
      });
    } catch (e) {
      setState(() {
        _loadingProviders = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des prestataires: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Charger les services d'un prestataire depuis l'API
  Future<void> _loadServices() async {
    if (_selectedProviderId == null) return;
    
    setState(() {
      _loadingServices = true;
    });

    try {
      final serviceProvider = Provider.of<ServiceProvider>(
        context, 
        listen: false
      );
      
      await serviceProvider.fetchProviderServices(_selectedProviderId!);
      
      setState(() {
        _services = serviceProvider.services;
        _loadingServices = false;
      });
    } catch (e) {
      setState(() {
        _loadingServices = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des services: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate() || _selectedProviderId == null) {
      if (_selectedProviderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un prestataire'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final disputeProvider = Provider.of<DisputeProvider>(context, listen: false);
      final success = await disputeProvider.createDispute(
        _selectedProviderId!,
        _titleController.text,
        _descriptionController.text,
        serviceId: _selectedServiceId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Litige créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(disputeProvider.errorMessage ?? 'Erreur lors de la création du litige'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _selectProvider(int providerId) {
    setState(() {
      _selectedProviderId = providerId;
      _services = []; // Réinitialiser les services
      _selectedServiceId = null;
    });
    _loadServices();
  }

  void _selectReason(String? reason) {
    setState(() {
      _selectedReason = reason;
      if (reason != null && reason != 'Autre problème') {
        _titleController.text = reason;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un litige'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Information générale
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Qu\'est-ce qu\'un litige?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Un litige est un désaccord entre vous et un prestataire concernant un service. Nous sommes là pour vous aider à résoudre ce problème de manière équitable.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Sélection du prestataire
            Card(
              elevation: 2,
              color: Colors.white, // Couleur de carte blanche
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Étape 1: Sélectionner un prestataire',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_loadingProviders)
                      const Center(child: CircularProgressIndicator())
                    else if (_providers.isEmpty)
                      const Text('Aucun prestataire disponible')
                    else
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('Sélectionnez un prestataire'),
                        isExpanded: true,
                        value: _selectedProviderId,
                        items: _providers.map((provider) {
                          return DropdownMenuItem<int>(
                            value: provider.id,
                            child: Text(provider.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _selectProvider(value);
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner un prestataire';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Sélection du service (si prestataire sélectionné)
            if (_selectedProviderId != null)
              Card(
                elevation: 2,
                color: Colors.white, // Couleur de carte blanche
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Étape 2: Sélectionner un service (optionnel)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _loadingServices
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : _services.isEmpty
                              ? const Text('Aucun service disponible pour ce prestataire')
                              : DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  hint: const Text('Sélectionnez un service (optionnel)'),
                                  isExpanded: true,
                                  value: _selectedServiceId,
                                  items: _services.map((service) {
                                    return DropdownMenuItem<int>(
                                      value: service.id,
                                      child: Text(service.title),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedServiceId = value;
                                    });
                                  },
                                ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Sélection de la raison courante
            Card(
              elevation: 2,
              color: Colors.white, // Couleur de carte blanche
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Étape 3: Type de problème',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      hint: const Text('Sélectionnez la raison principale'),
                      isExpanded: true,
                      value: _selectedReason,
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
            ),
            const SizedBox(height: 16),
            
            // Détails du litige
            Card(
              elevation: 2,
              color: Colors.white, // Couleur de carte blanche
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Étape 4: Détails du litige',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Titre du litige
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre du litige',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un titre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description du litige
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description du problème',
                        hintText: 'Décrivez le problème rencontré en détail',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        if (value.length < 20) {
                          return 'La description doit comporter au moins 20 caractères';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Bouton d'envoi
            SizedBox(
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
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Soumettre le litige',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: Vous pourrez ajouter des preuves (images, documents) après la création du litige.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}