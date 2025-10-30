// lib/ui/screens/provider_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:teyago/providers/favorites_provider.dart';
import '../../core/models/provider_model.dart';
import '../../core/models/service.dart';
import '../../core/services/api_service.dart';
import '../../providers/provider_detail_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/review_form.dart';
import '../widgets/quote_request_form.dart';

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

      final apiService = Provider.of<ApiService>(context, listen: false);
      final services = await apiService.getProviderServices(providerId);
      
      print('✅ Services chargés: ${services.length}');

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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noDataAvailable,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          // DEBUG: Afficher les infos dans la console
          print('👤 Provider: ${provider.name}');
          print('⭐ Rating: ${provider.rating}');
          print('💬 Reviews: ${provider.reviewCount}');
          print('📦 Services: ${_providerServices.length}');

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
                                label: Flexible(
                                  child: Text(
                                    l10n.reportProblem,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                              child: ElevatedButton(
                                onPressed: () => _checkAuthAndExecute(context, _openQuoteRequestForm),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF142FE2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  l10n.requestQuote,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ..._providerServices.map((service) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/service-detail',
                        arguments: {
                          'serviceId': service.id,
                          'providerId': provider.id,
                        },
                      );
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.title,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          service.priceType == 'quote'
                              ? 'Sur devis'
                              : '${service.price.toStringAsFixed(0)} AOA',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFF142FE2),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

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
              TextButton(
                onPressed: _onReviewFormPressed,
                child: Text(l10n.writeReview),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Avis à venir depuis l\'API',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab(ProviderModel provider, AppLocalizations l10n) {
    List<String> allImages = [];
    for (var service in _providerServices) {
      if (service.galleryImages != null) {
        allImages.addAll(
          service.galleryImages.map<String>((img) => img.imageUrl as String),
        );
      }
    }

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
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            allImages[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        );
      },
    );
  }
}