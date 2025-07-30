// lib/ui/screens/improved_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/services/improved_location_service.dart';
import '../../providers/improved_nearby_provider.dart';
import '../../core/models/provider_model.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/provider_bottom_sheet.dart';
import '../widgets/map_filter_widget.dart';
import 'dart:async';

class ImprovedMapScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;

  const ImprovedMapScreen({
    Key? key, 
    this.categoryId,
    this.categoryName,
  }) : super(key: key);

  @override
  _ImprovedMapScreenState createState() => _ImprovedMapScreenState();
}

class _ImprovedMapScreenState extends State<ImprovedMapScreen> 
    with TickerProviderStateMixin {
  
  // Contrôleurs
  GoogleMapController? _mapController;
  late AnimationController _fabAnimationController;
  late AnimationController _filterAnimationController;
  
  // État de la carte
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  bool _isMapReady = false;
  bool _showUserLocation = true;
  bool _showSearchRadius = false;
  
  // État de l'interface
  bool _showFilters = false;
  ProviderModel? _selectedProvider;
  
  // Animation
  late Animation<double> _fabAnimation;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeMap();
  }

  void _initAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));

    _filterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeMap() async {
    print('🗺️ Initialisation de la carte...');
    
    final locationService = Provider.of<ImprovedLocationService>(context, listen: false);
    final nearbyProvider = Provider.of<ImprovedNearbyProvider>(context, listen: false);

    // Démarrer la récupération de la position
    bool locationSuccess = await locationService.getCurrentLocation();
    
    if (locationSuccess) {
      print('✅ Position récupérée pour la carte');
    } else {
      print('⚠️ Impossible de récupérer la position, utilisation de la position par défaut');
    }

    // Rechercher les prestataires
    await nearbyProvider.searchNearbyProviders(
      categoryId: widget.categoryId,
      forceRefresh: true,
    );

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _filterAnimationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte principale
          _buildMap(),
          
          // Interface utilisateur superposée
          _buildOverlayUI(),
          
          // Feuille de filtre
          if (_showFilters) _buildFilterSheet(),
          
          // Bottom sheet pour le prestataire sélectionné
          if (_selectedProvider != null) _buildProviderBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer2<ImprovedLocationService, ImprovedNearbyProvider>(
      builder: (context, locationService, nearbyProvider, child) {
        LatLng initialPosition = locationService.getCurrentOrDefaultPosition();
        
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14.0,
          ),
          onMapCreated: _onMapCreated,
          markers: _markers,
          circles: _circles,
          myLocationEnabled: _showUserLocation && locationService.hasValidPosition,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          trafficEnabled: false,
          buildingsEnabled: true,
          onTap: _onMapTap,
          style: _getMapStyle(),
        );
      },
    );
  }

  Widget _buildOverlayUI() {
    return SafeArea(
      child: Column(
        children: [
          // Barre d'en-tête
          _buildHeaderBar(),
          
          const Spacer(),
          
          // Boutons d'action flottants
          _buildFloatingActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton retour
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          
          const SizedBox(width: 12),
          
          // Titre et informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName ?? AppLocalizations.of(context)!.viewOnMap,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<ImprovedNearbyProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      '${provider.resultsCount} ${AppLocalizations.of(context)!.providersFound}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Bouton de filtre
          IconButton(
            icon: Icon(
              _showFilters ? Icons.close : Icons.tune,
              color: _showFilters ? Colors.red : Colors.grey[700],
            ),
            onPressed: _toggleFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bouton pour centrer sur la position utilisateur
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: "location",
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              onPressed: _centerOnUserLocation,
              child: Consumer<ImprovedLocationService>(
                builder: (context, locationService, child) {
                  if (locationService.isLoading) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return const Icon(Icons.my_location);
                },
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Bouton pour basculer l'affichage du rayon de recherche
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: "radius",
              mini: true,
              backgroundColor: _showSearchRadius ? Colors.blue : Colors.white,
              foregroundColor: _showSearchRadius ? Colors.white : Colors.blue,
              onPressed: _toggleSearchRadius,
              child: const Icon(Icons.radio_button_checked),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Bouton pour actualiser
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: "refresh",
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              onPressed: _refreshMap,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSheet() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_filterAnimation),
      child: Container(
        margin: const EdgeInsets.only(top: 120),
        child: MapFilterWidget(
          onFiltersChanged: _onFiltersChanged,
          onClose: _toggleFilters,
        ),
      ),
    );
  }

  Widget _buildProviderBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ProviderBottomSheet(
            provider: _selectedProvider!,
            scrollController: scrollController,
            onClose: () {
              setState(() {
                _selectedProvider = null;
              });
            },
          ),
        );
      },
    );
  }

  // Méthodes de gestion de la carte
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    _updateMapMarkers();
    print('✅ Carte Google Maps créée');
  }

  void _onMapTap(LatLng position) {
    if (_selectedProvider != null) {
      setState(() {
        _selectedProvider = null;
      });
    }
  }

  void _updateMapMarkers() {
    if (!_isMapReady) return;

    final nearbyProvider = Provider.of<ImprovedNearbyProvider>(context, listen: false);
    
    setState(() {
      _markers.clear();
      _circles.clear();
      
      // Ajouter les marqueurs pour les prestataires
      for (var provider in nearbyProvider.nearbyProviders) {
        if (provider.latitude != null && provider.longitude != null) {
          _markers.add(_createProviderMarker(provider));
        }
      }
      
      // Ajouter le cercle de rayon de recherche si activé
      if (_showSearchRadius) {
        _addSearchRadiusCircle();
      }
    });
  }

  Marker _createProviderMarker(ProviderModel provider) {
    return Marker(
      markerId: MarkerId('provider_${provider.id}'),
      position: LatLng(provider.latitude!, provider.longitude!),
      infoWindow: InfoWindow(
        title: provider.name,
        snippet: _buildMarkerSnippet(provider),
      ),
      icon: _getMarkerIcon(provider),
      onTap: () => _onMarkerTap(provider),
    );
  }

  String _buildMarkerSnippet(ProviderModel provider) {
    List<String> snippetParts = [];
    
    snippetParts.add(provider.businessType);
    snippetParts.add('${provider.rating.toStringAsFixed(1)}⭐');
    
    if (provider.distance != null) {
      snippetParts.add('${provider.distance!.toStringAsFixed(1)}km');
    }
    
    return snippetParts.join(' • ');
  }

  BitmapDescriptor _getMarkerIcon(ProviderModel provider) {
    if (provider.isVerified) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (provider.businessType == 'Entreprise') {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  void _addSearchRadiusCircle() {
    final locationService = Provider.of<ImprovedLocationService>(context, listen: false);
    final nearbyProvider = Provider.of<ImprovedNearbyProvider>(context, listen: false);
    
    if (locationService.hasValidPosition) {
      _circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center: LatLng(
            locationService.currentPosition!.latitude,
            locationService.currentPosition!.longitude,
          ),
          radius: nearbyProvider.searchRadius * 1000, // Convertir km en mètres
          fillColor: Colors.blue.withOpacity(0.1),
          strokeColor: Colors.blue.withOpacity(0.3),
          strokeWidth: 2,
        ),
      );
    }
  }

  // Méthodes d'interaction
  void _onMarkerTap(ProviderModel provider) {
    setState(() {
      _selectedProvider = provider;
    });
    
    // Centrer la carte sur le marqueur sélectionné
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(provider.latitude!, provider.longitude!),
        16.0,
      ),
    );
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _onFiltersChanged() {
    _updateMapMarkers();
  }

  Future<void> _centerOnUserLocation() async {
    final locationService = Provider.of<ImprovedLocationService>(context, listen: false);
    
    if (!locationService.hasValidPosition) {
      // Essayer de récupérer la position
      bool success = await locationService.getCurrentLocation();
      if (!success) {
        _showLocationError(context);
        return;
      }
    }
    
    final position = locationService.currentPosition!;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        16.0,
      ),
    );
  }

  void _toggleSearchRadius() {
    setState(() {
      _showSearchRadius = !_showSearchRadius;
    });
    _updateMapMarkers();
  }

  Future<void> _refreshMap() async {
    final nearbyProvider = Provider.of<ImprovedNearbyProvider>(context, listen: false);
    await nearbyProvider.refresh();
    _updateMapMarkers();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Carte mise à jour: ${nearbyProvider.resultsCount} prestataires trouvés'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String? _getMapStyle() {
    // Vous pouvez retourner un style JSON personnalisé ici
    return null;
  }

  void _showLocationError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.locationPermission),
        content: Text(AppLocalizations.of(context)!.locationPermissionDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final locationService = Provider.of<ImprovedLocationService>(context, listen: false);
              locationService.openAppSettings();
            },
            child: Text(AppLocalizations.of(context)!.settings),
          ),
        ],
      ),
    );
  }
}