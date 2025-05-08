import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/provider_detail_provider.dart';
import '../../providers/review_provider.dart';
import '../widgets/rating_stars.dart';
import '../widgets/review_card.dart';
import '../widgets/quote_request_form.dart';
import '../widgets/review_form.dart';

class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;

  const ServiceDetailScreen({
    Key? key,
    required this.serviceId,
  }) : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isQuoteRequestOpen = false;
  bool _isReviewFormOpen = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les données
    _loadData();
  }
  
  Future<void> _loadData() async {
    // Charger les détails du service
    await Provider.of<ServiceProvider>(context, listen: false).fetchServiceDetails(widget.serviceId);
    
    // Une fois le service chargé, récupérer les détails du prestataire
    final service = Provider.of<ServiceProvider>(context, listen: false).currentService;
    if (service != null) {
      await Provider.of<ProviderDetailProvider>(context, listen: false).fetchProviderDetails(service.providerId);
      
      // Charger les avis
      await Provider.of<ReviewProvider>(context, listen: false).fetchProviderReviews(service.providerId);
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openQuoteRequestForm() {
    setState(() {
      _isQuoteRequestOpen = true;
    });
  }

  void _closeQuoteRequestForm() {
    setState(() {
      _isQuoteRequestOpen = false;
    });
  }

  void _openReviewForm() {
    setState(() {
      _isReviewFormOpen = true;
    });
  }

  void _closeReviewForm() {
    setState(() {
      _isReviewFormOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Profil prestataire',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer2<ServiceProvider, ProviderDetailProvider>(
        builder: (context, serviceProvider, providerDetailProvider, _) {
          final service = serviceProvider.currentService;
          final provider = providerDetailProvider.currentProvider;

          if (service == null || provider == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // Contenu principal
              Column(
                children: [
                  // Image d'en-tête avec photo de profil et nom du prestataire
                  Stack(
                    children: [
                      // Image du service
                      Container(
                        height: 200,
                        width: double.infinity,
                        child: service.imageUrl.isNotEmpty
                            ? Image.network(
                                service.imageUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
                              ),
                      ),
                      
                      // Superposition pour les informations du prestataire
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Photo de profil du prestataire
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: provider.profileImageUrl.isNotEmpty
                                    ? NetworkImage(provider.profileImageUrl)
                                    : null,
                                child: provider.profileImageUrl.isEmpty
                                    ? Text(
                                        provider.name.substring(0, 1),
                                        style: const TextStyle(fontSize: 20),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              
                              // Informations du prestataire
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      provider.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2.0,
                                            color: Colors.black45,
                                            offset: Offset(1.0, 1.0),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      provider.businessType,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2.0,
                                            color: Colors.black45,
                                            offset: Offset(1.0, 1.0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Titre, note et bouton demander un devis
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Notation avec étoiles et nombre d'avis
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF142FE2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "${provider.rating}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "(${provider.reviewCount} avis)",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Bouton demander un devis
                        ElevatedButton(
                          onPressed: _openQuoteRequestForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF142FE2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: const Text(
                            'Demander un devis',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // TabBar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF142FE2),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF142FE2),
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Présentation'),
                        Tab(text: 'Évaluations'),
                        Tab(text: 'Galerie'),
                      ],
                    ),
                  ),
                  
                  // Contenu des tabs
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab Présentation
                        _buildPresentationTab(service, provider),
                        
                        // Tab Évaluations
                        _buildEvaluationsTab(provider),
                        
                        // Tab Galerie
                        _buildGalleryTab(provider),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Modal de demande de devis
              if (_isQuoteRequestOpen)
                _buildQuoteRequestModal(provider),
              
              // Modal d'ajout d'avis
              if (_isReviewFormOpen)
                _buildReviewFormModal(provider),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildPresentationTab(service, provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section À propos
          const Text(
            'À propos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF142FE2),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              provider.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Section Services proposés
          const Text(
            'Services proposés',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF142FE2),
            ),
          ),
          const SizedBox(height: 8),
          
          // Liste des services
          ...provider.services.map((serviceItem) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      serviceItem.title,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    serviceItem.priceType,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF142FE2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildEvaluationsTab(provider) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.reviews;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et bouton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Évaluations vérifiées',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF142FE2),
                    ),
                  ),
                  TextButton(
                    onPressed: _openReviewForm,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF142FE2),
                    ),
                    child: const Text('Écrire un avis'),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Liste des avis
              if (reviews.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Aucun avis pour ce service',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...reviews.map((review) => ReviewCard(review: review)).toList(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildGalleryTab(provider) {
    // Liste d'images fictives pour l'exemple
    final List<String> galleryImages = [
      'https://picsum.photos/id/1018/300/300',
      'https://picsum.photos/id/1015/300/300',
      'https://picsum.photos/id/1019/300/300',
      'https://picsum.photos/id/1020/300/300',
      'https://picsum.photos/id/1021/300/300',
      'https://picsum.photos/id/1022/300/300',
      'https://picsum.photos/id/1023/300/300',
      'https://picsum.photos/id/1024/300/300',
      'https://picsum.photos/id/1025/300/300',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: galleryImages.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              galleryImages[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildQuoteRequestModal(provider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      color: Colors.black.withOpacity(0.5),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _closeQuoteRequestForm,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Demander un devis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Formulaire
                const Text(
                  'Objet de demande',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Objet...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Votre budget',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Budget...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Votre demande',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Laissez une description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Logique d'envoi
                      _closeQuoteRequestForm();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demande de devis envoyée')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF142FE2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Envoyer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewFormModal(provider) {
    int _rating = 0;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          color: Colors.black.withOpacity(0.5),
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _closeReviewForm,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Quelle est votre note ?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Système de notation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: index < _rating ? Colors.amber : Colors.grey,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 16),
                    const Text(
                      'N\'hésitez pas à partager votre opinion\nà propos du produit',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Votre avis',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Logique pour ajouter des photos
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Ajouter des photos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Logique d'envoi
                          _closeReviewForm();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Avis envoyé avec succès')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF142FE2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'ENVOYER UN AVIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}