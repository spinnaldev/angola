// lib/ui/screens/provider_detail_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:teyago/providers/favorites_provider.dart';
import 'package:teyago/providers/messaging_provider.dart';
import 'package:teyago/providers/quote_provider.dart';
import 'package:teyago/ui/screens/messaging/conversation_detail_screen.dart';
import 'package:teyago/ui/screens/service_detail_screen.dart';
import '../../core/models/provider_model.dart';
import '../../core/models/service.dart';
import '../../core/models/review.dart';
import '../../core/services/api_service.dart';
import '../../providers/provider_detail_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../widgets/review_form.dart';
import '../widgets/quote_request_form.dart';
import '../widgets/review_card.dart';
import '../widgets/rating_stars.dart';

class ProviderDetailScreen extends StatefulWidget {
  final int providerId;
  
  const ProviderDetailScreen({
    Key? key,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isQuoteRequestOpen = false;
  bool _isReviewFormOpen = false;
  bool _isLoading = true;
  List<Service> _providerServices = [];
  List<Review> _providerReviews = [];
  bool _isLoadingReviews = true;
  
  final _subjectController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reviewController = TextEditingController();
  final _titleController = TextEditingController();
  int _rating = 0;
  List<File> _selectedReviewImages = [];
  bool _isSubmittingReview = false;
  bool _isSubmittingQuote = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    print('🔍 ProviderDetailScreen initState pour providerId: ${widget.providerId}');
    
    // Charger les données dès l'initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProviderData(widget.providerId);

      // ✅ AJOUTÉ : Charger les favoris
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<FavoritesProvider>(context, listen: false).loadAllFavorites();
      }
    });
  }

  Future<void> _loadProviderData(int providerId) async {
    print('📥 _loadProviderData pour providerId: $providerId');
    
    try {
      final providerDetailProvider = Provider.of<ProviderDetailProvider>(context, listen: false);
      await providerDetailProvider.fetchProviderDetails(providerId);
      
      print('✅ Prestataire chargé: ${providerDetailProvider.currentProvider?.name}');

      // ✅ CHARGEMENT DES SERVICES
      final apiService = Provider.of<ApiService>(context, listen: false);
      final services = await apiService.getProviderServices(providerId);
      
      print('✅ Services chargés: ${services.length}');

      // ✅ NOUVEAU : CHARGEMENT DES AVIS DU PRESTATAIRE
      await _loadProviderReviews(providerId);

      if (mounted) {
        setState(() {
          _providerServices = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ NOUVELLE MÉTHODE : Charger tous les avis du prestataire
  Future<void> _loadProviderReviews(int providerId) async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      print('⭐ Chargement des avis du prestataire $providerId...');
      
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      await reviewProvider.fetchProviderReviews(providerId);
      
      final reviews = reviewProvider.reviews;
      
      print('✅ ${reviews.length} avis chargés avec succès');
      
      if (mounted) {
        setState(() {
          _providerReviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des avis: $e');
      if (mounted) {
        setState(() {
          _providerReviews = [];
          _isLoadingReviews = false;
        });
      }
    }
  }

  void _toggleFavorite() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    // Vérifier l'authentification
    if (!authProvider.isAuthenticated) {
      _checkAuthAndExecute(context, () {});
      return;
    }

    final user = authProvider.currentUser;
    
    // Seuls les clients peuvent ajouter aux favoris
    if (user?.role == 'provider') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seuls les clients peuvent ajouter des prestataires aux favoris'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('🔍 Toggle favori pour prestataire ${widget.providerId}');

    favoritesProvider.toggleProviderFavorite(widget.providerId).then((isNowFavorite) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowFavorite 
                ? 'Prestataire ajouté aux favoris ❤️' 
                : 'Prestataire retiré des favoris'
            ),
            backgroundColor: isNowFavorite ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        print('❌ Erreur toggle: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    _reviewController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndExecute(BuildContext context, VoidCallback action) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      action();
    } else {
      final result = await Navigator.pushNamed(context, '/login');
      if (result == true) {
        action();
      }
    }
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
    // ✅ AJOUTÉ : Recharger les avis après avoir fermé le formulaire
    _loadProviderReviews(widget.providerId);
  }

  void _onReviewFormPressed() {
    _checkAuthAndExecute(context, () {
      _openReviewForm();
    });
  }

  void _onReportPressed() {
    _checkAuthAndExecute(context, () {
      print("Signaler un problème");
    });
  }

  int _getCompletedJobs(ProviderModel provider) {
    try {
      return (provider as dynamic).completedJobs ?? 0;
    } catch (e) {
      return 0;
    }
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
        actions: [
          Consumer2<AuthProvider, FavoritesProvider>(
            builder: (context, authProvider, favoritesProvider, _) {
              // Ne pas afficher si non connecté
              if (!authProvider.isAuthenticated) {
                return SizedBox.shrink();
              }

              final user = authProvider.currentUser;
              
              // Cacher pour les prestataires (ils ne peuvent pas ajouter d'autres prestataires en favoris)
              if (user?.role == 'provider') {
                return SizedBox.shrink();
              }

              // Vérifier si le prestataire est en favoris
              final isFavorite = favoritesProvider.isProviderFavorite(widget.providerId);
              
              return IconButton(
                onPressed: () => _toggleFavorite(),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                tooltip: isFavorite 
                  ? 'Retirer ce prestataire des favoris' 
                  : 'Ajouter ce prestataire aux favoris',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ProviderDetailProvider>(
        builder: (context, providerDetailProvider, _) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final provider = providerDetailProvider.currentProvider;
          if (provider == null) {
            return const Center(child: Text('Prestataire non trouvé'));
          }

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image du prestataire avec photo de profil débordante
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Image principale
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: const Color(0xFF142FE2),
                        child: provider.profileImageUrl.isNotEmpty
                            ? Image.network(
                                provider.profileImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.business,
                                      size: 80,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.business,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                      ),

                      // Photo de profil débordante À GAUCHE
                      Positioned(
                        left: 16,
                        bottom: -30,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF142FE2).withOpacity(0.1),
                            backgroundImage: provider.profileImageUrl.isNotEmpty
                                ? NetworkImage(provider.profileImageUrl)
                                : null,
                            child: provider.profileImageUrl.isEmpty
                                ? Text(
                                    provider.name.isNotEmpty
                                        ? provider.name.substring(0, 1).toUpperCase()
                                        : "P",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF142FE2),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Espace pour l'avatar qui déborde
                  const SizedBox(height: 40),

                  // Nom du prestataire et informations
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom avec badge vérifié
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (provider.isVerified)
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF142FE2),
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // Type d'entreprise
                        Text(
                          _getBusinessType(provider, l10n),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Statistiques
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            // Note
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF142FE2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    provider.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Nombre d'avis
                            Text(
                              '(${provider.reviewCount} ${l10n.reviews})',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            
                            // Projets complétés
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${_getCompletedJobs(provider)} ${l10n.completedProjects}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Boutons d'action
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _onReportPressed,
                                icon: const Icon(Icons.report_problem, size: 16, color: Colors.orange),
                                label: Text(
                                  l10n.reportProblem,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon( // ✅ CHANGÉ en ElevatedButton.icon pour avoir une icône
                                onPressed: () => _checkAuthAndExecute(context, _contactProvider),
                                icon: const Icon(Icons.message, size: 18), // ✅ AJOUT icône message
                                label: Text(
                                  l10n.contactProvider, // ✅ CHANGÉ le texte
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF142FE2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

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
                        _buildPresentationTab(provider, l10n),
                        _buildEvaluationsTab(provider, l10n),
                        _buildGalleryTab(provider, l10n),
                      ],
                    ),
                  ),
                ],
              ),

              // Modals
              if (_isQuoteRequestOpen)
                QuoteRequestForm(
                  providerId: provider.id,
                  onClose: _closeQuoteRequestForm,
                ),

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
  Future<void> _contactProvider() async {
    final provider = Provider.of<ProviderDetailProvider>(context, listen: false).currentProvider;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(context, listen: false);
    
    if (provider == null) return;
    
    // Vérifier l'authentification
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour contacter ce prestataire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    print('📱 Ouverture conversation avec ${provider.name}');
    
    try {
      // Afficher un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // ✅ Créer ou récupérer la conversation avec ce prestataire
      final conversation = await messagingProvider.getOrCreateConversation(provider.id);
      
      // Fermer le loader
      if (mounted) Navigator.pop(context);
      
      if (conversation != null && mounted) {
        // ✅ Navigation vers la conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversationId: conversation.id,
              otherPerson: conversation.otherPerson,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la conversation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ouverture du chat: $e');
      
      // Fermer le loader si encore ouvert
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitQuoteRequest(int providerId) async {
    final l10n = AppLocalizations.of(context)!;
    
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

      double budget = 0.0;
      if (_budgetController.text.isNotEmpty) {
        String cleanBudgetText = _budgetController.text
            .replaceAll(RegExp(r'[^\d.]'), '')
            .trim();
        
        if (cleanBudgetText.isNotEmpty) {
          final parsedBudget = double.tryParse(cleanBudgetText);
          if (parsedBudget != null && parsedBudget >= 0) {
            budget = parsedBudget;
          }
        }
      }

      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      final success = await quoteProvider.createQuoteRequest(
        providerId,
        _subjectController.text,
        budget,
        _descriptionController.text,
      );

      if (success && mounted) {
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

  Future<void> _submitReview(int providerId) async {
    final l10n = AppLocalizations.of(context)!;

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

      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      final success = await reviewProvider.createReview(
        providerId,
        _rating,
        _reviewController.text,
        _titleController.text.trim(),
        _selectedReviewImages,
        null, // Pas de serviceId spécifique
      );

      if (success && mounted) {
        _rating = 0;
        _reviewController.clear();
        _titleController.clear();
        _selectedReviewImages = [];
        _closeReviewForm();

        await _loadProviderReviews(providerId);

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
    
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addImageFeatureNotImplemented)),
      );
    });
  }
  String _getBusinessType(ProviderModel provider, AppLocalizations l10n) {
    switch (provider.businessType.toLowerCase()) {
      case 'entreprise':
      case 'company':
        return l10n.company;
      case 'freelance':
      case 'freelancer':
        return l10n.freelance;
      case 'particulier':
      case 'individual':
        return l10n.individual;
      default:
        return provider.businessType.isNotEmpty ? provider.businessType : l10n.unknown;
    }
  }

  Widget _buildPresentationTab(ProviderModel provider, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Biographie
          Text(
            l10n.providerBio,
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
              provider.description.isNotEmpty
                  ? provider.description
                  : l10n.noDescriptionAvailable,
              style: const TextStyle(fontSize: 14, height: 1.5),
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

          if (_providerServices.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  l10n.noServicesListed,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            // ✅ DESIGN AMÉLIORÉ - Cards plus grandes avec description
            ..._providerServices.map((service) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  print('🔍 Navigation vers service ${service.id} du prestataire ${provider.id}');
                  
                  // ✅ CORRECTION : Importer ServiceDetailScreen en haut du fichier
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailScreen(
                        serviceId: service.id,
                        providerId: provider.id,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Partie gauche: Titre + Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre du service
                            Text(
                              service.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Description du service
                            if (service.description.isNotEmpty)
                              Text(
                                service.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Partie droite: Prix + Flèche
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            service.priceType == 'quote'
                                ? 'Sur devis'
                                : '${service.price.toStringAsFixed(0)} AOA',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF142FE2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF142FE2).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: const Color(0xFF142FE2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )),
        ],
      ),
    );
  }

  // ✅ CORRIGÉ : Affichage des avis chargés depuis l'API
  Widget _buildEvaluationsTab(ProviderModel provider, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              // TextButton(
              //   onPressed: _onReviewFormPressed,
              //   child: Text(l10n.writeReview),
              // ),
            ],
          ),
          const SizedBox(height: 16),
          
          // ✅ AFFICHAGE DES AVIS
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_providerReviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined, 
                      size: 64, 
                      color: Colors.grey[400]
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noReviewsYet,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.beFirstToReview,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // ✅ LISTE DES AVIS
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _providerReviews.length,
              itemBuilder: (context, index) {
                final review = _providerReviews[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom du client et date
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF142FE2),
                              child: Text(
                                review.clientName.isNotEmpty 
                                  ? review.clientName[0].toUpperCase()
                                  : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.clientName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(review.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Note avec étoiles
                        RatingStars(
                          rating: review.rating,
                          size: 18,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Titre de l'avis (si disponible)
                        if (review.reviewTitle != null && review.reviewTitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              review.reviewTitle!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        
                        // Commentaire
                        Text(
                          review.comment,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        
                        // Images de l'avis (si disponibles)
                        if (review.imageUrls.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: review.imageUrls.length,
                                itemBuilder: (context, imgIndex) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          review.imageUrls[imgIndex]
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ✅ Méthode utilitaire pour formater la date avec traductions
  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return l10n.today;
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays); // ✅ CORRIGÉ : Passer directement l'int
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      if (weeks == 1) {
        return l10n.weeksAgo(weeks); // ✅ CORRIGÉ : Passer l'int, pas le String
      } else {
        return l10n.weeksAgoPlural(weeks); // ✅ CORRIGÉ
      }
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      if (months == 1) {
        return l10n.monthsAgo(months); // ✅ CORRIGÉ : Passer directement l'int
      } else {
        return l10n.monthsAgoPlural(months); // ✅ CORRIGÉ
      }
    } else {
      final years = (difference.inDays / 365).floor();
      if (years == 1) {
        return l10n.yearsAgo(years); // ✅ CORRIGÉ
      } else {
        return l10n.yearsAgoPlural(years); // ✅ CORRIGÉ
      }
    }
  }

  // ✅ GALERIE : Toutes les images de tous les services
  Widget _buildGalleryTab(ProviderModel provider, AppLocalizations l10n) {
    // ✅ Récupérer TOUTES les images de TOUS les services
    List<String> allImages = [];
    for (var service in _providerServices) {
      if (service.galleryImages != null && service.galleryImages.isNotEmpty) {
        allImages.addAll(
          service.galleryImages.map<String>((img) => img.imageUrl as String),
        );
      }
      
      // ✅ AJOUT : Ajouter aussi l'image principale du service si elle existe
      if (service.imageUrl != null && service.imageUrl!.isNotEmpty) {
        allImages.add(service.imageUrl!);
      }
    }

    print('📸 Total images dans la galerie: ${allImages.length}');

    if (allImages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.noImagesAvailable,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // ✅ BONUS : Ouvrir l'image en plein écran
            _showImageFullScreen(context, allImages, index);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              allImages[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ✅ BONUS : Voir l'image en plein écran
  void _showImageFullScreen(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      images[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}