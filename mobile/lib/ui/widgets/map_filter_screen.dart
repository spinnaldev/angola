// lib/ui/widgets/map_filter_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/provider_list_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/models/provider_model.dart';
import '../widgets/loading_indicator.dart';

class MapFilterScreen extends StatefulWidget {
  final VoidCallback onClose;
  final int? categoryId;

  const MapFilterScreen({
    Key? key, 
    required this.onClose,
    this.categoryId,
  }) : super(key: key);

  @override
  _MapFilterScreenState createState() => _MapFilterScreenState();
}

class _MapFilterScreenState extends State<MapFilterScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String _errorMessage = '';
  LatLng? _currentPosition;
  bool _showListView = false;
  List<ProviderModel> _providers = [];

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
      // Récupérer la position actuelle
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      bool locationAvailable = await locationProvider.checkLocationServices();
      
      if (locationAvailable) {
        bool success = await locationProvider.getCurrentLocation();
        if (success && locationProvider.currentPosition != null) {
          _currentPosition = LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
        }
      }
      
      // Position par défaut si la géolocalisation échoue (Cotonou, Bénin)
      _currentPosition ??= const LatLng(6.3728, 2.3905);

      // Charger les prestataires
      final providerListProvider = Provider.of<ProviderListProvider>(context, listen: false);
      
      if (widget.categoryId != null) {
        await providerListProvider.fetchProvidersByCategory(widget.categoryId!);
      } else {
        // Essayer de récupérer les prestataires à proximité
        if (locationProvider.currentPosition != null) {
          await providerListProvider.fetchNearbyProviders(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
            radius: 10.0, // 10 km de rayon
          );
        } else {
          await providerListProvider.fetchProviders();
        }
      }

      _providers = providerListProvider.providers;
      _createMarkers(_providers);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  void _createMarkers(List<ProviderModel> providers) {
    _markers.clear();
    
    for (var provider in providers) {
      if (provider.latitude != null && provider.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('provider_${provider.id}'),
            position: LatLng(provider.latitude!, provider.longitude!),
            infoWindow: InfoWindow(
              title: provider.name,
              snippet: '${provider.businessType} • ${provider.rating.toStringAsFixed(1)}⭐',
            ),
            onTap: () => _showProviderBottomSheet(provider),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              provider.isVerified 
                ? BitmapDescriptor.hueGreen
                : provider.businessType == 'Entreprise' 
                  ? BitmapDescriptor.hueBlue 
                  : BitmapDescriptor.hueOrange
            ),
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _showProviderBottomSheet(ProviderModel provider) {
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
                    
                    // Provider header
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      provider.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (provider.isVerified)
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                ],
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
                            Text(
                              service.priceType == 'quote' 
                                  ? 'Sur devis' 
                                  : service.priceType,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
                    
                    // Distance et adresse
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
                              // Naviguer vers la messagerie ou demande de devis
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
      body: Stack(
        children: [
          // Carte ou liste
          _showListView ? _buildListView() : _buildMapView(),
          
          // Header
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Services à proximité',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isLoading 
                              ? 'Chargement...'
                              : '${_providers.length} prestataire(s) trouvé(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_showListView ? Icons.map : Icons.list),
                    onPressed: () {
                      setState(() {
                        _showListView = !_showListView;
                      });
                    },
                    tooltip: _showListView ? 'Vue carte' : 'Vue liste',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
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
      return const Center(child: Text('Position non disponible'));
    }

    return GoogleMap(
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
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_providers.isEmpty) {
      return const Center(
        child: Text('Aucun prestataire trouvé'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: provider.profileImageUrl.isNotEmpty
                  ? NetworkImage(provider.profileImageUrl)
                  : null,
              child: provider.profileImageUrl.isEmpty
                  ? Text(provider.name.isNotEmpty ? provider.name[0] : 'P')
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    provider.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (provider.isVerified)
                  const Icon(Icons.verified, color: Colors.green, size: 16),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.businessType),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      provider.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text('(${provider.reviewCount})'),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => _showProviderBottomSheet(provider),
            ),
            onTap: () => _showProviderBottomSheet(provider),
          ),
        );
      },
    );
  }
}