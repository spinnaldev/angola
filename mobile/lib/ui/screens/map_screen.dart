// lib/ui/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/models/provider_model.dart';
import '../../core/models/user.dart';
import '../../core/services/improved_location_service.dart';
import '../../core/services/api_service.dart';
import '../../providers/auth_provider.dart';
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
  bool _isProvider = false;
  List<ProviderModel> _providers = [];
  List<User> _clients = [];

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
      // Vérifier le rôle de l'utilisateur
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _isProvider = authProvider.currentUser?.role == 'provider';
      
      // Récupérer la position
      final locationService = Provider.of<ImprovedLocationService>(context, listen: false);
      // bool locationAvailable = await locationService.checkLocationServices();
      
      // if (!locationAvailable) {
      //   setState(() {
      //     _errorMessage = AppLocalizations.of(context)!.locationServicesNotAvailable;
      //     _isLoading = false;
      //   });
      //   return;
      // }
      
      bool success = await locationService.getCurrentLocation();
      if (success && locationService.currentPosition != null) {
        _currentPosition = LatLng(
          locationService.currentPosition!.latitude,
          locationService.currentPosition!.longitude,
        );
      } else {
        _currentPosition = const LatLng(6.3728, 2.3905);
      }

      // Récupérer les données selon le rôle
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      if (_isProvider) {
        // PRESTATAIRE → voir les CLIENTS
        _clients = await apiService.getNearbyClients(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radius: 10,
        );
        _createClientMarkers(_clients);
      } else {
        // CLIENT → voir les PRESTATAIRES
        if (widget.categoryId != null) {
          _providers = await apiService.getProvidersByCategory(widget.categoryId!);
        } else {
          _providers = await apiService.getNearbyProviders(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            radius: 10,
          );
        }
        _createProviderMarkers(_providers);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.loadingDataError(e.toString());
        _isLoading = false;
      });
    }
  }

  void _createProviderMarkers(List<ProviderModel> providers) {
    _markers.clear();
    
    for (var provider in providers) {
      if (provider.latitude != null && provider.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('provider_${provider.id}'),
            position: LatLng(provider.latitude!, provider.longitude!),
            infoWindow: InfoWindow(
              title: provider.name,
              snippet: provider.distance != null
                  ? '${provider.distance!.toStringAsFixed(1)} km • ${provider.rating.toStringAsFixed(1)}⭐'
                  : '${provider.businessType} • ${provider.rating.toStringAsFixed(1)}⭐',
              onTap: () => _showProviderDetails(provider),
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
    
    if (mounted) setState(() {});
  }

  void _createClientMarkers(List<User> clients) {
    _markers.clear();
    
    for (var client in clients) {
      if (client.latitude != null && client.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('client_${client.id}'),
            position: LatLng(client.latitude!, client.longitude!),
            infoWindow: InfoWindow(
              title: client.fullName,
              snippet: client.location ?? '',
              onTap: () => _showClientDetails(client),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
    }
    
    if (mounted) setState(() {});
  }

  void _showProviderDetails(ProviderModel provider) {
    final l10n = AppLocalizations.of(context)!;
    
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
                    
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: provider.profileImageUrl.isNotEmpty
                              ? NetworkImage(provider.profileImageUrl)
                              : null,
                          child: provider.profileImageUrl.isEmpty
                              ? Text(provider.name.isNotEmpty ? provider.name[0] : 'P',
                                  style: const TextStyle(fontSize: 24))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(provider.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(provider.businessType,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(provider.rating.toStringAsFixed(1),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text('(${provider.reviewCount} ${l10n.reviews})',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (provider.description.isNotEmpty) ...[
                      Text(provider.description, style: const TextStyle(fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 16),
                    ],
                    
                    if (provider.services.isNotEmpty) ...[
                      Text(l10n.servicesOffered, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...provider.services.take(3).map((service) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(service.title, style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                      )),
                      if (provider.services.length > 3)
                        Text(l10n.otherServices(provider.services.length - 3),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 16),
                    ],
                    
                    if (provider.address != null) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(provider.address!, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/provider-detail', arguments: provider.id);
                            },
                            icon: const Icon(Icons.info_outline),
                            label: Text(l10n.viewProfile),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Navigation vers chat
                            },
                            icon: const Icon(Icons.message),
                            label: Text(l10n.contact),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF142FE2)),
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

  void _showClientDetails(User client) {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.2,
        maxChildSize: 0.6,
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
                    
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: client.profilePicture != null && client.profilePicture!.isNotEmpty
                              ? NetworkImage(client.profilePicture!)
                              : null,
                          child: client.profilePicture == null || client.profilePicture!.isEmpty
                              ? Text(client.fullName.isNotEmpty ? client.fullName[0] : 'C',
                                  style: const TextStyle(fontSize: 24))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(client.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              if (client.location != null)
                                Text(client.location!, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (client.bio != null && client.bio!.isNotEmpty) ...[
                      Text(client.bio!, style: const TextStyle(fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 16),
                    ],
                    
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigation vers chat ou projets du client
                      },
                      icon: const Icon(Icons.message),
                      label: Text(l10n.contact),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF142FE2),
                        minimumSize: const Size(double.infinity, 48),
                      ),
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isProvider 
            ? l10n.clientsNearby
            : widget.categoryId != null 
                ? l10n.providersCategory
                : l10n.providersNearby),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;
    
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
              Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return Center(child: Text(l10n.positionNotAvailable));
    }
    
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 12),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: (controller) => _mapController = controller,
        ),
        
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, spreadRadius: 1)],
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF142FE2), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _markers.isEmpty 
                        ? (_isProvider ? l10n.noClientsFound : l10n.noProvidersFound)
                        : _isProvider 
                            ? l10n.clientsFound(_markers.length)
                            : l10n.providersFound(_markers.length),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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