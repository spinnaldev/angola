// lib/ui/screens/project_detail_screen.dart - Version corrigée
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isSubmittingOffer = false;
  List<dynamic> _offers = [];

  // Controllers pour l'offre
  final TextEditingController _offerMessageController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final TextEditingController _offerDeliveryController = TextEditingController();

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

  Future<void> _submitOffer() async {
    if (!mounted) return;

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null || user.role != 'provider') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté en tant que prestataire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_offerMessageController.text.trim().isEmpty ||
        _offerPriceController.text.trim().isEmpty ||
        _offerDeliveryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingOffer = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final offerData = {
        'message': _offerMessageController.text.trim(),
        'price': double.tryParse(_offerPriceController.text.trim()) ?? 0.0,
        'delivery_time': int.tryParse(_offerDeliveryController.text.trim()) ?? 1,
      };

      await apiService.submitOffer(widget.project.id, offerData);

      if (mounted) {
        // Vider les champs
        _offerMessageController.clear();
        _offerPriceController.clear();
        _offerDeliveryController.clear();

        // Fermer le modal
        Navigator.pop(context);

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        // Recharger les offres
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingOffer = false;
        });
      }
    }
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
            content: Text(
              _isFavorited 
                ? 'Projet ajouté aux favoris' 
                : 'Projet retiré des favoris'
            ),
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

  void _showOfferModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Envoyer une offre',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Message de présentation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _offerMessageController,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText: 'Présentez-vous et expliquez pourquoi vous êtes le bon choix pour ce projet...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Prix (€)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _offerPriceController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: '1000',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Délai (jours)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _offerDeliveryController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: '30',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmittingOffer ? null : _submitOffer,
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
                            : const Text(
                                'Envoyer l\'offre',
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
          ],
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
            content: Text(
              action == 'accepted' 
                ? 'Offre acceptée avec succès' 
                : 'Offre rejetée'
            ),
            backgroundColor: action == 'accepted' ? Colors.green : Colors.orange,
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
      bottomNavigationBar: isProvider && !_hasUserOffered() 
          ? _buildMakeOfferButton() 
          : null,
    );
  }

  Widget _buildAppBar(BuildContext context, bool isProvider) {
    return SliverAppBar(
      expandedHeight: 80, // Réduire la hauteur de 100 à 80
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF142FE2),
      elevation: 4, // Ajouter une élévation pour l'effet shadow
      shadowColor: const Color(0xFF142FE2).withOpacity(0.3), // Couleur du shadow
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          padding: EdgeInsets.zero,
        ),
      ),
      actions: [
        // Conteneur pour organiser les actions sur une ligne
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isProvider) ...[
                // Bouton favori avec background semi-transparent
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorited ? Colors.red : Colors.white,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ],
              // Bouton partage avec background semi-transparent
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _shareProject,
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Détails du projet',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18, // Taille légèrement plus petite
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 12), // Ajuster pour le nouveau bouton back
        centerTitle: false, // Aligner à gauche
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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