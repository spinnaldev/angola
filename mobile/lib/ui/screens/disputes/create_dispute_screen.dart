// lib/ui/screens/disputes/create_dispute_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/dispute_provider.dart';
import '../../../providers/service_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../../core/models/service.dart';

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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  int? _selectedProviderId;
  int? _selectedServiceId;
  List<Service> _services = [];
  bool _loadingServices = false;

  @override
  void initState() {
    super.initState();
    _selectedProviderId = widget.providerId;
    _selectedServiceId = widget.serviceId;
    
    if (_selectedProviderId != null) {
      _loadServices();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    if (_selectedProviderId == null) return;
    
    setState(() {
      _loadingServices = true;
    });

    try {
      // Dans un cas réel, récupérer la liste des services du prestataire
      // Ici, on utilise une liste fictive pour la démonstration
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _services = [
          Service(
            id: 1,
            title: 'Plomberie',
            description: 'Services de plomberie',
            imageUrl: '',
            rating: 4.5,
            reviewCount: 15,
            providerId: _selectedProviderId!,
            businessType: 'Entreprise',
            price: 0,
            categoryId: 1,
          ),
          Service(
            id: 2,
            title: 'Électricité',
            description: 'Services d\'électricité',
            imageUrl: '',
            rating: 4.2,
            reviewCount: 12,
            providerId: _selectedProviderId!,
            businessType: 'Entreprise',
            price: 0,
            categoryId: 1,
          ),
        ];
        _loadingServices = false;
      });
    } catch (e) {
      setState(() {
        _loadingServices = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des services: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _selectProvider() async {
    // Dans un cas réel, ouvrir un écran de sélection de prestataire
    // Ici, on simule la sélection d'un prestataire
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _selectedProviderId = 1; // Prestataire fictif pour la démonstration
      _services = []; // Réinitialiser les services
      _selectedServiceId = null;
    });
    _loadServices();
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
            // Sélection du prestataire
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectProvider,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _selectedProviderId == null
                          ? 'Sélectionner un prestataire'
                          : 'Prestataire sélectionné',
                      style: TextStyle(
                        color: _selectedProviderId == null
                            ? Colors.grey[700]
                            : Theme.of(context).primaryColor,
                        fontWeight:
                            _selectedProviderId == null ? null : FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_selectedProviderId != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            // Sélection du service (si prestataire sélectionné)
            if (_selectedProviderId != null) ...[
              const Text(
                'Service concerné',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _loadingServices
                  ? const Center(child: LoadingIndicator(size: 24))
                  : _services.isEmpty
                      ? const Text('Aucun service disponible pour ce prestataire')
                      : DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
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
              const SizedBox(height: 16),
            ],
            
            // Titre du litige
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du litige',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'Description du problème',
                hintText: 'Décrivez le problème rencontré en détail',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 24),
            
            // Bouton d'envoi
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDispute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const LoadingIndicator(size: 24)
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
          ],
        ),
      ),
    );
  }
}