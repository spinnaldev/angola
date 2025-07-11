import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import ajouté
import 'package:teyago/providers/quote_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/provider_detail_provider.dart';
import '../../providers/review_provider.dart';
import '../widgets/rating_stars.dart';
import '../widgets/review_card.dart';
import 'disputes/create_dispute_screen.dart';
import '../../core/models/review.dart';

class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;
  final int providerId;
  const ServiceDetailScreen({
    Key? key,
    required this.serviceId,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isQuoteRequestOpen = false;
  bool _isReviewFormOpen = false;

  // Contrôleurs pour le formulaire de demande de devis
  final _subjectController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Contrôleurs pour le formulaire d'avis
  final _reviewController = TextEditingController();
  int _rating = 0;
  List<File> _selectedReviewImages = [];
  bool _isSubmittingReview = false;
  bool _isSubmittingQuote = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les données
    _loadData();
  }

  Future<void> _loadData() async {
    print("Load data");
    print(widget.serviceId);
    print(widget.providerId);
    // Charger les détails du service
    await Provider.of<ServiceProvider>(context, listen: false)
        .fetchServiceDetails(widget.serviceId);

    // Une fois le service chargé, récupérer les détails du prestataire
    final service =
        Provider.of<ServiceProvider>(context, listen: false).currentService;

    if (service != null) {
      await Provider.of<ProviderDetailProvider>(context, listen: false)
          .fetchProviderDetails(service.provider_id);

      // Charger les avis
      await Provider.of<ReviewProvider>(context, listen: false)
          .fetchProviderReviews(service.provider_id);
      print("Le prestataire");
      print(service.provider_id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    _reviewController.dispose();
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
      _rating = 0;
      _reviewController.clear();
      _selectedReviewImages = [];
    });
  }

  Future<void> _submitQuoteRequest(int providerId, int serviceId) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Validation des champs
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterRequestSubject)),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.describeYourRequest)),
      );
      return;
    }

    try {
      setState(() {
        _isSubmittingQuote = true;
      });

      // Convertir le budget en double s'il est présent
      double? budget;
      if (_budgetController.text.isNotEmpty) {
        budget = double.tryParse(_budgetController.text);
      }

      // Soumettre la demande de devis via le provider
      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      final success = await quoteProvider.createQuoteRequest(
        providerId,
        _subjectController.text,
        budget ?? 0,
        _descriptionController.text,
      );

      if (success && mounted) {
        // Réinitialiser les champs et fermer le formulaire
        _subjectController.clear();
        _budgetController.clear();
        _descriptionController.clear();
        _closeQuoteRequestForm();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.quoteRequestSentSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quoteProvider.errorMessage ?? l10n.errorSendingQuoteRequest),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorSendingQuoteRequest}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingQuote = false;
        });
      }
    }
  }

  Future<void> _submitReview(int providerId, int serviceId) async {
    final l10n = AppLocalizations.of(context)!;
    
    print('Submitting review for providerId: $providerId');
    print('Submitting review for serviceId: $serviceId');

    // Validation des champs
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseGiveRating)),
      );
      return;
    }

    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseWriteComment)),
      );
      return;
    }

    try {
      setState(() {
        _isSubmittingReview = true;
      });

      // Soumettre l'avis via le provider
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final success = await reviewProvider.createReview(
        providerId,
        _rating,
        _reviewController.text,
        _selectedReviewImages,
        serviceId,
      );

      if (success && mounted) {
        // Réinitialiser les champs et fermer le formulaire
        _rating = 0;
        _reviewController.clear();
        _selectedReviewImages = [];
        _closeReviewForm();

        // Recharger les avis
        await reviewProvider.fetchProviderReviews(providerId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reviewSentSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reviewProvider.errorMessage ?? l10n.errorSendingReview),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorSendingReview}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
    }
  }

  Future<void> _pickReviewImage() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Logique pour sélectionner une image depuis la galerie
    // Cette fonction serait implémentée avec ImagePicker
    // Pour l'instant, c'est une simulation
    setState(() {
      // _selectedReviewImages.add(File('[Chemin de l\'image]'));
      // Montrer un message indiquant que la fonctionnalité n'est pas implémentée
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addImageFeatureNotImplemented)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.providerProfile,
          style: const TextStyle(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image du service avec photo de profil du prestataire
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Image du service
                      Container(
                        height: 180,
                        width: double.infinity,
                        child: service.imageUrl.isNotEmpty
                            ? Image.network(
                                service.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported,
                                          size: 50, color: Colors.grey),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image,
                                      size: 50, color: Colors.grey),
                                ),
                              ),
                      ),

                      // Photo de profil du prestataire (à cheval sur l'image et la zone suivante)
                      Positioned(
                        left: 16,
                        bottom: -30,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: provider.profileImageUrl.isNotEmpty
                                ? NetworkImage(provider.profileImageUrl)
                                : null,
                            child: provider.profileImageUrl.isEmpty
                                ? Text(
                                    provider.name.isNotEmpty
                                        ? provider.name.substring(0, 1)
                                        : "P",
                                    style: const TextStyle(fontSize: 24),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Espace pour tenir compte de l'avatar qui déborde
                  const SizedBox(height: 40),

                  // Nom du service et informations sur l'entreprise
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.businessType,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Note et avis
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF142FE2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${provider.rating}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "(${provider.reviewCount} ${l10n.reviews})",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        // Prix du service si disponible
                        if (service.price > 0 && service.priceType != 'quote')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "${l10n.price}: ${service.price.toStringAsFixed(0)} AOA (${_getPriceTypeLabel(service.priceType, l10n)})",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF142FE2),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "${l10n.price}: ${l10n.onQuotePrice}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF142FE2),
                              ),
                            ),
                          ),

                        // Buttons row
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Bouton signaler un problème
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateDisputeScreen(
                                        providerId: provider.id,
                                        serviceId: service.id,
                                      ),
                                    ),
                                  );
                                },
                                icon:
                                    const Icon(Icons.report_problem, size: 16),
                                label: Text(l10n.reportProblem),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Bouton demander un devis
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _openQuoteRequestForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF142FE2),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  l10n.requestQuote,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // TabBar
                  const SizedBox(height: 16),
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
                      tabs: [
                        Tab(text: l10n.presentation),
                        Tab(text: l10n.evaluations),
                        Tab(text: l10n.gallery),
                      ],
                    ),
                  ),

                  // Contenu des tabs
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab Présentation
                        _buildPresentationTab(service, provider, l10n),

                        // Tab Évaluations
                        _buildEvaluationsTab(provider, l10n),

                        // Tab Galerie
                        _buildGalleryTab(service, l10n),
                      ],
                    ),
                  ),
                ],
              ),

              // Modal de demande de devis
              if (_isQuoteRequestOpen)
                _buildQuoteRequestModal(provider, service, l10n),

              // Modal d'ajout d'avis
              if (_isReviewFormOpen)
                _buildReviewFormModal(provider, service.id, widget.providerId, l10n),
            ],
          );
        },
      ),
    );
  }

  String _getPriceTypeLabel(String priceType, AppLocalizations l10n) {
    switch (priceType) {
      case 'fixed':
        return l10n.fixedPrice;
      case 'hourly':
        return l10n.hourlyPrice;
      case 'daily':
        return l10n.dailyPrice;
      case 'negotiable':
        return l10n.negotiablePrice;
      case 'quote':
      default:
        return l10n.onQuotePrice;
    }
  }

  Widget _buildPresentationTab(service, provider, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section À propos
          Text(
            l10n.about,
            style: const TextStyle(
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
              service.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section Services proposés
          Text(
            l10n.servicesOffered,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF142FE2),
            ),
          ),
          const SizedBox(height: 8),

          // Liste des services
          ...service.options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      option.name,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (option.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (option.price != null && option.price! > 0)
                    Text(
                      '${option.price!.toStringAsFixed(0)} AOA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF142FE2),
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

  Widget _buildEvaluationsTab(provider, AppLocalizations l10n) {
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
                  Text(
                    l10n.verifiedEvaluations,
                    style: const TextStyle(
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
                    child: Text(l10n.writeReview),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Liste des avis
              if (reviewProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (reviews.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.noReviewsForService,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...reviews
                    .map(
                      (review) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage:
                                      review.userImageUrl.isNotEmpty
                                          ? NetworkImage(review.userImageUrl)
                                          : null,
                                  child: review.userImageUrl.isEmpty
                                      ? Text(
                                          review.userName.isNotEmpty
                                              ? review.userName[0]
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        review.date.toString().substring(0, 10),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < review.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: index < review.rating
                                          ? Colors.amber
                                          : Colors.grey,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(review.comment),

                            // Images d'avis (si présentes)
                            if (review.imageUrls.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: review.imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              review.imageUrls[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryTab(service, AppLocalizations l10n) {
    final List<String> galleryImages;

    if (service.galleryImages != null && service.galleryImages.isNotEmpty) {
      galleryImages = service.galleryImages
          .map<String>((img) => img.imageUrl as String)
          .toList();
    } else {
      // Fallback to using the main service image
      galleryImages = [service.imageUrl];
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: galleryImages.isEmpty
          ? Center(
              child: Text(
                l10n.noImagesAvailable,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: galleryImages.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    // Option pour afficher l'image en plein écran
                    _showFullScreenImage(context, galleryImages[index]);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      galleryImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(80),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white, size: 100),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteRequestModal(provider, service, AppLocalizations l10n) {
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
                Center(
                  child: Text(
                    l10n.requestQuoteFor(service.title),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Formulaire
                Text(
                  l10n.requestSubject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: l10n.requestSubjectHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  l10n.yourBudgetOptional,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _budgetController,
                  decoration: InputDecoration(
                    hintText: l10n.budgetHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixText: 'AOA',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),
                Text(
                  l10n.yourRequest,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: l10n.requestDescriptionHint,
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
                    onPressed: _isSubmittingQuote
                        ? null
                        : () => _submitQuoteRequest(provider.id, service.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF142FE2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSubmittingQuote
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            l10n.send,
                            style: const TextStyle(
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

  Widget _buildReviewFormModal(provider, int serviceId, providerId, AppLocalizations l10n) {
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
                    Center(
                      child: Text(
                        l10n.whatIsYourRating,
                        style: const TextStyle(
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
                    Text(
                      l10n.shareYourOpinion,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reviewController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: l10n.yourReview,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickReviewImage,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(l10n.addPhotos),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    // Affichage des images sélectionnées
                    if (_selectedReviewImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedReviewImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image:
                                      FileImage(_selectedReviewImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmittingReview
                            ? null
                            : () => _submitReview(providerId, serviceId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF142FE2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isSubmittingReview
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.sendReview,
                                style: const TextStyle(
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
