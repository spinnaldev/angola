// Créé ce fichier : lib/ui/screens/search_results_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/services/api_service.dart';
import '../../core/models/service.dart';
import '../../core/models/client_project.dart';
import '../widgets/service_card.dart'; // ✅ IMPORTÉ
import 'base_screen.dart';
import 'service_detail_screen.dart';
import 'project_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String type; // 'services' ou 'projects'

  const SearchResultsScreen({
    Key? key,
    required this.query,
    required this.type,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<dynamic> _results = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Démarrage recherche: "${widget.query}" (type: ${widget.type})');

      final apiService = Provider.of<ApiService>(context, listen: false);
      Map<String, dynamic> response;

      if (widget.type == 'services') {
        response = await apiService.searchServices(widget.query);
      } else {
        response = await apiService.searchProjects(widget.query);
      }

      // Debug des résultats
      print('📊 Réponse API: ${response.keys}');
      print('📊 Nombre de résultats: ${response['results']?.length ?? 0}');

      setState(() {
        _results = response['results'] ?? [];
        _isLoading = false;
      });

      // Log final avec détails des ratings
      if (_results.isEmpty) {
        print('⚠️ Aucun résultat trouvé pour "${widget.query}"');
      } else {
        print('✅ ${_results.length} résultat(s) trouvé(s)');
        if (widget.type == 'services' && _results.isNotEmpty) {
          print('🔍 Exemple de données reçues:');
          final firstResult = _results[0];
          print('   avg_rating: ${firstResult['avg_rating']}');
          print('   review_count: ${firstResult['review_count']}');
        }
      }
    } catch (e) {
      print('❌ Erreur complète dans _performSearch: $e');
      setState(() {
        _errorMessage = '${l10n.searchError}: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ✅ SIMPLIFIÉE : Utiliser directement fromJson() du modèle Service
  // Le modèle Service a déjà toutes les protections nécessaires
  Service _mapToService(Map<String, dynamic> data) {
    // La méthode fromJson() du modèle Service gère déjà :
    // - Le parsing de avg_rating et review_count
    // - La protection contre les valeurs null
    // - Les conversions de types
    // - Les valeurs par défaut
    return Service.fromJson(data);
  }

  // Helper method to convert Map to ClientProject
  ClientProject _mapToClientProject(Map<String, dynamic> data) {
    return ClientProject(
      id: data['id'] ?? 0,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      clientName: data['client_name'] ?? '',
      categoryName: data['category_name'] ?? '',
      subcategoryName: data['subcategory_name'],
      budgetRange: data['budget_range'] ?? '',
      minBudget: data['min_budget']?.toDouble(),
      maxBudget: data['max_budget']?.toDouble(),
      budgetDisplay: data['budget_display'] ?? '',
      location: data['location'] ?? '',
      remotePossible: data['remote_possible'] ?? false,
      deadline:
          data['deadline'] != null ? DateTime.tryParse(data['deadline']) : null,
      urgency: data['urgency'] ?? 'normal',
      status: data['status'] ?? 'open',
      contactViaPlatform: data['contact_via_platform'] ?? true,
      showEmail: data['show_email'] ?? false,
      showPhone: data['show_phone'] ?? false,
      requiredSkills: data['required_skills'] != null
          ? List<String>.from(data['required_skills'])
          : [],
      offersCount: data['offers_count'] ?? 0,
      viewsCount: data['views_count'] ?? 0,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
          : DateTime.now(),
      timeSincePosted: data['time_since_posted'],
      isFavorited: data['is_favorited'],
      hasUserOffered: data['has_user_offered'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      currentIndex: widget.type == 'services'
          ? 1
          : 0, // Explorer pour services, Accueil pour projets
      body: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.type == 'services'
              ? l10n.servicesSearchTitle(widget.query)
              : l10n.projectsSearchTitle(widget.query)),
          backgroundColor: const Color(0xFF142FE2),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildSearchResults(),
      ),
    );
  }

  Widget _buildSearchResults() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.searchInProgress),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.type == 'services' ? Icons.search_off : Icons.work_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.type == 'services'
                  ? l10n.noServiceFound(widget.query)
                  : l10n.noProjectFound(widget.query),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.newSearch),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _results.length == 1
                ? l10n.resultFound(_results.length)
                : l10n.resultsFound(_results.length),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.type == 'services'
                ? _buildServicesList()
                : _buildProjectsList(),
          ),
        ],
      ),
    );
  }

  // ✅ MODIFIÉ : Utiliser ServiceCard au lieu de carte custom
  Widget _buildServicesList() {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final serviceData = _results[index];
        
        // ✅ Convertir les données en objet Service
        final service = _mapToService(serviceData);
        
        // ✅ Utiliser le widget ServiceCard existant
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ServiceCard(
            service: service,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(
                    serviceId: service.id,
                    providerId: service.provider_id,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProjectsList() {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final projectData = _results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildProjectCard(projectData),
        );
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> projectData) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Convert Map to ClientProject before passing
          final project = _mapToClientProject(projectData);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(projectId: project.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      projectData['title'] ?? l10n.projectWithoutName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (projectData['status'] ?? 'open') == 'open'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (projectData['status'] ?? 'open') == 'open'
                          ? l10n.open
                          : l10n.closed,
                      style: TextStyle(
                        fontSize: 12,
                        color: (projectData['status'] ?? 'open') == 'open'
                            ? Colors.green
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                projectData['description'] ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    projectData['client_name'] ?? l10n.unknownClient,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Spacer(),
                  const Icon(Icons.account_balance_wallet,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    projectData['budget'] != null
                        ? '${projectData['budget']} AOA'
                        : l10n.onQuotePrice,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}