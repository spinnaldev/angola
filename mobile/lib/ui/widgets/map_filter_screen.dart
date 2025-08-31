// // lib/ui/widgets/map_filter_screen.dart
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:provider/provider.dart';
// import '../../providers/provider_list_provider.dart';
// import '../../providers/location_provider.dart';
// import '../../core/models/provider_model.dart';
// import '../widgets/loading_indicator.dart';

// class MapFilterScreen extends StatefulWidget {
//   final VoidCallback onClose;
//   final int? categoryId;

//   const MapFilterScreen({
//     Key? key, 
//     required this.onClose,
//     this.categoryId,
//   }) : super(key: key);

//   @override
//   _MapFilterScreenState createState() => _MapFilterScreenState();
// }

// class _MapFilterScreenState extends State<MapFilterScreen> {
//   GoogleMapController? _mapController;
//   final Set<Marker> _markers = {};
//   bool _isLoading = true;
//   String _errorMessage = '';
//   LatLng? _currentPosition;
//   bool _showListView = false;
//   List<ProviderModel> _providers = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       // Récupérer la position actuelle
//       final locationProvider = Provider.of<LocationProvider>(context, listen: false);
//       bool locationAvailable = await locationProvider.checkLocationServices();
      
//       if (locationAvailable) {
//         bool success = await locationProvider.getCurrentLocation();
//         if (success && locationProvider.currentPosition != null) {
//           _currentPosition = LatLng(
//             locationProvider.currentPosition!.latitude,
//             locationProvider.currentPosition!.longitude,
//           );
//         }
//       }
      
//       // Position par défaut si la géolocalisation échoue (Cotonou, Bénin)
//       _currentPosition ??= const LatLng(6.3728, 2.3905);

//       // Charger les prestataires
//       final providerListProvider = Provider.of<ProviderListProvider>(context, listen: false);
      
//       if (widget.categoryId != null) {
//         await providerListProvider.fetchProvidersByCategory(widget.categoryId!);
//       } else {
//         // Essayer de récupérer les prestataires à proximité
//         if (locationProvider.currentPosition != null) {
//           await providerListProvider.fetchNearbyProviders(
//             locationProvider.currentPosition!.latitude,
//             locationProvider.currentPosition!.longitude,
//             radius: 10.0, // 10 km de rayon
//           );
//         } else {
//           await providerListProvider.fetchProviders();
//         }
//       }

//       _providers = providerListProvider.providers;
//       _createMarkers(_providers);

//       setState(() {
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Erreur lors du chargement: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   void _createMarkers(List<ProviderModel> providers) {
//     _markers.clear();
    
//     for (var provider in providers) {
//       if (provider.latitude != null && provider.longitude != null) {
//         _markers.add(
//           Marker(
//             markerId: MarkerId('provider_${provider.id}'),
//             position: LatLng(provider.latitude!, provider.longitude!),
//             infoWindow: InfoWindow(
//               title: provider.name,
//               snippet: '${provider.businessType} • ${provider.rating.toStringAsFixed(1)}⭐',
//             ),
//             onTap: () => _showProviderBottomSheet(provider),
//             icon: BitmapDescriptor.defaultMarkerWithHue(
//               provider.isVerified 
//                 ? BitmapDescriptor.hueGreen
//                 : provider.businessType == 'Entreprise' 
//                   ? BitmapDescriptor.hueBlue 
//                   : BitmapDescriptor.hueOrange
//             ),
//           ),
//         );
//       }
//     }
    
//     if (mounted) {
//       setState(() {});
//     }
//   }

//   void _showProviderBottomSheet(ProviderModel provider) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.4,
//         minChildSize: 0.3,
//         maxChildSize: 0.8,
//         builder: (context, scrollController) {
//           return Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             ),
//             child: SingleChildScrollView(
//               controller: scrollController,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Handle bar
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Provider header
//                     Row(
//                       children: [
//                         CircleAvatar(
//                           radius: 30,
//                           backgroundImage: provider.profileImageUrl.isNotEmpty
//                               ? NetworkImage(provider.profileImageUrl)
//                               : null,
//                           child: provider.profileImageUrl.isEmpty
//                               ? Text(
//                                   provider.name.isNotEmpty ? provider.name[0] : 'P',
//                                   style: const TextStyle(fontSize: 24),
//                                 )
//                               : null,
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       provider.name,
//                                       style: const TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                   if (provider.isVerified)
//                                     const Icon(
//                                       Icons.verified,
//                                       color: Colors.green,
//                                       size: 20,
//                                     ),
//                                 ],
//                               ),
//                               Text(
//                                 provider.businessType,
//                                 style: TextStyle(
//                                   color: Colors.grey[600],
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               Row(
//                                 children: [
//                                   const Icon(Icons.star, color: Colors.amber, size: 16),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     provider.rating.toStringAsFixed(1),
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     '(${provider.reviewCount} avis)',
//                                     style: TextStyle(
//                                       color: Colors.grey[600],
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
                    
//                     const SizedBox(height: 16),
                    
//                     // Description
//                     if (provider.description.isNotEmpty) ...[
//                       Text(
//                         provider.description,
//                         style: const TextStyle(fontSize: 14),
//                         maxLines: 3,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 16),
//                     ],
                    
//                     // Services
//                     if (provider.services.isNotEmpty) ...[
//                       const Text(
//                         'Services proposés',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       ...provider.services.take(3).map((service) => Padding(
//                         padding: const EdgeInsets.only(bottom: 4),
//                         child: Row(
//                           children: [
//                             Icon(Icons.check_circle, 
//                                  color: Colors.green, size: 16),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 service.title,
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                             ),
//                             Text(
//                               service.priceType == 'quote' 
//                                   ? 'Sur devis' 
//                                   : service.priceType,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       )),
//                       if (provider.services.length > 3)
//                         Text(
//                           '+${provider.services.length - 3} autres services',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 12,
//                           ),
//                         ),
//                       const SizedBox(height: 16),
//                     ],
                    
//                     // Distance et adresse
//                     if (provider.address != null) ...[
//                       Row(
//                         children: [
//                           Icon(Icons.location_on, 
//                                color: Colors.grey[600], size: 16),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               provider.address!,
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                     ],
                    
//                     // Action buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                               Navigator.pushNamed(
//                                 context,
//                                 '/provider-detail',
//                                 arguments: provider.id,
//                               );
//                             },
//                             icon: const Icon(Icons.info_outline),
//                             label: const Text('Voir le profil'),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                               // Naviguer vers la messagerie ou demande de devis
//                             },
//                             icon: const Icon(Icons.message),
//                             label: const Text('Contacter'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF142FE2),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Carte ou liste
//           _showListView ? _buildListView() : _buildMapView(),
          
//           // Header
//           SafeArea(
//             child: Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 8,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back),
//                     onPressed: widget.onClose,
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Text(
//                           'Services à proximité',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           _isLoading 
//                               ? 'Chargement...'
//                               : '${_providers.length} prestataire(s) trouvé(s)',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(_showListView ? Icons.map : Icons.list),
//                     onPressed: () {
//                       setState(() {
//                         _showListView = !_showListView;
//                       });
//                     },
//                     tooltip: _showListView ? 'Vue carte' : 'Vue liste',
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMapView() {
//     if (_isLoading) {
//       return const Center(child: LoadingIndicator());
//     }

//     if (_errorMessage.isNotEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, size: 64, color: Colors.red),
//               const SizedBox(height: 16),
//               Text(
//                 _errorMessage,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: _loadData,
//                 child: const Text('Réessayer'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     if (_currentPosition == null) {
//       return const Center(child: Text('Position non disponible'));
//     }

//     return GoogleMap(
//       initialCameraPosition: CameraPosition(
//         target: _currentPosition!,
//         zoom: 12,
//       ),
//       markers: _markers,
//       myLocationEnabled: true,
//       myLocationButtonEnabled: true,
//       onMapCreated: (controller) {
//         _mapController = controller;
//       },
//     );
//   }

//   Widget _buildListView() {
//     if (_isLoading) {
//       return const Center(child: LoadingIndicator());
//     }

//     if (_providers.isEmpty) {
//       return const Center(
//         child: Text('Aucun prestataire trouvé'),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
//       itemCount: _providers.length,
//       itemBuilder: (context, index) {
//         final provider = _providers[index];
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundImage: provider.profileImageUrl.isNotEmpty
//                   ? NetworkImage(provider.profileImageUrl)
//                   : null,
//               child: provider.profileImageUrl.isEmpty
//                   ? Text(provider.name.isNotEmpty ? provider.name[0] : 'P')
//                   : null,
//             ),
//             title: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     provider.name,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 if (provider.isVerified)
//                   const Icon(Icons.verified, color: Colors.green, size: 16),
//               ],
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(provider.businessType),
//                 Row(
//                   children: [
//                     const Icon(Icons.star, color: Colors.amber, size: 16),
//                     const SizedBox(width: 4),
//                     Text(
//                       provider.rating.toStringAsFixed(1),
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(width: 4),
//                     Text('(${provider.reviewCount})'),
//                   ],
//                 ),
//               ],
//             ),
//             trailing: IconButton(
//               icon: const Icon(Icons.arrow_forward_ios),
//               onPressed: () => _showProviderBottomSheet(provider),
//             ),
//             onTap: () => _showProviderBottomSheet(provider),
//           ),
//         );
//       },
//     );
//   }
// }

// 
// lib/ui/widgets/map_filter_screen.dart - Version améliorée
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/provider_list_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/models/provider_model.dart';
import '../../core/models/service.dart';
import '../screens/service_detail_screen.dart';

class MapFilterScreen extends StatefulWidget {
  final VoidCallback onClose;
  final int? categoryId;
  final bool isProviderMode;

  const MapFilterScreen({
    Key? key, 
    required this.onClose,
    this.categoryId,
    this.isProviderMode = false,
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
  List<ProviderModel> _allProviders = []; // Liste complète
  List<ProviderModel> _filteredProviders = []; // Liste filtrée
  ProviderModel? _selectedProvider;
  
  // Contrôleurs d'animation
  late AnimationController _bottomSheetController;
  late AnimationController _fabController;
  late Animation<double> _bottomSheetAnimation;
  late Animation<double> _fabAnimation;

  // Filtres simplifiés - seulement distance et rating
  double _radiusFilter = 10.0; // km
  double _minRatingFilter = 0.0; // Note minimum (0 à 5)

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadDataWithLocation();
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

  // Méthode améliorée pour charger les données avec localisation
  Future<void> _loadDataWithLocation() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. D'abord récupérer la position actuelle
      await _updateCurrentLocation();
      
      // 2. Puis charger les prestataires
      await _loadProviders();

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

  // Méthode séparée pour mettre à jour la localisation
  Future<void> _updateCurrentLocation() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      // Vérifier si on a déjà une position
      if (locationProvider.currentPosition != null) {
        _currentPosition = LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
        return;
      }

      // Sinon, essayer de récupérer la position
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
      
      // Position par défaut si échec (Cotonou, Bénin)
      _currentPosition ??= const LatLng(6.3728, 2.3905);
      
    } catch (e) {
      print('Erreur lors de la récupération de la localisation: $e');
      _currentPosition = const LatLng(6.3728, 2.3905);
    }
  }

  Future<void> _loadProviders() async {
    if (!mounted) return;
    
    final providerListProvider = Provider.of<ProviderListProvider>(context, listen: false);
    
    try {
      if (widget.categoryId != null) {
        await providerListProvider.fetchProvidersByCategory(widget.categoryId!);
      } else if (_currentPosition != null) {
        // Utiliser un rayon par défaut pour charger tous les prestataires proches
        await providerListProvider.fetchNearbyProviders(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          radius: 50.0, // Rayon plus large pour avoir plus de données
        );
      } else {
        await providerListProvider.fetchProviders();
      }

      _allProviders = List.from(providerListProvider.providers);
      _applyFilters();
      
    } catch (e) {
      print('Erreur lors du chargement des prestataires: $e');
      _allProviders = [];
      _filteredProviders = [];
    }
  }

  void _applyFilters() {
    if (!mounted) return;

    List<ProviderModel> filtered = List.from(_allProviders);

    // Filtre par note minimum
    if (_minRatingFilter > 0) {
      filtered = filtered.where((provider) => provider.rating >= _minRatingFilter).toList();
    }

    // Filtre par distance si on a une position actuelle
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
    _createMarkers(_filteredProviders);
    
    if (mounted) {
      setState(() {});
    }
  }

  // Calcul de distance entre deux points (en km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
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

  void _createMarkers(List<ProviderModel> providers) {
    _markers.clear();
    
    // Marqueur pour la position actuelle
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
    
    // Marqueurs pour les prestataires
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

  void _showProviderBottomSheet(ProviderModel provider) {
    setState(() {
      _selectedProvider = provider;
    });
    _bottomSheetController.forward();
  }

  void _hideProviderBottomSheet() {
    _bottomSheetController.reverse();
    setState(() {
      _selectedProvider = null;
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
          height: MediaQuery.of(context).size.height * 0.5, // Réduit la hauteur
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
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
                          _radiusFilter = 10.0;
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
                      // Rayon de recherche
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
                        max: 50.0,
                        divisions: 49,
                        activeColor: const Color(0xFF142FE2),
                        onChanged: (value) {
                          setModalState(() {
                            _radiusFilter = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Note minimum
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
                        divisions: 10, // Steps de 0.5
                        activeColor: const Color(0xFF142FE2),
                        onChanged: (value) {
                          setModalState(() {
                            _minRatingFilter = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Afficher le nombre de prestataires qui correspondent
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
                                'Rayon: ${_radiusFilter.toInt()}km, Note min: ${_minRatingFilter.toStringAsFixed(1)}',
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
              
              // Bouton appliquer
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters(); // Appliquer les filtres
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
    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps ou état de chargement
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
                            child: Text(AppLocalizations.of(context)!.retry),
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
                      onTap: (_) => _hideProviderBottomSheet(),
                    ),

          // Header avec boutons
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Bouton retour
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
                  
                  // Info sur le nombre de prestataires
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
                        '${_filteredProviders.length} prestataire(s) trouvé(s)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Bouton actualiser localisation
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
                        await _loadProviders();
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Bouton filtres
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
                  
                  // Bouton liste/carte
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

          // Bottom sheet prestataire sélectionné
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

          // Vue liste (optionnelle)
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
                        '${_filteredProviders.length} ${AppLocalizations.of(context)!.providersFound}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredProviders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun prestataire trouvé',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Essayez d\'élargir votre rayon de recherche',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredProviders.length,
                              itemBuilder: (context, index) {
                                final provider = _filteredProviders[index];
                                return _buildProviderListItem(provider);
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
                          '(${provider.reviewCount} avis)',
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
                    // Centrer la carte sur le prestataire
                    if (provider.latitude != null && provider.longitude != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(provider.latitude!, provider.longitude!),
                          15.0,
                        ),
                      );
                    }
                    _hideProviderBottomSheet();
                  },
                  child: Text(AppLocalizations.of(context)!.viewOnMap),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Naviguer vers le détail du prestataire
                    Navigator.pop(context); // Fermer la carte
                    // Ajouter ici navigation vers profil prestataire
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF142FE2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Voir profil'),
                ),
              ),
            ],
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
}