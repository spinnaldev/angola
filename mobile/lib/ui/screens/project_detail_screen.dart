import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isSubmittingOffer = false;  // Contrôle l'état de soumission
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

  // Future<void> _submitOffer() async {
  //   if (!mounted) return;

  //   final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
  //   if (user == null || user.role != 'provider') {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Vous devez être connecté en tant que prestataire'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   // Validation des champs
  //   if (_offerMessageController.text.trim().isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Veuillez saisir un message pour votre offre'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   if (_offerPriceController.text.trim().isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Veuillez indiquer un prix pour votre offre'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   if (_offerDeliveryController.text.trim().isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Veuillez indiquer un délai de livraison'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   // Validation du format des nombres
  //   final double? price = double.tryParse(_offerPriceController.text.trim());
  //   if (price == null || price <= 0) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Veuillez saisir un prix valide'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   final int? deliveryTime =
  //       int.tryParse(_offerDeliveryController.text.trim());
  //   if (deliveryTime == null || deliveryTime <= 0) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Veuillez saisir un délai valide (en jours)'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   // Afficher le loader et désactiver les interactions
  //   setState(() {
  //     _isSubmittingOffer = true;
  //   });

  //   // Préparer les données de l'offre
  //   final offerData = {
  //     'proposed_price': price,
  //     'delivery_time': deliveryTime,
  //     'message': _offerMessageController.text.trim(),
  //     'includes_materials': _includesMaterials,
  //     'travel_costs_included': _travelCostsIncluded,
  //   };

  //   try {
  //     final apiService = Provider.of<ApiService>(context, listen: false);

  //     // Envoyer l'offre
  //     await apiService.submitOffer(widget.project.id, offerData);

  //     if (mounted) {
  //       // Fermer le bottom sheet avec un délai pour montrer le succès
  //       Navigator.pop(context);

  //       // Vider les champs pour la prochaine fois
  //       _offerMessageController.clear();
  //       _offerPriceController.clear();
  //       _offerDeliveryController.clear();
  //       _includesMaterials = false;
  //       _travelCostsIncluded = false;

  //       // Afficher le message de succès
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Row(
  //             children: [
  //               Icon(Icons.check_circle, color: Colors.white),
  //               SizedBox(width: 8),
  //               Text('Offre envoyée avec succès !'),
  //             ],
  //           ),
  //           backgroundColor: Colors.green,
  //           duration: Duration(seconds: 3),
  //         ),
  //       );

  //       // Recharger les offres pour afficher la nouvelle
  //       _loadOffers();
  //     }
  //   } catch (e) {
  //     print('Erreur lors de l\'envoi de l\'offre: $e');

  //     if (mounted) {
  //       // Afficher l'erreur dans une snackbar ou un dialog
  //       String errorMessage = e.toString();
  //       if (errorMessage.startsWith('Exception: ')) {
  //         errorMessage = errorMessage.substring(11);
  //       }

  //       // Si l'erreur est longue, l'afficher dans un dialog
  //       if (errorMessage.length > 100) {
  //         showDialog(
  //           context: context,
  //           builder: (context) => AlertDialog(
  //             title: const Row(
  //               children: [
  //                 Icon(Icons.error, color: Colors.red),
  //                 SizedBox(width: 8),
  //                 Text('Erreur'),
  //               ],
  //             ),
  //             content: SingleChildScrollView(
  //               child: Text(errorMessage),
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Text('OK'),
  //               ),
  //             ],
  //           ),
  //         );
  //       } else {
  //         // Sinon, utiliser une snackbar
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Row(
  //               children: [
  //                 const Icon(Icons.error, color: Colors.white),
  //                 const SizedBox(width: 8),
  //                 Expanded(child: Text(errorMessage)),
  //               ],
  //             ),
  //             backgroundColor: Colors.red,
  //             duration: const Duration(seconds: 5),
  //             action: SnackBarAction(
  //               label: 'Fermer',
  //               textColor: Colors.white,
  //               onPressed: () {
  //                 ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //               },
  //             ),
  //           ),
  //         );
  //       }
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isSubmittingOffer = false;
  //       });
  //     }
  //   }
  // }

  // Fonction pour soumettre l'offre - Version corrigée
  Future<void> _submitOffer(StateSetter setBottomSheetState) async {
    // Validation des champs
    if (_offerPriceController.text.trim().isEmpty) {
      _showErrorInBottomSheet('Veuillez saisir un prix', setBottomSheetState);
      return;
    }

    if (_offerDeliveryController.text.trim().isEmpty) {
      _showErrorInBottomSheet('Veuillez saisir un délai de livraison', setBottomSheetState);
      return;
    }

    if (_offerMessageController.text.trim().isEmpty) {
      _showErrorInBottomSheet('Veuillez saisir un message', setBottomSheetState);
      return;
    }

    if (_offerMessageController.text.trim().length < 50) {
      _showErrorInBottomSheet('Le message doit contenir au moins 50 caractères', setBottomSheetState);
      return;
    }

    final double? price = double.tryParse(_offerPriceController.text.trim());
    if (price == null || price <= 0) {
      _showErrorInBottomSheet('Veuillez saisir un prix valide', setBottomSheetState);
      return;
    }

    final int? deliveryTime = int.tryParse(_offerDeliveryController.text.trim());
    if (deliveryTime == null || deliveryTime <= 0) {
      _showErrorInBottomSheet('Veuillez saisir un délai valide (en jours)', setBottomSheetState);
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
        _showSuccessSnackBar('Offre envoyée avec succès !');

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
        String errorMessage = 'Erreur lors de l\'envoi de l\'offre';
        
        if (e.toString().contains('déjà fait une offre')) {
          errorMessage = 'Vous avez déjà fait une offre pour ce projet';
        } else if (e.toString().contains('n\'accepte plus d\'offres')) {
          errorMessage = 'Ce projet n\'accepte plus d\'offres';
        }

        // ENSUITE afficher le message d'erreur (visible maintenant)
        await Future.delayed(const Duration(milliseconds: 300));
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _showErrorInBottomSheet(String message, StateSetter setBottomSheetState) {
    // Vous pouvez soit :
    // 1. Afficher un widget d'erreur dans la BottomSheet
    // 2. Ou utiliser un ScaffoldMessenger temporaire dans la BottomSheet
    
    // Option 1: Afficher une alerte simple dans la BottomSheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
                ? 'Projet ajouté aux favoris'
                : 'Projet retiré des favoris'),
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
    }
  }

  void _shareProject() {
    Share.share(
      'Découvrez ce projet: ${widget.project.title}\n\n${widget.project.description}',
      subject: 'Projet sur Angola',
    );
  }

  void _openAttachment(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le fichier'),
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
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Envoi en cours...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Faire une offre',
                style: TextStyle(
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
                decoration: const InputDecoration(
                  labelText: 'Prix proposé (€)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
              ),
              const SizedBox(height: 16),

              // Champ délai
              TextFormField(
                controller: _offerDeliveryController,
                keyboardType: TextInputType.number,
                enabled: !_isSubmittingOffer,
                decoration: const InputDecoration(
                  labelText: 'Délai de livraison (jours)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                ),
              ),
              const SizedBox(height: 16),

              // Champ message
              TextFormField(
                controller: _offerMessageController,
                maxLines: 4,
                enabled: !_isSubmittingOffer,
                decoration: const InputDecoration(
                  labelText: 'Message pour le client',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Options supplémentaires
              CheckboxListTile(
                title: const Text('Matériaux inclus'),
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
                title: const Text('Frais de déplacement inclus'),
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
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Envoi en cours...'),
                          ],
                        )
                      : const Text(
                          'Envoyer mon offre',
                          style: TextStyle(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description du projet',
            style: TextStyle(
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
            const Text(
              'Compétences requises',
              style: TextStyle(
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
                '${widget.project.viewsCount} vues',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.mail, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${widget.project.offersCount} offres',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fichiers joints',
            style: TextStyle(
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
            child: const Text('Ouvrir'),
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
    return Container(
      color: Colors.grey[50],
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: 'Offres (${_offers.length})'),
          const Tab(text: 'Activité'),
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
              'Aucune offre reçue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les prestataires intéressés pourront vous envoyer leurs offres',
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text(
        'Activité du projet - À implémenter',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildMakeOfferButton() {
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
            child: const Text(
              'Envoyer une offre',
              style: TextStyle(
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
    switch (widget.project.urgency) {
      case 'high':
        return 'Urgent';
      case 'medium':
        return 'Modéré';
      case 'low':
        return 'Pas pressé';
      default:
        return '';
    }
  }

  bool _hasUserOffered() {
    return widget.project.hasUserOffered ?? false;
  }
}
