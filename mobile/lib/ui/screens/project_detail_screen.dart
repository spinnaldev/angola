import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:teyago/providers/project_provider.dart';
import '../../core/models/client_project.dart';
import '../../core/models/user.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../widgets/offer_card.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    final number = int.parse(text);
    final formatted = NumberFormat('#,###', 'fr_FR').format(number);
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({
    Key? key,
    required this.projectId,
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
  bool _isSubmittingOffer = false;
  
  // Variables pour le chargement du projet
  bool _isLoadingProject = false;
  ClientProject? _project;

  // Variables pour les options d'offre
  bool _includesMaterials = false;
  bool _travelCostsIncluded = false;

  // Controllers pour l'offre
  final TextEditingController _offerMessageController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final TextEditingController _offerDeliveryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProject();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _offerMessageController.dispose();
    _offerPriceController.dispose();
    _offerDeliveryController.dispose();
    super.dispose();
  }
  double? parseFormattedPrice(String formattedPrice) {
    final cleaned = formattedPrice.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  // ========== MÉTHODES DE CHARGEMENT DES DONNÉES ==========

  Future<void> _loadProject() async {
    if (!mounted) return;

    setState(() {
      _isLoadingProject = true;
    });

    try {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final project = await projectProvider.getProjectById(widget.projectId);
      
      if (mounted && project != null) {
        setState(() {
          _project = project;
          _isFavorited = project.isFavorited ?? false;
          _isLoadingProject = false;
        });
        
        await _loadOffers();
        
        Future.delayed(const Duration(milliseconds: 500), () {
          _incrementView();
        });
      } else if (mounted) {
        _handleLoadingError('Projet non trouvé');
      }
    } catch (e) {
      print('Erreur lors du chargement du projet: $e');
      if (mounted) {
        _handleLoadingError('Erreur de chargement du projet');
      }
    }
  }

  Future<void> _loadOffers() async {
    if (!mounted || _project == null) return;

    setState(() {
      _isLoadingOffers = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final offers = await apiService.getProjectOffers(_project!.id);

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

  Future<void> _incrementView() async {
    if (_viewCounted || _project == null) return;

    try {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.incrementProjectView(_project!.id);
      _viewCounted = true;
    } catch (e) {
      print('Erreur lors de l\'incrémentation des vues: $e');
    }
  }

  void _handleLoadingError(String message) {
    setState(() {
      _isLoadingProject = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    
    Navigator.pop(context);
  }

  // ========== GESTION DES OFFRES ==========

  Future<void> _submitOffer(StateSetter setBottomSheetState) async {
    final l10n = AppLocalizations.of(context)!;

    // Validation des champs
    final validationError = _validateOfferForm(l10n);
    if (validationError != null) {
      _showErrorInBottomSheet(validationError, setBottomSheetState);
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
        'proposed_price': double.parse(_offerPriceController.text.trim()),
        'delivery_time': int.parse(_offerDeliveryController.text.trim()),
        'message': _offerMessageController.text.trim(),
        'includes_materials': _includesMaterials,
        'travel_costs_included': _travelCostsIncluded,
      };

      // Envoyer l'offre
      await apiService.submitOffer(_project!.id, offerData);

      if (mounted) {
        // Fermer la BottomSheet
        Navigator.pop(context);

        // Réinitialiser les états
        setState(() {
          _isSubmittingOffer = false;
        });

        // Réinitialiser les champs
        _clearOfferForm();

        // Afficher le message de succès
        await Future.delayed(const Duration(milliseconds: 300));
        _showSuccessSnackBar(l10n.offerSentSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        // Fermer la BottomSheet
        Navigator.pop(context);

        // Réinitialiser les états
        setState(() {
          _isSubmittingOffer = false;
        });

        // Afficher le message d'erreur
        await Future.delayed(const Duration(milliseconds: 300));
        _showErrorSnackBar(_getErrorMessage(e.toString(), l10n));
      }
    }
  }

  String? _validateOfferForm(AppLocalizations l10n) {
    if (_offerPriceController.text.trim().isEmpty) {
      return l10n.pleaseEnterPrice;
    }

    if (_offerDeliveryController.text.trim().isEmpty) {
      return l10n.pleaseEnterDeliveryTime;
    }

    if (_offerMessageController.text.trim().isEmpty) {
      return l10n.pleaseEnterMessage;
    }

    if (_offerMessageController.text.trim().length < 50) {
      return l10n.messageMinLength50;
    }

    final double? price = double.tryParse(_offerPriceController.text.trim());
    if (price == null || price <= 0) {
      return l10n.pleaseEnterValidPrice;
    }

    final int? deliveryTime = int.tryParse(_offerDeliveryController.text.trim());
    if (deliveryTime == null || deliveryTime <= 0) {
      return l10n.pleaseEnterValidDeliveryTime;
    }

    return null;
  }

  String _getErrorMessage(String error, AppLocalizations l10n) {
    if (error.contains('déjà fait une offre')) {
      return l10n.alreadyMadeOfferProject;
    } else if (error.contains('n\'accepte plus d\'offres')) {
      return l10n.projectNoLongerAcceptsOffers;
    }
    return l10n.offerSendingError;
  }

  void _clearOfferForm() {
    _offerMessageController.clear();
    _offerPriceController.clear();
    _offerDeliveryController.clear();
    _includesMaterials = false;
    _travelCostsIncluded = false;
  }

  // ========== MÉTHODES D'AFFICHAGE DES MESSAGES ==========

  void _showErrorInBottomSheet(String message, StateSetter setBottomSheetState) {
    final l10n = AppLocalizations.of(context)!;

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

  // ========== ACTIONS UTILISATEUR ==========

  Future<void> _toggleFavorite() async {
    final l10n = AppLocalizations.of(context)!;

    if (!mounted || _project == null) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.toggleProjectFavorite(_project!.id);

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

    if (_project == null) return;

    Share.share(
      l10n.discoverProject(_project!.title, _project!.description),
      subject: 'Projet sur Teyago',
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

  void _showOfferBottomSheet() {
    final l10n = AppLocalizations.of(context)!;

    bool localIncludesMaterials = _includesMaterials;
    bool localTravelCostsIncluded = _travelCostsIncluded;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !_isSubmittingOffer,
      enableDrag: !_isSubmittingOffer,
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // En-tête fixe
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
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
                          Text(
                            l10n.sendingInProgress,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Zone scrollable
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 10,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.makeOffer,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ CHAMP PRIX AMÉLIORÉ
                      TextFormField(
                        controller: _offerPriceController,
                        keyboardType: TextInputType.number,
                        enabled: !_isSubmittingOffer,
                        inputFormatters: [
                          PriceInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: '${l10n.proposedPrice} ',
                          hintText: l10n.priceExample,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                          helperText: l10n.priceFormatHelper,
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
                          // hintText: 'Ex: 7 jours',
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

                      // Options
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

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              
              // Bouton fixe
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingOffer
                        ? null
                        : () {
                            setState(() {
                              _includesMaterials = localIncludesMaterials;
                              _travelCostsIncluded = localTravelCostsIncluded;
                            });

                            _submitOfferWithFormattedPrice(setBottomSheetState);
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
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.sendMyOffer,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
  void _submitOfferWithFormattedPrice(StateSetter setBottomSheetState) async {
    final l10n = AppLocalizations.of(context)!;

    // Validation avec prix formaté
    final validationError = _validateOfferFormWithFormatting(l10n);
    if (validationError != null) {
      _showErrorInBottomSheet(validationError, setBottomSheetState);
      return;
    }

    setBottomSheetState(() {
      _isSubmittingOffer = true;
    });

    setState(() {
      _isSubmittingOffer = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // ✅ Nettoyer le prix avant envoi
      final cleanPrice = parseFormattedPrice(_offerPriceController.text.trim())!;

      final offerData = {
        'proposed_price': cleanPrice,
        'delivery_time': int.parse(_offerDeliveryController.text.trim()),
        'message': _offerMessageController.text.trim(),
        'includes_materials': _includesMaterials,
        'travel_costs_included': _travelCostsIncluded,
      };

      await apiService.submitOffer(_project!.id, offerData);

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _isSubmittingOffer = false;
        });
        _clearOfferForm();
        await Future.delayed(const Duration(milliseconds: 300));
        _showSuccessSnackBar(l10n.offerSentSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _isSubmittingOffer = false;
        });
        await Future.delayed(const Duration(milliseconds: 300));
        _showErrorSnackBar(_getErrorMessage(e.toString(), l10n));
      }
    }
  }

   String? _validateOfferFormWithFormatting(AppLocalizations l10n) {
    if (_offerPriceController.text.trim().isEmpty) {
      return l10n.pleaseEnterPrice;
    }

    if (_offerDeliveryController.text.trim().isEmpty) {
      return l10n.pleaseEnterDeliveryTime;
    }

    if (_offerMessageController.text.trim().isEmpty) {
      return l10n.pleaseEnterMessage;
    }

    if (_offerMessageController.text.trim().length < 50) {
      return l10n.messageMinLength50;
    }

    final double? price = parseFormattedPrice(_offerPriceController.text.trim());
    if (price == null || price <= 0) {
      return l10n.pleaseEnterValidPrice;
    }

    final int? deliveryTime = int.tryParse(_offerDeliveryController.text.trim());
    if (deliveryTime == null || deliveryTime <= 0) {
      return l10n.pleaseEnterValidDeliveryTime;
    }

    return null;
  }
  Future<void> _handleOfferAction(dynamic offer, String action) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

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

  // ========== MÉTHODES DE CONSTRUCTION DE L'UI ==========

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isProvider = user?.role == 'provider';
    final isClient = user?.role == 'client';

    if (_isLoadingProject || _project == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                    if (_project!.attachments?.isNotEmpty == true)
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
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF142FE2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _project!.categoryName,
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (_project!.urgency != 'low') ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getUrgencyColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 12, color: _getUrgencyColor()),
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
            _project!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Card client avec photo et infos
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Photo de profil du client
                CircleAvatar(
                  radius: 20,
                  backgroundImage: _project!.clientPicture != null && _project!.clientPicture!.isNotEmpty
                      ? NetworkImage(_project!.clientPicture!)
                      : null,
                  backgroundColor: const Color(0xFF142FE2),
                  child: _project!.clientPicture == null || _project!.clientPicture!.isEmpty
                      ? Text(
                          _project!.clientName.isNotEmpty 
                              ? _project!.clientName[0].toUpperCase() 
                              : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _project!.client?.firstName ?? _project!.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _project!.timeSincePosted ?? l10n.recently,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Badge client vérifié
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.client,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Budget container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${l10n.budget}: ${_project!.budgetDisplay}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_project!.remotePossible) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.remoteOk,
                      style: const TextStyle(
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
            _project!.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          if (_project!.requiredSkills.isNotEmpty) ...[
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
              children: _project!.requiredSkills.map((skill) {
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
                _project!.location,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_project!.viewsCount} ${l10n.views}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.mail, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_project!.offersCount} ${l10n.offers}',
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
          ..._project!.attachments!.map((attachment) {
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
            onPressed: _handleOfferButtonAction,
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
    switch (_project!.urgency) {
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

    switch (_project!.urgency) {
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
    return _project!.hasUserOffered ?? false;
  }
  void _handleOfferButtonAction() {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user?.isVerified == true) {
      _showOfferBottomSheet();
    } else {
      _showVerificationRequiredDialog(l10n);
    }
  }
  void _showVerificationRequiredDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified_user, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(l10n.verificationRequired),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.verificationRequiredToSendOffer),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.completeVerificationFirst,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/provider-verification');
            },
            icon: Icon(Icons.verified_user, size: 18),
            label: Text(l10n.verify),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

}