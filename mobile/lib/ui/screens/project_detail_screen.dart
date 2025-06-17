import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/client_project.dart';
import '../../core/models/project_offer.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import 'make_offer_screen.dart';
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

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<ProjectOffer> _offers = [];
  bool _isLoadingOffers = false;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isFavorited = widget.project.isFavorited ?? false;
    
    // Charger les offres si c'est le client propriétaire
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.role == 'client') {
      _loadOffers();
    }
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoadingOffers = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final offers = await apiService.getProjectOffers(widget.project.id);
      setState(() {
        _offers = offers;
      });
    } catch (e) {
      print('Erreur lors du chargement des offres: $e');
    } finally {
      setState(() {
        _isLoadingOffers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isOwner = user?.role == 'client';
    final isProvider = user?.role == 'provider';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isProvider),
          SliverToBoxAdapter(child: _buildProjectHeader()),
          SliverToBoxAdapter(child: _buildProjectDetails()),
          if (isOwner) ...[
            SliverToBoxAdapter(child: _buildTabBar()),
            SliverFillRemaining(child: _buildTabBarView()),
          ] else ...[
            SliverToBoxAdapter(child: _buildProviderActions()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
      bottomNavigationBar: isProvider && !widget.project.hasUserOffered! 
          ? _buildMakeOfferButton() 
          : null,
    );
  }

  Widget _buildAppBar(BuildContext context, bool isProvider) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF6366F1),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        if (isProvider) ...[
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : Colors.white,
            ),
          ),
        ],
        IconButton(
          onPressed: _shareProject,
          icon: const Icon(Icons.share, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        title: Text(
          'Détails du projet',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        titlePadding: EdgeInsets.only(left: 16, bottom: 16),
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
                  color: const Color(0xFF6366F1).withOpacity(0.1),
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
                        Icons.priority_high,
                        color: _getUrgencyColor(),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.project.urgencyLabel,
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
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.euro,
                label: widget.project.budgetDisplay,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.location_on,
                label: widget.project.location,
                color: Colors.blue,
              ),
            ],
          ),
          if (widget.project.remotePossible) ...[
            const SizedBox(height: 8),
            _buildInfoChip(
              icon: Icons.computer,
              label: 'Télétravail possible',
              color: Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetails() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Description',
            child: Text(
              widget.project.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (widget.project.requiredSkills.isNotEmpty) ...[
            _buildSection(
              title: 'Compétences requises',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.project.requiredSkills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: skill.isRequired 
                          ? const Color(0xFF6366F1).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: skill.isRequired 
                            ? const Color(0xFF6366F1).withOpacity(0.3)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (skill.isRequired) ...[
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          skill.name,
                          style: TextStyle(
                            color: skill.isRequired 
                                ? const Color(0xFF6366F1)
                                : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          _buildSection(
            title: 'Informations projet',
            child: Column(
              children: [
                _buildDetailRow('Client', widget.project.clientName),
                _buildDetailRow('Publié', widget.project.timeSincePosted ?? 'Récemment'),
                _buildDetailRow('Vues', '${widget.project.viewsCount}'),
                _buildDetailRow('Offres reçues', '${widget.project.offersCount}'),
                if (widget.project.deadline != null) ...[
                  _buildDetailRow(
                    'Date limite',
                    '${widget.project.deadline!.day}/${widget.project.deadline!.month}/${widget.project.deadline!.year}',
                  ),
                ],
              ],
            ),
          ),
          if (widget.project.hasAttachments) ...[
            const SizedBox(height: 24),
            _buildSection(
              title: 'Fichiers joints',
              child: Column(
                children: [
                  if (widget.project.attachment1 != null)
                    _buildAttachmentTile('Document 1', widget.project.attachment1!),
                  if (widget.project.attachment2 != null)
                    _buildAttachmentTile('Document 2', widget.project.attachment2!),
                  if (widget.project.attachment3 != null)
                    _buildAttachmentTile('Document 3', widget.project.attachment3!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(String name, String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
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
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF6366F1),
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

  Widget _buildProviderActions() {
    if (widget.project.hasUserOffered!) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Vous avez déjà envoyé une offre pour ce projet',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMakeOfferButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _makeOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Proposer une offre',
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
      case 'very_high':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final newFavoriteStatus = await apiService.toggleProjectFavorite(widget.project.id);
      
      setState(() {
        _isFavorited = newFavoriteStatus;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newFavoriteStatus ? 'Projet ajouté aux favoris' : 'Projet retiré des favoris'
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _shareProject() {
    // TODO: Implémenter le partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
    );
  }

  void _makeOffer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MakeOfferScreen(project: widget.project),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          // Marquer que l'utilisateur a fait une offre
          widget.project.hasUserOffered == true;
        });
        _loadOffers(); // Recharger les offres si c'est le propriétaire
      }
    });
  }

  Future<void> _handleOfferAction(ProjectOffer offer, String action) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.updateOfferStatus(offer.id, action);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'accepted' ? 'Offre acceptée' : 'Offre rejetée'
          ),
          backgroundColor: action == 'accepted' ? Colors.green : Colors.orange,
        ),
      );
      
      _loadOffers(); // Recharger les offres
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Impossible d\'ouvrir le fichier';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ouverture du fichier: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}