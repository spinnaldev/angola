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
  List<ProviderModel> _providers = [];
  ProviderModel? _selectedProvider;
  
  // Contrôleurs d'animation
  late AnimationController _bottomSheetController;
  late AnimationController _fabController;
  late Animation<double> _bottomSheetAnimation;
  late Animation<double> _fabAnimation;

  // Filtres
  double _radiusFilter = 10.0; // km
  int _minRatingFilter = 0;
  String _businessTypeFilter = '';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Récupérer la position actuelle
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      if (locationProvider.currentPosition != null) {
        _currentPosition = LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
      } else {
        // Essayer de récupérer la position
        bool success = await locationProvider.getCurrentLocation();
        if (success && locationProvider.currentPosition != null) {
          _currentPosition = LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
        } else {
          // Position par défaut (Cotonou, Bénin)
          _currentPosition = const LatLng(6.3728, 2.3905);
        }
      }

      // Charger les prestataires
      await _loadProviders();

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

  Future<void> _loadProviders() async {
    final providerListProvider = Provider.of<ProviderListProvider>(context, listen: false);
    
    try {
      if (widget.categoryId != null) {
        await providerListProvider.fetchProvidersByCategory(widget.categoryId!);
      } else if (_currentPosition != null) {
        await providerListProvider.fetchNearbyProviders(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          radius: _radiusFilter,
        );
      } else {
        await providerListProvider.fetchProviders();
      }

      _providers = providerListProvider.providers;
      _applyFilters();
      _createMarkers(_providers);
    } catch (e) {
      print('Erreur lors du chargement des prestataires: $e');
    }
  }

  void _applyFilters() {
    List<ProviderModel> filteredProviders = List.from(_providers);

    // Filtre par note
    if (_minRatingFilter > 0) {
      filteredProviders = filteredProviders
          .where((provider) => provider.rating >= _minRatingFilter)
          .toList();
    }

    // Filtre par type d'entreprise
    if (_businessTypeFilter.isNotEmpty) {
      filteredProviders = filteredProviders
          .where((provider) => provider.businessType == _businessTypeFilter)
          .toList();
    }

    _createMarkers(filteredProviders);
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
    
    setState(() {});
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
          height: MediaQuery.of(context).size.height * 0.6,
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
                          _minRatingFilter = 0;
                          _businessTypeFilter = '';
                        });
                        _applyFilters();
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
                      Slider(
                        value: _radiusFilter,
                        min: 1.0,
                        max: 50.0,
                        divisions: 49,
                        onChanged: (value) {
                          setModalState(() {
                            _radiusFilter = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Note minimum
                      Text(
                        AppLocalizations.of(context)!.minimumRating,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(5, (index) {
                          final rating = index + 1;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _minRatingFilter = _minRatingFilter == rating ? 0 : rating;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _minRatingFilter >= rating
                                    ? const Color(0xFF142FE2)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: _minRatingFilter >= rating
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$rating+',
                                    style: TextStyle(
                                      color: _minRatingFilter >= rating
                                          ? Colors.white
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Type d'entreprise
                      Text(
                        AppLocalizations.of(context)!.businessType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: ['Entreprise', 'Freelance', 'Auto-entrepreneur'].map((type) {
                          return ChoiceChip(
                            label: Text(type),
                            selected: _businessTypeFilter == type,
                            onSelected: (selected) {
                              setModalState(() {
                                _businessTypeFilter = selected ? type : '';
                              });
                            },
                            selectedColor: const Color(0xFF142FE2),
                            labelStyle: TextStyle(
                              color: _businessTypeFilter == type
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          );
                        }).toList(),
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
                    _loadProviders();
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
          // Carte Google Maps
          _isLoading
              ? const Center(child: CircularProgressIndicator())
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
                            onPressed: _loadData,
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
                  
                  const Spacer(),
                  
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
                  
                  const SizedBox(width: 10),
                  
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
          if (_showListView)
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
                        '${_providers.length} ${AppLocalizations.of(context)!.providersFound}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _providers.length,
                        itemBuilder: (context, index) {
                          final provider = _providers[index];
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
                    // Naviguer vers le détail (simulé)
                    if (provider.services.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailScreen(
                            serviceId: provider.services.first.id,
                            providerId: provider.id,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF142FE2),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context)!.viewServices),
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