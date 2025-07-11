import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import ajouté
import 'package:teyago/providers/project_provider.dart';
import '../../core/models/client_project.dart';
import '../../core/models/user.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../widgets/offer_card.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ClientProject project;

  const ProjectDetailScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorited = false;
  bool _isLoadingOffers = false;
  List<dynamic> _offers = [];
  bool _viewCounted = false;
  bool _isSubmittingOffer = false; // Contrôle l'état de soumission
  bool _showOfferForm = false;

  // VARIABLES MANQUANTES AJOUTÉES
  bool _includesMaterials = false;
  bool _travelCostsIncluded = false;

  // Controllers pour l'offre
  final TextEditingController _offerMessageController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final TextEditingController _offerDeliveryController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialiser l'état favori de manière sécurisée
    _isFavorited = widget.project.isFavorited ?? false;

    // Charger les données après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOffers();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _incrementView();
    });
  }

  Future<void> _incrementView() async {
    if (_viewCounted) return;

    try {
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.incrementProjectView(widget.project.id);
      _viewCounted = true;
    } catch (e) {
      print('Erreur lors de l\'incrémentation des vues: $e');
      // Ne pas afficher d'erreur à l'utilisateur
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _offerMessageController.dispose();
    _offerPriceController.dispose();
    _offerDeliveryController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    if (!mounted) return;

    setState(() {
      _isLoadingOffers = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final offers = await apiService.getProjectOffers(widget.project.id);

      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoadingOffers = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des offres: $e');
      if (mounted) {
        setState(() {
          _offers = [];
          _isLoadingOffers = false;
        });
      }
    }
  }

  // Fonction pour soumettre l'offre - Version corrigée
  Future<void> _submitOffer(StateSetter setBottomSheetState) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Validation des champs
    if (_offerPriceController.text.trim().isEmpty) {
      _showErrorInBottomSheet(l10n.pleaseEnterPrice, setBottomSheetState);
      return;
    }

    if (_offerDeliveryController.text.trim().isEmpty) {
      _showErrorInBottomSheet(l10n.pleaseEnterDeliveryTime, setBottomSheetState);
      return;
    }

    if (_offerMessageController.text.trim().isEmpty) {
      _showErrorInBottomSheet(l10n.pleaseEnterMessage, setBottomSheetState);
      return;
    }

    if (_offerMessageController.text.trim().length < 50) {
      _showErrorInBottomSheet(l10n.messageMinLength50, setBottomSheetState);
      return;
    }

    final double? price = double.tryParse(_offerPriceController.text.trim());
    if (price == null || price <= 0) {
      _showErrorInBottomSheet(l10n.pleaseEnterValidPrice, setBottomSheetState);
      return;
    }

    final int? deliveryTime =
        int.tryParse(_offerDeliveryController.text.trim());
    if (deliveryTime == null || deliveryTime <= 0) {
      _showErrorInBottomSheet(l10n.pleaseEnterValidDeliveryTime, setBottomSheetState);
      return;
    }

    // Activer le loader
    setBottomSheetState(() {
      _isSubmittingOffer = true;
    });

    setState(() {
      _isSubmittingOffer = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Préparer les données de l'offre
      final offerData = {
        'proposed_price': price,
        'delivery_time': deliveryTime,
        'message': _offerMessageController.text.trim(),
        'includes_materials': _includesMaterials,
        'travel_costs_included': _travelCostsIncluded,
      };

      // Envoyer l'offre
      await apiService.submitOffer(widget.project.id, offerData);

      if (mounted) {
        // FERMER D'ABORD la BottomSheet
        Navigator.pop(context);

        // Réinitialiser les états
        setState(() {
          _isSubmittingOffer = false;
          _showOfferForm = false;
        });

        // Réinitialiser les champs
        _clearOfferForm();

        // ENSUITE afficher le message de succès (visible maintenant)
        await Future.delayed(const Duration(milliseconds: 300));
        _showSuccessSnackBar(l10n.offerSentSuccessfully);

        // Optionnel : Rafraîchir les données du projet
        // await _refreshProjectData();
      }
    } catch (e) {
      if (mounted) {
        // FERMER D'ABORD la BottomSheet même en cas d'erreur
        Navigator.pop(context);

        // Réinitialiser les états
        setState(() {
          _isSubmittingOffer = false;
          _showOfferForm = false;
        });

        // Déterminer le message d'erreur
        String errorMessage = l10n.offerSendingError;

        if (e.toString().contains('déjà fait une offre')) {
          errorMessage = l10n.alreadyMadeOfferProject;
        } else if (e.toString().contains('n\'accepte plus d\'offres')) {
          errorMessage = l10n.projectNoLongerAcceptsOffers;
        }

        // ENSUITE afficher le message d'erreur (visible maintenant)
        await Future.delayed(const Duration(milliseconds: 300));
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _showErrorInBottomSheet(
      String message, StateSetter setBottomSheetState) {
    final l10n = AppLocalizations.of(context)!;
    
    // Afficher une alerte simple dans la BottomSheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.errorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  // Fonction pour afficher les messages d'erreur APRÈS fermeture de la BottomSheet
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Fonction pour afficher les messages de succès APRÈS fermeture de la BottomSheet
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!mounted) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.toggleProjectFavorite(widget.project.id);

      if (mounted) {
        setState(() {
          _isFavorited = !_isFavorited;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorited
                ? l10n.addedToFavorites
                : l10n.removedFromFavorites),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorTitle}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareProject() {
    final l10n = AppLocalizations.of(context)!;
    
    Share.share(
      l10n.discoverProject(widget.project.title, widget.project.description),
      subject: 'Projet sur Angola',
    );
  }

  void _openAttachment(String url) async {
    final l10n = AppLocalizations.of(context)!;
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cannotOpenFile),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // MÉTHODE RENOMMÉE ET CORRIGÉE
  void _showOfferModal() {
    _showOfferBottomSheet();
  }

  void _showOfferBottomSheet() {
    final l10n = AppLocalizations.of(context)!;
    
    // Variables locales pour le bottom sheet
    bool localIncludesMaterials = _includesMaterials;
    bool localTravelCostsIncluded = _travelCostsIncluded;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible:
          !_isSubmittingOffer, // Empêcher la fermeture pendant l'envoi
      enableDrag: !_isSubmittingOffer, // Empêcher le drag pendant l'envoi
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec indicateur et titre
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  if (_isSubmittingOffer)
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.sendingInProgress,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                l10n.makeOffer,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Champ prix
              TextFormField(
                controller: _offerPriceController,
                keyboardType: TextInputType.number,
                enabled: !_isSubmittingOffer,
                decoration: InputDecoration(
                  labelText: l10n.proposedPrice,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.euro),
                ),
              ),
              const SizedBox(height: 16),

              // Champ délai
              TextFormField(
                controller: _offerDeliveryController,
                keyboardType: TextInputType.number,
                enabled: !_isSubmittingOffer,
                decoration: InputDecoration(
                  labelText: l10n.deliveryTime,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.schedule),
                ),
              ),
              const SizedBox(height: 16),

              // Champ message
              TextFormField(
                controller: _offerMessageController,
                maxLines: 4,
                enabled: !_isSubmittingOffer,
                decoration: InputDecoration(
                  labelText: l10n.messageForClient,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Options supplémentaires
              CheckboxListTile(
                title: Text(l10n.materialsIncluded),
                value: localIncludesMaterials,
                onChanged: _isSubmittingOffer
                    ? null
                    : (value) {
                        setBottomSheetState(() {
                          localIncludesMaterials = value ?? false;
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                title: Text(l10n.travelCostsIncluded),
                value: localTravelCostsIncluded,
                onChanged: _isSubmittingOffer
                    ? null
                    : (value) {
                        setBottomSheetState(() {
                          localTravelCostsIncluded = value ?? false;
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 20),

              // Bouton d'envoi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmittingOffer
                      ? null
                      : () {
                          // Mettre à jour les variables d'état globales
                          setState(() {
                            _includesMaterials = localIncludesMaterials;
                            _travelCostsIncluded = localTravelCostsIncluded;
                          });

                          // Appeler la méthode de soumission
                          _submitOffer(setBottomSheetState);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF142FE2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmittingOffer
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(l10n.sendingInProgress),
                          ],
                        )
                      : Text(
                          l10n.sendMyOffer,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Future<void> _handleOfferAction(dynamic offer, String action) async {
    // Logique pour accepter/rejeter une offre
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // Implémenter l'API pour accepter/rejeter les offres

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accepted'
                ? 'Offre acceptée avec succès'
                : 'Offre rejetée'),
            backgroundColor:
                action == 'accepted' ? Colors.green : Colors.orange,
          ),
        );

        _loadOffers();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isProvider = user?.role == 'provider';
    final isClient = user?.role == 'client';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            _buildAppBar(context, isProvider),
          ];
        },
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProjectHeader(),
                    _buildProjectDetails(),
                    if (widget.project.attachments?.isNotEmpty == true)
                      _buildAttachments(),
                    if (isClient) ...[
                      _buildTabBar(),
                      SizedBox(
                        height: 400,
                        child: _buildTabBarView(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          isProvider && !_hasUserOffered() ? _buildMakeOfferButton() : null,
    );
  }

  // ... [Toutes vos autres méthodes _buildAppBar, _buildProjectHeader, etc. restent identiques]
  // Je vais les inclure pour la complétude:

  Widget _buildAppBar(BuildContext context, bool isProvider) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      leading: Container(
        margin: const EdgeInsets.all(8),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          padding: EdgeInsets.zero,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isProvider) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border,
                      color:
                          _isFavorited ? Colors.red : const Color(0xFF142FE2),
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ],
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _shareProject,
                  icon: const Icon(Icons.share,
                      color: Color(0xFF142FE2), size: 24),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      // Vous pouvez aussi ajouter une ombre personnalisée sur le conteneur principal
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF142FE2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.project.categoryName,
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.project.urgency != 'low') ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getUrgencyColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: _getUrgencyColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getUrgencyText(),
                        style: TextStyle(
                          color: _getUrgencyColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.project.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                widget.project.clientName,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                widget.project.timeSincePosted ?? 'Récemment',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.euro, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Budget: ${widget.project.budgetDisplay}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.project.remotePossible) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Remote OK',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetails() {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.projectDescription,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.project.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.project.requiredSkills.isNotEmpty) ...[
            Text(
              l10n.requiredSkills,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.project.requiredSkills.map((skill) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF142FE2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF142FE2).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                widget.project.location,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${widget.project.viewsCount} ${l10n.views}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.mail, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${widget.project.offersCount} ${l10n.offers}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.attachments,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.project.attachments!.map((attachment) {
            return _buildAttachmentItem(
              attachment['name'] ?? 'Fichier joint',
              attachment['url'] ?? '',
            );
          }).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(String name, String url) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: Color(0xFF6366F1)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _openAttachment(url),
            child: Text(l10n.open),
          ),
        ],
      ),
    );
  }

  // Fonction pour vider le formulaire
  void _clearOfferForm() {
    _offerMessageController.clear();
    _offerPriceController.clear();
    _offerDeliveryController.clear();
    _includesMaterials = false;
    _travelCostsIncluded = false;
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      color: Colors.grey[50],
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: l10n.offersTab(_offers.length)),
          Tab(text: l10n.activity),
        ],
        labelColor: const Color(0xFF142FE2),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF142FE2),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOffersTab(),
        _buildActivityTab(),
      ],
    );
  }

  Widget _buildOffersTab() {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoadingOffers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_offers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noOffersReceived,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.providersCanSendOffers,
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: OfferCard(
            offer: _offers[index],
            onAccept: (offer) => _handleOfferAction(offer, 'accepted'),
            onReject: (offer) => _handleOfferAction(offer, 'rejected'),
          ),
        );
      },
    );
  }

  Widget _buildActivityTab() {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        l10n.projectActivityToImplement,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildMakeOfferButton() {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showOfferModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142FE2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.sendOffer,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getUrgencyColor() {
    switch (widget.project.urgency) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getUrgencyText() {
    final l10n = AppLocalizations.of(context)!;
    
    switch (widget.project.urgency) {
      case 'high':
        return l10n.urgent;
      case 'medium':
        return l10n.moderate;
      case 'low':
        return l10n.notRushed;
      default:
        return '';
    }
  }

  bool _hasUserOffered() {
    return widget.project.hasUserOffered ?? false;
  }
}
