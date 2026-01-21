import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/provider_list_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/provider_model.dart';
import '../../core/models/user.dart';
import '../../core/services/api_service.dart';

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

class _MapFilterScreenState extends State<MapFilterScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String _errorMessage = '';
  LatLng? _currentPosition;
  bool _showListView = false;
  
  // Listes pour les deux types d'utilisateurs
  List<ProviderModel> _allProviders = [];
  List<ProviderModel> _filteredProviders = [];
  List<User> _allClients = [];
  List<User> _filteredClients = [];
  
  ProviderModel? _selectedProvider;
  User? _selectedClient;
  
  // Déterminer le rôle de l'utilisateur
  bool _isProvider = false;
  
  // Contrôleurs d'animation
  late AnimationController _bottomSheetController;
  late AnimationController _fabController;
  late Animation<double> _bottomSheetAnimation;
  late Animation<double> _fabAnimation;

  // Filtres
  double _radiusFilter = 15.0;
  double _minRatingFilter = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkUserRole();
    _loadDataWithLocation();
  }

  void _checkUserRole() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _isProvider = authProvider.currentUser?.role == 'provider';
    print('🔍 Rôle utilisateur: ${_isProvider ? "PRESTATAIRE" : "CLIENT"}');
  }

  void _initAnimations() {
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _bottomSheetAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bottomSheetController,
      curve: Curves.easeInOut,
    ));
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    ));

    _fabController.forward();
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    _fabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDataWithLocation() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _updateCurrentLocation();
      
      // Charger selon le rôle
      if (_isProvider) {
        await _loadClients();
      } else {
        await _loadProviders();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement: $e';
          _isLoading = false;
        });
      }
      print('Erreur MapFilterScreen: $e');
    }
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      if (locationProvider.currentPosition != null) {
        _currentPosition = LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
        return;
      }

      bool locationServicesEnabled = await locationProvider.checkLocationServices();
      
      if (locationServicesEnabled) {
        bool permissionGranted = await locationProvider.requestLocationPermission();
        
        if (permissionGranted) {
          bool locationSuccess = await locationProvider.getCurrentLocation();
          
          if (locationSuccess && locationProvider.currentPosition != null) {
            _currentPosition = LatLng(
              locationProvider.currentPosition!.latitude,
              locationProvider.currentPosition!.longitude,
            );
          }
        }
      }
      
      _currentPosition ??= const LatLng(6.3728, 2.3905);
      
    } catch (e) {
      print('Erreur localisation: $e');
      _currentPosition = const LatLng(6.3728, 2.3905);
    }
  }

  // Charger les PRESTATAIRES (pour les clients)
  Future<void> _loadProviders() async {
    if (!mounted) return;
    
    final providerListProvider = Provider.of<ProviderListProvider>(context, listen: false);
    
    try {
      if (widget.categoryId != null) {
        await providerListProvider.fetchProvidersByCategory(widget.categoryId!);
      } else if (_currentPosition != null) {
        await providerListProvider.fetchNearbyProviders(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          radius: 70.0,
        );
      } else {
        await providerListProvider.fetchProviders();
      }

      _allProviders = List.from(providerListProvider.providers);
      _applyFilters();
      
    } catch (e) {
      print('Erreur chargement prestataires: $e');
      _allProviders = [];
      _filteredProviders = [];
    }
  }

  // Charger les CLIENTS (pour les prestataires)
  Future<void> _loadClients() async {
    if (!mounted) return;
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    try {
      if (_currentPosition != null) {
        _allClients = await apiService.getNearbyClients(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radius: 70.0,
        );
      } else {
        _allClients = [];
      }

      _applyFilters();
      
    } catch (e) {
      print('Erreur chargement clients: $e');
      _allClients = [];
      _filteredClients = [];
    }
  }

  void _applyFilters() {
    if (!mounted) return;

    if (_isProvider) {
      // Filtrer les CLIENTS
      List<User> filtered = List.from(_allClients);

      if (_currentPosition != null) {
        filtered = filtered.where((client) {
          if (client.latitude == null || client.longitude == null) return false;
          
          double distance = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            client.latitude!,
            client.longitude!,
          );
          
          return distance <= _radiusFilter;
        }).toList();
      }

      _filteredClients = filtered;
      _createClientMarkers(_filteredClients);
      
    } else {
      // Filtrer les PRESTATAIRES
      List<ProviderModel> filtered = List.from(_allProviders);

      if (_minRatingFilter > 0) {
        filtered = filtered.where((provider) => provider.rating >= _minRatingFilter).toList();
      }

      if (_currentPosition != null) {
        filtered = filtered.where((provider) {
          if (provider.latitude == null || provider.longitude == null) return false;
          
          double distance = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            provider.latitude!,
            provider.longitude!,
          );
          
          return distance <= _radiusFilter;
        }).toList();
      }

      _filteredProviders = filtered;
      _createProviderMarkers(_filteredProviders);
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Créer les marqueurs pour les PRESTATAIRES
  void _createProviderMarkers(List<ProviderModel> providers) {
    _markers.clear();
    
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: AppLocalizations.of(context)!.yourPosition,
          ),
        ),
      );
    }
    
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
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }
  }

  // Créer les marqueurs pour les CLIENTS
  void _createClientMarkers(List<User> clients) {
    _markers.clear();
    
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: AppLocalizations.of(context)!.yourPosition,
          ),
        ),
      );
    }
    
    for (var client in clients) {
      if (client.latitude != null && client.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('client_${client.id}'),
            position: LatLng(client.latitude!, client.longitude!),
            infoWindow: InfoWindow(
              title: client.fullName,
              snippet: client.location ?? '',
            ),
            onTap: () => _showClientBottomSheet(client),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
    }
  }

  void _showProviderBottomSheet(ProviderModel provider) {
    setState(() {
      _selectedProvider = provider;
      _selectedClient = null;
    });
    _bottomSheetController.forward();
  }

  void _showClientBottomSheet(User client) {
    setState(() {
      _selectedClient = client;
      _selectedProvider = null;
    });
    _bottomSheetController.forward();
  }

  void _hideBottomSheet() {
    _bottomSheetController.reverse();
    setState(() {
      _selectedProvider = null;
      _selectedClient = null;
    });
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersBottomSheet(),
    );
  }

  Widget _buildFiltersBottomSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.filters,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _radiusFilter = 15.0;
                          _minRatingFilter = 0.0;
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.reset),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.searchRadius}: ${_radiusFilter.toInt()} km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Slider(
                        value: _radiusFilter,
                        min: 1.0,
                        max: 70.0,
                        divisions: 69,
                        activeColor: const Color(0xFF142FE2),
                        onChanged: (value) {
                          setModalState(() {
                            _radiusFilter = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Note minimum (seulement pour les clients qui voient les prestataires)
                      if (!_isProvider) ...[
                        Text(
                          '${AppLocalizations.of(context)!.minimumRating}: ${_minRatingFilter.toStringAsFixed(1)} ⭐',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Slider(
                          value: _minRatingFilter,
                          min: 0.0,
                          max: 5.0,
                          divisions: 10,
                          activeColor: const Color(0xFF142FE2),
                          onChanged: (value) {
                            setModalState(() {
                              _minRatingFilter = value;
                            });
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isProvider
                                    ? 'Rayon: ${_radiusFilter.toInt()}km'
                                    : 'Rayon: ${_radiusFilter.toInt()}km, Note min: ${_minRatingFilter.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
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
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF142FE2),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.applyFilters),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF142FE2),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chargement de la carte...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDataWithLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF142FE2),
                            ),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition ?? const LatLng(6.3728, 2.3905),
                        zoom: 13.0,
                      ),
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onTap: (_) => _hideBottomSheet(),
                    ),

          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _fabAnimation,
                    child: FloatingActionButton(
                      heroTag: "back",
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      onPressed: widget.onClose,
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        _isProvider
                            ? l10n.clientsFound(_filteredClients.length)
                            : l10n.providersFound(_filteredProviders.length),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  ScaleTransition(
                    scale: _fabAnimation,
                    child: FloatingActionButton(
                      heroTag: "location",
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF142FE2),
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        await _updateCurrentLocation();
                        if (_isProvider) {
                          await _loadClients();
                        } else {
                          await _loadProviders();
                        }
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  ScaleTransition(
                    scale: _fabAnimation,
                    child: FloatingActionButton(
                      heroTag: "filters",
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF142FE2),
                      onPressed: _showFiltersBottomSheet,
                      child: const Icon(Icons.tune),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  ScaleTransition(
                    scale: _fabAnimation,
                    child: FloatingActionButton(
                      heroTag: "list",
                      mini: true,
                      backgroundColor: const Color(0xFF142FE2),
                      foregroundColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _showListView = !_showListView;
                        });
                      },
                      child: Icon(_showListView ? Icons.map : Icons.list),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet pour prestataire
          if (_selectedProvider != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _bottomSheetAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      200 * (1 - _bottomSheetAnimation.value),
                    ),
                    child: _buildProviderBottomSheet(_selectedProvider!),
                  );
                },
              ),
            ),

          // Bottom sheet pour client
          if (_selectedClient != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _bottomSheetAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      200 * (1 - _bottomSheetAnimation.value),
                    ),
                    child: _buildClientBottomSheet(_selectedClient!),
                  );
                },
              ),
            ),

          // Vue liste
          if (_showListView && !_isLoading)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              bottom: 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _isProvider
                            ? l10n.clientsFound(_filteredClients.length)
                            : l10n.providersFound(_filteredProviders.length),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: (_isProvider ? _filteredClients.isEmpty : _filteredProviders.isEmpty)
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isProvider ? l10n.noClientsFound : l10n.noProvidersFound,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _isProvider ? _filteredClients.length : _filteredProviders.length,
                              itemBuilder: (context, index) {
                                if (_isProvider) {
                                  return _buildClientListItem(_filteredClients[index]);
                                } else {
                                  return _buildProviderListItem(_filteredProviders[index]);
                                }
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProviderBottomSheet(ProviderModel provider) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: provider.profileImageUrl.isNotEmpty
                    ? NetworkImage(provider.profileImageUrl)
                    : null,
                child: provider.profileImageUrl.isEmpty
                    ? Text(provider.name[0].toUpperCase())
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
                          const Icon(Icons.verified, color: Colors.green, size: 20),
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${provider.reviewCount} ${l10n.reviews})',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (provider.description.isNotEmpty)
            Text(
              provider.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (provider.latitude != null && provider.longitude != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(provider.latitude!, provider.longitude!),
                          15.0,
                        ),
                      );
                    }
                    _hideBottomSheet();
                  },
                  child: Text(l10n.viewOnMap),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/provider-detail',
                      arguments: provider.id,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF142FE2),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.viewProfile),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientBottomSheet(User client) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: client.profilePicture != null && client.profilePicture!.isNotEmpty
                    ? NetworkImage(client.profilePicture!)
                    : null,
                child: client.profilePicture == null || client.profilePicture!.isEmpty
                    ? Text(client.fullName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (client.location != null)
                      Text(
                        client.location!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (client.bio != null && client.bio!.isNotEmpty)
            Text(
              client.bio!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
          
          const SizedBox(height: 16),
          
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigation vers chat avec le client
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142FE2),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(l10n.contact),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderListItem(ProviderModel provider) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: provider.profileImageUrl.isNotEmpty
            ? NetworkImage(provider.profileImageUrl)
            : null,
        child: provider.profileImageUrl.isEmpty
            ? Text(provider.name[0].toUpperCase())
            : null,
      ),
      title: Row(
        children: [
          Expanded(child: Text(provider.name)),
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
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text('${provider.rating.toStringAsFixed(1)} (${provider.reviewCount})'),
            ],
          ),
        ],
      ),
      onTap: () => _showProviderBottomSheet(provider),
    );
  }

  Widget _buildClientListItem(User client) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: client.profilePicture != null && client.profilePicture!.isNotEmpty
            ? NetworkImage(client.profilePicture!)
            : null,
        child: client.profilePicture == null || client.profilePicture!.isEmpty
            ? Text(client.fullName[0].toUpperCase())
            : null,
      ),
      title: Text(client.fullName),
      subtitle: client.location != null ? Text(client.location!) : null,
      onTap: () => _showClientBottomSheet(client),
    );
  }
}