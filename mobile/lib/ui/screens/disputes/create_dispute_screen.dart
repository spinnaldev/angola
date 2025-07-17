// lib/ui/screens/disputes/create_dispute_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ AJOUT
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

  String? _selectedReason;

  // ✅ Liste des raisons courantes selon le profil avec traduction
  List<String> _getCommonReasons(AppLocalizations l10n) {
    if (ProfileManager.isProviderMode()) {
      return [
        l10n.clientNotResponding,
        l10n.lateOrRefusedPayment,
        l10n.excessiveDemands,
        l10n.disrespectfulBehavior,
        l10n.abusiveContractCancellation,
        l10n.falseAccusations,
        l10n.otherClientProblem,
      ];
    } else {
      return [
        l10n.serviceNotAsDescribed,
        l10n.significantDelay,
        l10n.poorQualityWork,
        l10n.incorrectBilling,
        l10n.unprofessionalBehavior,
        l10n.conditionsNotRespected,
        l10n.providerUnreachable,
        l10n.otherProblem,
      ];
    }
  }

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
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT
    
    setState(() {
      _loadingProviders = true;
    });
    
    try {
      print('🔄 Chargement des prestataires...');
      
      await Provider.of<ProviderListProvider>(context, listen: false).fetchProviders();
      final providerListProvider = Provider.of<ProviderListProvider>(context, listen: false);
      
      if (providerListProvider.hasError) {
        throw Exception(providerListProvider.errorMessage);
      }
      
      final loadedProviders = providerListProvider.providers;
      print('📋 Providers chargés: ${loadedProviders.length}');
      
      // ✅ Filtrer les providers valides et supprimer les doublons
      final validProviders = <ProviderModel>[];
      final seenIds = <int>{};
      
      for (final provider in loadedProviders) {
        if (provider.id > 0 && 
            provider.name.isNotEmpty && 
            !seenIds.contains(provider.id)) {
          validProviders.add(provider);
          seenIds.add(provider.id);
        } else {
          print('⚠️ Provider invalide ignoré: ID=${provider.id}, Name="${provider.name}"');
        }
      }
      
      setState(() {
        _providers = validProviders;
      });
      
      print('✅ Providers valides: ${_providers.length}');
      
    } catch (e) {
      print('❌ Erreur lors du chargement des prestataires: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error} ${e.toString()}'), // ✅ TRADUIT
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _loadingProviders = false;
      });
    }
  }

  Future<void> _loadServicesForProvider(int providerId) async {
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT
    
    setState(() {
      _loadingServices = true;
      _selectedServiceId = null;
      _services = [];
    });
    
    try {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      await serviceProvider.fetchProviderServices(providerId);
      
      final loadedServices = serviceProvider.services;
      
      // ✅ DEBUG: Vérifier les doublons
      print('🔍 Services chargés: ${loadedServices.length}');
      final serviceIds = loadedServices.map((s) => s.id).toList();
      final uniqueIds = serviceIds.toSet().toList();
      
      if (serviceIds.length != uniqueIds.length) {
        print('⚠️ ATTENTION: Doublons détectés dans les services!');
        print('IDs: $serviceIds');
        print('IDs uniques: $uniqueIds');
        
        // Supprimer les doublons
        final uniqueServices = <Service>[];
        final seenIds = <int>{};
        
        for (final service in loadedServices) {
          if (service.id != null && !seenIds.contains(service.id)) {
            uniqueServices.add(service);
            seenIds.add(service.id!);
          }
        }
        
        setState(() {
          _services = uniqueServices;
        });
        print('✅ Services après suppression des doublons: ${_services.length}');
      } else {
        setState(() {
          _services = loadedServices;
        });
      }
      
    } catch (e) {
      print('❌ Erreur lors du chargement des services: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorLoadingServices} $e')), // ✅ TRADUIT
        );
      }
    } finally {
      setState(() {
        _loadingServices = false;
      });
    }
  }

  void _selectReason(String? reason) {
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT
    
    setState(() {
      _selectedReason = reason;
      if (reason != null && 
          reason != l10n.otherProblem && 
          reason != l10n.otherClientProblem) { // ✅ TRADUIT
        _titleController.text = reason;
      } else {
        _titleController.clear();
      }
    });
  }

  Future<void> _submitDispute() async {
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT
    
    if (!_formKey.currentState!.validate()) return;
    
    // Validation supplémentaire selon le profil
    if (ProfileManager.isClientMode() && _selectedProviderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectProvider)), // ✅ TRADUIT
      );
      return;
    }
    
    if (ProfileManager.isProviderMode() && _clientInfoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseProvideClientInfo)), // ✅ TRADUIT
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
              ? l10n.complaintCreatedSuccessfully // ✅ TRADUIT
              : l10n.disputeCreatedSuccessfully), // ✅ TRADUIT
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(disputeProvider.errorMessage ?? l10n.errorCreating), // ✅ TRADUIT
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error} $e'), // ✅ TRADUIT
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
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT
    
    return Scaffold(
      appBar: AppBar(
        title: Text(ProfileManager.isProviderMode() 
          ? l10n.createComplaint // ✅ TRADUIT
          : l10n.reportProblem), // ✅ TRADUIT
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
              _buildHeaderCard(l10n), // ✅ PASSER l10n
              
              const SizedBox(height: 16),
              
              // Sélection selon le profil
              if (ProfileManager.isClientMode()) ...[
                _buildProviderSelection(l10n), // ✅ PASSER l10n
                const SizedBox(height: 16),
                if (_selectedProviderId != null) ...[
                  _buildServiceSelection(l10n), // ✅ PASSER l10n
                  const SizedBox(height: 16),
                ],
              ] else ...[
                _buildClientInfoSection(l10n), // ✅ PASSER l10n
                const SizedBox(height: 16),
              ],
              
              // Sélection de la raison
              _buildReasonSelection(l10n), // ✅ PASSER l10n
              
              const SizedBox(height: 16),
              
              // Détails du litige/réclamation
              _buildDisputeForm(l10n), // ✅ PASSER l10n
              
              const SizedBox(height: 24),
              
              // Bouton de soumission
              _buildSubmitButton(l10n), // ✅ PASSER l10n
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
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
                Expanded( // ✅ AJOUT pour éviter overflow
                  child: Text(
                    ProfileManager.isProviderMode() 
                      ? l10n.complaintAgainstClient // ✅ TRADUIT
                      : l10n.reportProblemTitle, // ✅ TRADUIT
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ProfileManager.isProviderMode()
                ? l10n.complaintDescription // ✅ TRADUIT
                : l10n.reportProblemDescription, // ✅ TRADUIT
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

  Widget _buildProviderSelection(AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
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
              l10n.step1SelectProvider, // ✅ TRADUIT
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_loadingProviders)
              const Center(child: CircularProgressIndicator())
            else if (_providers.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.noProvidersAvailable, // ✅ TRADUIT
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedProviderId,
                decoration: InputDecoration(
                  labelText: l10n.concernedProvider, // ✅ TRADUIT
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person_search),
                ),
                items: _buildProviderDropdownItems(),
                onChanged: (value) {
                  setState(() {
                    _selectedProviderId = value;
                    _selectedServiceId = null;
                  });
                  if (value != null) {
                    _loadServicesForProvider(value);
                  }
                },
                validator: (value) => value == null 
                    ? l10n.pleaseSelectProvider // ✅ TRADUIT
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> _buildProviderDropdownItems() {
    final items = <DropdownMenuItem<int>>[];
    final seenIds = <int>{};
    
    for (final provider in _providers) {
      // Vérifier que l'ID n'est pas déjà vu et n'est pas null
      if (provider.id > 0 && !seenIds.contains(provider.id)) {
        items.add(
          DropdownMenuItem<int>(
            value: provider.id,
            child: Text(
              provider.name.isNotEmpty ? provider.name : 'Prestataire #${provider.id}',
              overflow: TextOverflow.ellipsis, // ✅ Évite le débordement
            ),
          ),
        );
        seenIds.add(provider.id);
      }
    }
    
    print('🔧 Items provider dropdown créés: ${items.length}');
    return items;
  }

  Widget _buildServiceSelection(AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
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
              l10n.step2SelectService, // ✅ TRADUIT
              style: const TextStyle(
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
                child: Text(
                  l10n.noServicesFoundForProvider, // ✅ TRADUIT
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else
              DropdownButtonFormField<int?>(
                value: _selectedServiceId,
                decoration: InputDecoration(
                  labelText: l10n.concernedServiceOptional, // ✅ TRADUIT
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.work_outline),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.noSpecificService), // ✅ TRADUIT
                  ),
                  ..._services.where((service) => service.id != null).map((service) {
                    return DropdownMenuItem<int?>(
                      value: service.id,
                      child: Text(
                        service.title,
                        overflow: TextOverflow.ellipsis, // ✅ Évite le débordement
                      ),
                    );
                  }).toSet().toList(),
                ],
                onChanged: (int? value) {
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

  Widget _buildClientInfoSection(AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
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
              l10n.step1ClientInfo, // ✅ TRADUIT
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientInfoController,
              decoration: InputDecoration(
                labelText: l10n.clientNameOrEmail, // ✅ TRADUIT
                hintText: l10n.clientNameOrEmailHint, // ✅ TRADUIT
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return l10n.pleaseProvideClientInfo; // ✅ TRADUIT
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSelection(AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
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
                ? l10n.step2ComplaintNature // ✅ TRADUIT
                : l10n.step3ProblemNature, // ✅ TRADUIT
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                labelText: l10n.selectReason, // ✅ TRADUIT
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.list),
              ),
              items: _getCommonReasons(l10n).map((reason) { // ✅ UTILISER MÉTHODE TRADUITE
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(
                    reason,
                    overflow: TextOverflow.ellipsis, // ✅ Évite le débordement
                  ),
                );
              }).toList(),
              onChanged: _selectReason,
              validator: (value) {
                if (value == null) {
                  return l10n.pleaseSelectReason; // ✅ TRADUIT
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeForm(AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
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
                ? l10n.step3ComplaintDetails // ✅ TRADUIT
                : l10n.step4DisputeDetails, // ✅ TRADUIT
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
                  ? l10n.complaintTitle // ✅ TRADUIT
                  : l10n.disputeTitle, // ✅ TRADUIT
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              maxLength: 100,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return l10n.pleaseEnterTitle; // ✅ TRADUIT
                }
                if (value!.length < 10) {
                  return l10n.titleMinLength; // ✅ TRADUIT
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.detailedDescription, // ✅ TRADUIT
                hintText: ProfileManager.isProviderMode()
                  ? l10n.describeClientProblem // ✅ TRADUIT
                  : l10n.describeProviderProblem, // ✅ TRADUIT
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
                  return l10n.pleaseDescribeProblem; // ✅ TRADUIT
                }
                if (value!.length < 20) {
                  return l10n.descriptionMinLength; // ✅ TRADUIT
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
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
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.creationInProgress), // ✅ TRADUIT
                ],
              )
            : Text(
                ProfileManager.isProviderMode() 
                  ? l10n.createComplaint // ✅ TRADUIT
                  : l10n.createDispute, // ✅ TRADUIT
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}