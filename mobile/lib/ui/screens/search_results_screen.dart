// Créé ce fichier : lib/ui/screens/search_results_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/models/service.dart';
import '../widgets/service_card.dart';
import 'base_screen.dart';
import 'service_detail_screen.dart';

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      Map<String, dynamic> response;

      if (widget.type == 'services') {
        response = await apiService.searchServices(widget.query);
      } else {
        response = await apiService.searchProjects(widget.query);
      }

      setState(() {
        _results = response['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la recherche: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      currentIndex: widget.type == 'services' ? 1 : 0, // Explorer pour services, Accueil pour projets
      body: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            widget.type == 'services' 
                ? 'Services : "${widget.query}"'
                : 'Projets : "${widget.query}"'
          ),
          backgroundColor: const Color(0xFF142FE2),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildSearchResults(),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche en cours...'),
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
              child: const Text('Réessayer'),
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
                  ? 'Aucun service trouvé pour "${widget.query}"'
                  : 'Aucun projet trouvé pour "${widget.query}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nouvelle recherche'),
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
            '${_results.length} résultat${_results.length > 1 ? 's' : ''} trouvé${_results.length > 1 ? 's' : ''}',
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

  Widget _buildServicesList() {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final serviceData = _results[index];
        // Convertir en objet Service si nécessaire
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildServiceCard(serviceData),
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

  Widget _buildServiceCard(Map<String, dynamic> serviceData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(
                serviceId: serviceData['id'],
                providerId: serviceData['provider_id'] ?? serviceData['provider']?['id'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image du service
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  serviceData['image_url'] ?? serviceData['imageUrl'] ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Détails du service
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceData['title'] ?? 'Service sans nom',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      serviceData['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${serviceData['rating'] ?? 0.0}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          serviceData['price_type'] == 'quote'
                              ? 'Sur devis'
                              : '${serviceData['price'] ?? 0} FCFA',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF142FE2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> projectData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/project-detail',
            arguments: projectData['id'],
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
                      projectData['title'] ?? 'Projet sans nom',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      projectData['status'] ?? 'open',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
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
                  Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    projectData['client_name'] ?? 'Client inconnu',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Spacer(),
                  Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    projectData['budget'] != null
                        ? '${projectData['budget']} FCFA'
                        : 'Sur devis',
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