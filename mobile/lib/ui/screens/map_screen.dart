// lib/ui/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/provider_list_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/models/provider_model.dart';
import '../widgets/loading_indicator.dart';

class MapScreen extends StatefulWidget {
  final int? categoryId;

  const MapScreen({Key? key, this.categoryId}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String _errorMessage = '';
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Récupérer la position actuelle via le service de localisation
      final locationService = Provider.of<LocationService>(context, listen: false);
      bool locationAvailable = await locationService.checkLocationServices();
      
      if (!locationAvailable) {
        setState(() {
          _errorMessage = 'Les services de localisation ne sont pas disponibles';
          _isLoading = false;
        });
        return;
      }
      
      bool success = await locationService.getCurrentLocation();
      if (success && locationService.currentPosition != null) {
        _currentPosition = LatLng(
          locationService.currentPosition!.latitude,
          locationService.currentPosition!.longitude,
        );
      } else {
        // Position par défaut (Cotonou, Bénin)
        _currentPosition = const LatLng(6.3728, 2.3905);
      }

      // Charger les prestataires (filtrer par catégorie si categoryId est spécifié)
      final providerListProvider = Provider.of<ProviderListProvider>(context, listen: false);
      if (widget.categoryId != null) {
        await providerListProvider.fetchProvidersByCategory(widget.categoryId!);
      } else {
        await providerListProvider.fetchProviders();
      }

      // Créer les marqueurs pour chaque prestataire
      _createMarkers(providerListProvider.providers);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: $e';
        _isLoading = false;
      });
    }
  }

  void _createMarkers(List<ProviderModel> providers) {
    _markers.clear();
    
    for (var provider in providers) {
      // Vérifier si les coordonnées sont valides
      if (provider.latitude != null && provider.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('provider_${provider.id}'),
            position: LatLng(provider.latitude!, provider.longitude!),
            infoWindow: InfoWindow(
              title: provider.name,
              snippet: '${provider.businessType} • ${provider.rating.toStringAsFixed(1)}⭐',
              onTap: () {
                _showProviderDetails(provider);
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              provider.businessType == 'Entreprise' 
                ? BitmapDescriptor.hueBlue 
                : BitmapDescriptor.hueOrange
            ),
          ),
        );
      }
    }
    
    // Mettre à jour l'état pour rafraîchir la carte
    if (mounted) {
      setState(() {});
    }
  }

  void _showProviderDetails(ProviderModel provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Provider info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: provider.profileImageUrl.isNotEmpty
                              ? NetworkImage(provider.profileImageUrl)
                              : null,
                          child: provider.profileImageUrl.isEmpty
                              ? Text(
                                  provider.name.isNotEmpty ? provider.name[0] : 'P',
                                  style: const TextStyle(fontSize: 24),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                provider.businessType,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    provider.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${provider.reviewCount} avis)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    if (provider.description.isNotEmpty) ...[
                      Text(
                        provider.description,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Services
                    if (provider.services.isNotEmpty) ...[
                      const Text(
                        'Services proposés',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...provider.services.take(3).map((service) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, 
                                 color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                service.title,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (provider.services.length > 3)
                        Text(
                          '+${provider.services.length - 3} autres services',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Address
                    if (provider.address != null) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on, 
                               color: Colors.grey[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.address!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                '/provider-detail',
                                arguments: provider.id,
                              );
                            },
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Voir le profil'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Naviguer vers la messagerie
                              Navigator.pushNamed(
                                context,
                                '/chat',
                                arguments: provider.id,
                              );
                            },
                            icon: const Icon(Icons.message),
                            label: const Text('Contacter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF142FE2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryId != null 
            ? 'Prestataires - Catégorie' 
            : 'Prestataires à proximité'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return const Center(
        child: Text('Position non disponible'),
      );
    }
    
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition!,
            zoom: 12,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: (LatLng position) {
            // Fermer les info windows si l'utilisateur tape sur la carte
          },
        ),
        
        // Overlay d'information
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, 
                     color: const Color(0xFF142FE2), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _markers.isEmpty 
                        ? 'Aucun prestataire trouvé dans cette zone'
                        : '${_markers.length} prestataire(s) trouvé(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}