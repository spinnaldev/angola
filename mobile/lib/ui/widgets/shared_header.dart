// lib/ui/widgets/shared_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';

class SharedHeader extends StatelessWidget {
  /// Si true, affiche l'icône de localisation (uniquement pour l'accueil)
  final bool showLocationIcon;
  
  /// Callback pour l'icône de localisation
  final VoidCallback? onLocationTap;
  
  /// Si les permissions de localisation sont refusées
  final bool locationPermissionDenied;
  
  /// Si la localisation est en cours de chargement
  final bool isLocationLoading;
  
  /// Callback pour gérer le dialogue de permission de localisation
  final VoidCallback? onLocationPermissionDenied;

  const SharedHeader({
    Key? key,
    this.showLocationIcon = false,
    this.onLocationTap,
    this.locationPermissionDenied = false,
    this.isLocationLoading = false,
    this.onLocationPermissionDenied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo - utiliser un logo local
          Image.asset(
            'assets/images/logo.png',
            height: 40,
            width: 80,
            errorBuilder: (context, error, stackTrace) => const Text(
              'LOGO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              // Afficher l'icône de localisation seulement si demandé
              if (showLocationIcon) _buildLocationIcon(context),
              
              // Icône de notification (toujours affichée)
              _buildNotificationIcon(context),
            ],
          ),
        ],
      ),
    );
  }

  /// Icône de notification avec badge (CODE ORIGINAL PRÉSERVÉ)
  Widget _buildNotificationIcon(BuildContext context) {
    return Consumer2<NotificationProvider, AuthProvider>(
      builder: (context, notificationProvider, authProvider, child) {
        // 🔒 VÉRIFICATION D'AUTHENTIFICATION
        if (!authProvider.isAuthenticated) {
          return const SizedBox.shrink();
        }

        final unreadCount = notificationProvider.unreadCount;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Icône de localisation (CODE ORIGINAL PRÉSERVÉ)
  Widget _buildLocationIcon(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                locationPermissionDenied
                    ? Icons.location_disabled
                    : locationProvider.currentPosition != null
                        ? Icons.location_on
                        : Icons.location_searching,
                color: locationPermissionDenied
                    ? Colors.red
                    : locationProvider.currentPosition != null
                        ? Colors.green
                        : Colors.grey,
              ),
              onPressed: () {
                if (locationPermissionDenied) {
                  onLocationPermissionDenied?.call();
                } else {
                  onLocationTap?.call();
                }
              },
              tooltip: _getLocationTooltip(locationProvider),
            ),
            if (isLocationLoading)
              Positioned(
                right: 8,
                top: 8,
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getLocationTooltip(LocationProvider locationProvider) {
    if (locationPermissionDenied) {
      return 'Localisation désactivée';
    } else if (locationProvider.currentPosition != null) {
      return 'Localisation activée';
    } else {
      return 'Recherche de localisation...';
    }
  }
}