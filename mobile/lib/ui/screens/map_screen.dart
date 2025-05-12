// lib/ui/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/provider_list_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/models/provider_model.dart';

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
      if (!success) {
        setState(() {
          _errorMessage = locationService.errorMessage;
          _isLoading = false;
        });
        return;
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
              snippet: provider.businessType,
              onTap: () {
                _navigateToProviderDetail(provider.id);
              },
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

  void _navigateToProviderDetail(int providerId) {
    Navigator.pushNamed(
      context,
      '/provider-detail',
      arguments: providerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestataires à proximité'),
        elevation: 0,
      ),
      body: _buildContent(locationService),
    );
  }

  Widget _buildContent(LocationService locationService) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
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

    if (locationService.currentPosition == null) {
      return const Center(
        child: Text('Position non disponible'),
      );
    }

    final currentPosition = LatLng(
      locationService.currentPosition!.latitude,
      locationService.currentPosition!.longitude,
    );
    
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: currentPosition,
            zoom: 14,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
        if (_markers.isEmpty)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              child: const Text(
                'Aucun prestataire trouvé à proximité',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}