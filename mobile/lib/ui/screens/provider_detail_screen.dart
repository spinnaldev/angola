// lib/ui/screens/provider_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/provider_model.dart';
import '../../../../providers/provider_detail_provider.dart';
import '../widgets/rating_stars.dart';
// import '../../../widgets/review_card.dart';
import '../widgets/review_card.dart';
import '../widgets/quote_request_form.dart';
import '../widgets/review_form.dart';

class ProviderDetailScreen extends StatefulWidget {
  final int providerId;

  const ProviderDetailScreen({
    Key? key,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isQuoteRequestOpen = false;
  bool _isReviewFormOpen = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les détails du prestataire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProviderDetailProvider>(context, listen: false).fetchProviderDetails(widget.providerId);
    });
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
      body: Consumer<ProviderDetailProvider>(
        builder: (context, providerDetailProvider, _) {
          if (providerDetailProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final provider = providerDetailProvider.currentProvider;

          if (provider == null) {
            return const Center(child: Text('Données non disponibles'));
          }

          return Stack(
            children: [
              // Contenu principal
              Column(
                children: [
                  // En-tête avec le titre du profil
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Profil prestataire',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Pour équilibrer avec le bouton retour
                        ],
                      ),
                    ),
                  ),
                  
                  // Image d'en-tête et info prestataire
                  Stack(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        child: provider.profileImageUrl.isNotEmpty
                            ? Image.network(
                                provider.profileImageUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
                              ),
                      ),
                      
                      // Info du prestataire sur l'image
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.black.withOpacity(0.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
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
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        provider.businessType,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF142FE2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          provider.rating.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${provider.reviewCount})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Bouton Demander un devis
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openQuoteRequestForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF142FE2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Demander un devis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // TabBar pour naviguer entre les sections
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF142FE2),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF142FE2),
                    tabs: const [
                      Tab(text: 'Présentation'),
                      Tab(text: 'Évaluations'),
                      Tab(text: 'Galerie'),
                    ],
                  ),
                  
                  // Contenu des tabs
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab Présentation
                        _buildPresentationTab(provider),
                        
                        // Tab Évaluations
                        _buildEvaluationsTab(provider),
                        
                        // Tab Galerie
                        _buildGalleryTab(provider),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Modal de demande de devis (s'affiche par-dessus si _isQuoteRequestOpen est true)
              if (_isQuoteRequestOpen)
                QuoteRequestForm(
                  providerId: provider.id,
                  onClose: _closeQuoteRequestForm,
                ),
              
              // Modal d'ajout d'avis
              if (_isReviewFormOpen)
                ReviewForm(
                  providerId: provider.id,
                  onClose: _closeReviewForm,
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildPresentationTab(ProviderModel provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section À propos
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'À propos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF142FE2),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  provider.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Section Services proposés
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Services proposés',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF142FE2),
                  ),
                ),
                const SizedBox(height: 10),
                ...provider.services.map((service) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service.title,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        service.priceType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEvaluationsTab(ProviderModel provider) {
    // Simuler quelques avis pour l'exemple
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton pour ajouter un avis
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: OutlinedButton.icon(
              onPressed: _openReviewForm,
              icon: const Icon(Icons.rate_review),
              label: const Text('Écrire un avis'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF142FE2),
                side: const BorderSide(color: Color(0xFF142FE2)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          
          // Liste des avis (exemple simplifié)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Évaluations vérifiées',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF142FE2),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Exemple d'avis - utiliser une liste dynamique des avis du prestataire
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/23.jpg'),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hélène Moove',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) => 
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          )
                        ),
                      ),
                      Text(
                        'Juin 5, 2023',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Je tiens à remercier chaleureusement l\'équipe de No:m de Quinto Offie pour leur travail exceptionnel dans la construction de ma maison. Dès le début du projet, ils ont fait preuve d\'un grand professionnalisme, de réactivité et d\'une expertise irréprochable. Le suivi de chantier a été précis et les délais ont été respectés, ce qui est très appréciable.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  isThreeLine: true,
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Écrire un avis'),
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFF142FE2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGalleryTab(ProviderModel provider) {
    // Images d'exemple pour la galerie
    List<String> galleryImages = [
      'https://picsum.photos/id/1018/300/300',
      'https://picsum.photos/id/1015/300/300',
      'https://picsum.photos/id/1019/300/300',
      'https://picsum.photos/id/1020/300/300',
      'https://picsum.photos/id/1021/300/300',
      'https://picsum.photos/id/1022/300/300',
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
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
    );
  }
  
  Widget _buildQuoteRequestModal() {
    final TextEditingController _subjectController = TextEditingController();
    final TextEditingController _budgetController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    
    return GestureDetector(
      onTap: _closeQuoteRequestForm, // Ferme le modal si on clique en dehors
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Empêche la fermeture si on clique sur le modal
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec titre et bouton fermer
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Demander un devis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: _closeQuoteRequestForm,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  
                  // Formulaire
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Objet de demande'),
                        SizedBox(height: 8),
                        TextField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            hintText: 'Objet...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        Text('Votre budget'),
                        SizedBox(height: 8),
                        TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Budget...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        Text('Votre demande'),
                        SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Saisissez une description...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // Logique d'envoi de la demande de devis
                              _closeQuoteRequestForm();
                              // Afficher un message de confirmation
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Demande de devis envoyée')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF142FE2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Envoyer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildReviewFormModal() {
    int _rating = 0;
    final TextEditingController _reviewController = TextEditingController();
    List<Image> _selectedImages = [];
    
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: _closeReviewForm, // Ferme le modal si on clique en dehors
          child: Container(
            color: Colors.black54,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Empêche la fermeture si on clique sur le modal
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header avec titre et bouton fermer
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quelle est votre note ?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: _closeReviewForm,
                            ),
                          ],
                        ),
                      ),
                      
                      // Système de notation avec étoiles
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) => 
                            IconButton(
                              icon: Icon(
                                index < _rating ? Icons.star : Icons.star_border,
                                color: index < _rating ? Colors.amber : Colors.grey,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  _rating = index + 1;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Champ pour le commentaire
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'N\'hésitez pas à partager votre opinion\nà propos du produit',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _reviewController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Votre avis',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Bouton pour ajouter des photos
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                // Logique pour ajouter des photos (simulée pour l'exemple)
                                setState(() {
                                  _selectedImages.add(Image.network('https://picsum.photos/id/1018/300/300'));
                                });
                              },
                              icon: Icon(Icons.camera_alt),
                              label: Text('Ajouter des photos'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // Afficher les miniatures des images sélectionnées
                            ..._selectedImages.map((image) => 
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: image,
                                  ),
                                ),
                              ),
                            ).toList(),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Bouton d'envoi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // Logique d'envoi de l'avis
                              _closeReviewForm();
                              // Afficher un message de confirmation
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Avis envoyé avec succès')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF142FE2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'ENVOYER UN AVIS',
                              style: TextStyle(
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
            ),
          ),
        );
      },
    );
  }
}