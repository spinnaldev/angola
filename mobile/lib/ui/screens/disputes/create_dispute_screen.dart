// lib/ui/screens/disputes/create_dispute_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:teyago/providers/offers_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../providers/dispute_provider.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/provider_list_provider.dart';
import '../../../providers/project_provider.dart'; // ✅ NOUVEAU
import '../../../providers/quote_provider.dart'; // ✅ NOUVEAU
import '../../../core/services/profile_manager.dart';
import '../../widgets/loading_indicator.dart';
import '../../../core/models/service.dart';
import '../../../core/models/provider_model.dart';
import '../post_project_screen.dart';
import '../../../ui/screens/provider/add_edit_service_screen.dart';


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

class InteractedUser {
  final int id;
  final String name;

  InteractedUser({required this.id, required this.name});
}

class _CreateDisputeScreenState extends State<CreateDisputeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs de texte
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientInfoController =
      TextEditingController(); // Pour les prestataires

  bool _isSubmitting = false;

  bool _isCheckingEligibility = true; // ✅ NOUVEAU
  bool _isEligible = false; // ✅ NOUVEAU
  String? _ineligibilityReason; // ✅ NOUVEAU

  int? _selectedProviderId;
  int? _selectedServiceId;
  List<Service> _services = [];
  List<ProviderModel> _providers = [];
  List<InteractedUser> _interactedUsers = [];
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

    // if (ProfileManager.isClientMode()) {
    //   _loadProviders();
    //   if (_selectedProviderId != null) {
    //     _loadServicesForProvider(_selectedProviderId!);
    //   }
    // }

    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    setState(() {
      _isCheckingEligibility = true;
    });

    try {
      if (ProfileManager.isProviderMode()) {
        // Vérifier si le prestataire a des services OU des offres validées
        final hasServices = await _checkProviderHasServices();
        print("!!!!!!!!!!!!!!!!!!!!!!On a des services ? $hasServices");
        final hasAcceptedOffers = await _checkProviderHasAcceptedOffers();

        if (!hasServices && !hasAcceptedOffers) {
          setState(() {
            _isEligible = false;
            _ineligibilityReason = 'no_services_or_offers';
          });
          return;
        }
      } else {
        // Vérifier si le client a des projets OU des demandes de devis
        final hasProjects = await _checkClientHasProjects();
        final hasQuoteRequests = await _checkClientHasQuoteRequests();

        if (!hasProjects && !hasQuoteRequests) {
          setState(() {
            _isEligible = false;
            _ineligibilityReason = 'no_projects_or_quotes';
          });
          return;
        }
      }

      // Si tout est OK
      setState(() {
        _isEligible = true;
      });

      // Charger les données nécessaires pour le formulaire
      if (ProfileManager.isClientMode()) {
        await _loadInteractedProviders(); // ✅ NOUVELLE MÉTHODE
      } else {
        await _loadInteractedClients(); // ✅ NOUVELLE MÉTHODE
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification d\'éligibilité: $e');
      setState(() {
        _isEligible = false;
        _ineligibilityReason = 'error';
      });
    } finally {
      setState(() {
        _isCheckingEligibility = false;
      });
    }
  }

  /// Pour CLIENT : Charger les prestataires avec qui il a interagi
  Future<void> _loadInteractedProviders() async {
    setState(() {
      _loadingProviders = true;
    });

    try {
      final Set<int> providerIds = {};
      final Map<int, String> providerNames = {};

      // 1. Depuis les demandes de devis (QuoteRequest a seulement providerId)
      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      await quoteProvider.fetchUserQuoteRequests();
      
      for (var quoteRequest in quoteProvider.quoteRequests) {
        if (quoteRequest.providerId > 0) {
          providerIds.add(quoteRequest.providerId);
          // QuoteRequest n'a PAS providerName, on le récupérera de l'API
        }
      }
      print('✅ ${providerIds.length} prestataires depuis devis');

      // 2. Depuis les offres sur mes projets (ProjectOffer a providerId et providerName)
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.fetchUserProjects();
      
      // Utiliser directement _apiService au lieu d'ApiService
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      for (var project in projectProvider.userProjects) {
        try {
          final offers = await apiService.getProjectOffers(project.id);
          
          for (var offerJson in offers) {
            // ProjectOffer a providerId et providerName
            final providerId = offerJson['provider_id'] ?? offerJson['provider'];
            final providerName = offerJson['provider_name'];
            
            if (providerId != null && providerId is int && providerId > 0) {
              providerIds.add(providerId);
              if (providerName != null && providerName is String && providerName.isNotEmpty) {
                providerNames[providerId] = providerName;
              }
            }
          }
        } catch (e) {
          print('⚠️ Erreur offres projet ${project.id}: $e');
        }
      }
      print('✅ Total: ${providerIds.length} prestataires uniques');

      // 3. Pour les IDs sans nom, essayer de récupérer via ProviderListProvider
      if (providerIds.isNotEmpty) {
        try {
          final providerListProvider = Provider.of<ProviderListProvider>(context, listen: false);
          await providerListProvider.fetchProviders();
          
          for (var provider in providerListProvider.providers) {
            if (providerIds.contains(provider.id) && !providerNames.containsKey(provider.id)) {
              providerNames[provider.id] = provider.name;
            }
          }
        } catch (e) {
          print('⚠️ Erreur chargement noms prestataires: $e');
        }
      }

      // 4. Créer la liste finale
      final interactedProviders = <InteractedUser>[];
      for (var providerId in providerIds) {
        final name = providerNames[providerId] ?? 'Prestataire #$providerId';
        interactedProviders.add(InteractedUser(id: providerId, name: name));
      }

      interactedProviders.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _interactedUsers = interactedProviders;
        _loadingProviders = false;
      });

      if (_selectedProviderId != null) {
        await _loadServicesForProvider(_selectedProviderId!);
      }

    } catch (e) {
      print('❌ Erreur _loadInteractedProviders: $e');
      setState(() {
        _interactedUsers = [];
        _loadingProviders = false;
      });
    }
  }

  /// Pour PRESTATAIRE : Charger les clients avec qui il a interagi
  Future<void> _loadInteractedClients() async {
    print('🔍 DEBUT _loadInteractedClients');
    setState(() {
      _loadingProviders = true;
    });

    try {
      final Set<int> clientIds = {};
      final Map<int, String> clientNames = {};

      // 1. Depuis les demandes de devis REÇUES
      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      await quoteProvider.fetchUserQuoteRequests();
      
      print('📋 QuoteRequests récupérés: ${quoteProvider.quoteRequests.length}');
      
      for (var quoteRequest in quoteProvider.quoteRequests) {
        print('  - QuoteRequest: clientId=${quoteRequest.clientId}, subject=${quoteRequest.subject}');
        if (quoteRequest.clientId > 0) {
          clientIds.add(quoteRequest.clientId);
          
          // ✅ AJOUTE CES 3 LIGNES :
          if (quoteRequest.clientName != null && quoteRequest.clientName!.isNotEmpty) {
            clientNames[quoteRequest.clientId] = quoteRequest.clientName!;
          }
        }
      }
      print('✅ ${clientIds.length} clients depuis devis');

      // 2. Depuis mes offres
      final offersProvider = Provider.of<OffersProvider>(context, listen: false);
      await offersProvider.fetchMyOffers();
      
      print('📋 Offres récupérées: ${offersProvider.offers.length}');
      
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      
      for (var offer in offersProvider.offers) {
        print('  - Offre: projectId=${offer.projectId}, status=${offer.status}');
        if (offer.projectId != null && offer.projectId! > 0) {
          try {
            final project = await projectProvider.getProjectById(offer.projectId!);
            
            if (project != null && project.client != null && project.client!.id > 0) {
              print('    → Client trouvé: id=${project.client!.id}, name=${project.clientName}');
              clientIds.add(project.client!.id);
              if (project.clientName != null && project.clientName!.isNotEmpty) {
                clientNames[project.client!.id] = project.clientName!;
              }
            } else {
              print('    → Projet sans client valide');
            }
          } catch (e) {
            print('⚠️ Erreur récupération projet ${offer.projectId}: $e');
          }
        }
      }
      print('✅ Total: ${clientIds.length} clients uniques');
      print('✅ Noms récupérés: $clientNames');

      // 3. Créer la liste finale
      final interactedClients = <InteractedUser>[];
      for (var clientId in clientIds) {
        final name = clientNames[clientId] ?? 'Client #$clientId';
        print('  → Ajout: id=$clientId, name=$name');
        interactedClients.add(InteractedUser(id: clientId, name: name));
      }

      interactedClients.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _interactedUsers = interactedClients;
        _loadingProviders = false;
      });
      
      print('🎯 FINAL: ${_interactedUsers.length} clients dans _interactedUsers');
      for (var user in _interactedUsers) {
        print('  - ${user.id}: ${user.name}');
      }

    } catch (e) {
      print('❌ Erreur _loadInteractedClients: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      setState(() {
        _interactedUsers = [];
        _loadingProviders = false;
      });
    }
  }
  Future<bool> _checkProviderHasServices() async {
    try {
      final serviceProvider =
          Provider.of<ServiceProvider>(context, listen: false);
      await serviceProvider.fetchMyServices();
      print(
          "!!!!!!!!!!!!!!!!!!!!!!Services: ${serviceProvider.myServices.length}");
      return serviceProvider.myServices.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification services: $e');
      return false;
    }
  }

  // ✅ Vérifier si le prestataire a des offres acceptées
  Future<bool> _checkProviderHasAcceptedOffers() async {
    try {
      final projectProvider =
          Provider.of<OffersProvider>(context, listen: false);
      await projectProvider.fetchMyOffers();
      // Vérifier s'il y a au moins une offre acceptée
      return projectProvider.offers.any((offer) => offer.status == 'accepted');
    } catch (e) {
      print('❌ Erreur vérification offres: $e');
      return false;
    }
  }

  // ✅ Vérifier si le client a des projets
  Future<bool> _checkClientHasProjects() async {
  try {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    await projectProvider.fetchUserProjects();
    
    // ✅ CHANGEMENT: Utiliser userProjects au lieu de allProjects
    final hasProjects = projectProvider.userProjects.isNotEmpty;
    print('✅ Vérification projets client: $hasProjects (${projectProvider.userProjects.length} projets)');
    
    return hasProjects;
  } catch (e) {
    print('❌ Erreur vérification projets: $e');
    return false;
  }
}

  // ✅ Vérifier si le client a des demandes de devis
  Future<bool> _checkClientHasQuoteRequests() async {
    try {
      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      await quoteProvider.fetchUserQuoteRequests();
      return quoteProvider.quoteRequests.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification devis: $e');
      return false;
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

      await Provider.of<ProviderListProvider>(context, listen: false)
          .fetchProviders();
      final providerListProvider =
          Provider.of<ProviderListProvider>(context, listen: false);

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
          print(
              '⚠️ Provider invalide ignoré: ID=${provider.id}, Name="${provider.name}"');
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
      final serviceProvider =
          Provider.of<ServiceProvider>(context, listen: false);
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
          SnackBar(
              content: Text('${l10n.errorLoadingServices} $e')), // ✅ TRADUIT
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
          reason != l10n.otherClientProblem) {
        // ✅ TRADUIT
        _titleController.text = reason;
      } else {
        _titleController.clear();
      }
    });
  }

  Future<void> _submitDispute() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    // Validation selon le profil
    if (ProfileManager.isClientMode() && _selectedProviderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectProvider)),
      );
      return;
    }

    // ✅ NOUVEAU : Vérifier qu'un client est sélectionné pour les prestataires
    if (ProfileManager.isProviderMode() && _selectedProviderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectClient)),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final disputeProvider = Provider.of<DisputeProvider>(context, listen: false);

      print('📤 Envoi du litige:');
      print('  - Mode: ${ProfileManager.isProviderMode() ? "PRESTATAIRE" : "CLIENT"}');
      print('  - selectedProviderId: $_selectedProviderId');
      print('  - selectedServiceId: $_selectedServiceId');
      
      bool success;
      if (ProfileManager.isClientMode()) {
        // CLIENT → Dispute contre un prestataire
        print('  → Client crée un litige contre prestataire $_selectedProviderId');
        success = await disputeProvider.createDispute(
          _selectedProviderId!,
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          serviceId: _selectedServiceId,
        );
      } else {
        // PRESTATAIRE → Réclamation contre un client
        // _selectedProviderId contient en fait le clientId
        print('  → Prestataire crée une réclamation contre client $_selectedProviderId');
        
        // ✅ CORRECTION : Envoyer le clientId au lieu de 0
        // Vous devez adapter selon la signature de votre DisputeProvider.createDispute
        // Si elle attend (providerId, title, description, {serviceId, clientId}):
        success = await disputeProvider.createDispute(
          _selectedProviderId!, // ✅ Envoyer le clientId sélectionné
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
                ? l10n.complaintCreatedSuccessfully
                : l10n.disputeCreatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(disputeProvider.errorMessage ?? l10n.errorCreating),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur _submitDispute: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error} $e'),
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

  Widget _buildIneligibilityScreen(AppLocalizations l10n) {
    String title;
    String message;
    String actionText;
    VoidCallback? onAction;

    if (ProfileManager.isProviderMode()) {
      title = l10n.cannotCreateComplaint;
      message = l10n.cannotCreateComplaintMessage;
      actionText = l10n.addFirstService;
      onAction = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditServiceScreen(),
          ),
        );
        // Navigator.pushNamed(context, '/add-service');
      };
    } else {
      title = l10n.cannotCreateDispute;
      message = l10n.cannotCreateDisputeMessage;
      actionText = l10n.postFirstProject;
      onAction = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PostProjectScreen(),
          ),
        );
        // Navigator.pushNamed(context, '/create-project');
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(ProfileManager.isProviderMode()
            ? l10n.newComplaint
            : l10n.newDispute),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Colors.orange[700],
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT

    if (_isCheckingEligibility) {
      return Scaffold(
        appBar: AppBar(
          title: Text(ProfileManager.isProviderMode()
              ? l10n.newComplaint
              : l10n.newDispute),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ✅ Afficher l'écran d'inéligibilité si nécessaire
    if (!_isEligible) {
      return _buildIneligibilityScreen(l10n);
    }

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

  Widget _buildHeaderCard(AppLocalizations l10n) {
    // ✅ PARAMÈTRE l10n
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
                  ProfileManager.isProviderMode()
                      ? Icons.report_outlined
                      : Icons.gavel,
                  color: Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  // ✅ AJOUT pour éviter overflow
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

  Widget _buildProviderSelection(AppLocalizations l10n) {
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
              l10n.step1SelectProvider,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_loadingProviders)
              const Center(child: CircularProgressIndicator())
            else if (_interactedUsers.isEmpty) // ✅ MODIFIÉ
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.noInteractedProviders, // ✅ NOUVELLE TRADUCTION
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedProviderId,
                decoration: InputDecoration(
                  labelText: l10n.concernedProvider,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person_search),
                ),
                items: _interactedUsers.map((user) { // ✅ MODIFIÉ
                  return DropdownMenuItem<int>(
                    value: user.id,
                    child: Text(
                      user.name,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                validator: (value) => value == null 
                    ? l10n.pleaseSelectProvider
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
              provider.name.isNotEmpty
                  ? provider.name
                  : 'Prestataire #${provider.id}',
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

  Widget _buildServiceSelection(AppLocalizations l10n) {
    // ✅ PARAMÈTRE l10n
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
                  ..._services
                      .where((service) => service.id != null)
                      .map((service) {
                        return DropdownMenuItem<int?>(
                          value: service.id,
                          child: Text(
                            service.title,
                            overflow:
                                TextOverflow.ellipsis, // ✅ Évite le débordement
                          ),
                        );
                      })
                      .toSet()
                      .toList(),
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

  Widget _buildClientInfoSection(AppLocalizations l10n) {
    print('🎨 _buildClientInfoSection: _interactedUsers.length=${_interactedUsers.length}');
    print('🎨 _selectedProviderId (clientId): $_selectedProviderId');
    
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
              l10n.step1SelectClient,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_loadingProviders)
              const Center(child: CircularProgressIndicator())
            else if (_interactedUsers.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.noInteractedClients,
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedProviderId,
                decoration: InputDecoration(
                  labelText: l10n.concernedClient,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: _interactedUsers.map((user) {
                  print('  → Item dropdown: ${user.id} - ${user.name}');
                  return DropdownMenuItem<int>(
                    value: user.id,
                    child: Text(
                      user.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  print('✅ Client sélectionné: $value');
                  setState(() {
                    _selectedProviderId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return l10n.pleaseSelectClient;
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSelection(AppLocalizations l10n) {
    // ✅ PARAMÈTRE l10n
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
              items: _getCommonReasons(l10n).map((reason) {
                // ✅ UTILISER MÉTHODE TRADUITE
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

  Widget _buildDisputeForm(AppLocalizations l10n) {
    // ✅ PARAMÈTRE l10n
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

  Widget _buildSubmitButton(AppLocalizations l10n) {
    // ✅ PARAMÈTRE l10n
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
