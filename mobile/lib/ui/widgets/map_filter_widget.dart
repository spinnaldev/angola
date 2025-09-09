// lib/ui/widgets/map_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/improved_nearby_provider.dart';

class MapFilterWidget extends StatefulWidget {
  final VoidCallback? onFiltersChanged;
  final VoidCallback onClose;

  const MapFilterWidget({
    Key? key,
    this.onFiltersChanged,
    required this.onClose,
  }) : super(key: key);

  @override
  _MapFilterWidgetState createState() => _MapFilterWidgetState();
}

class _MapFilterWidgetState extends State<MapFilterWidget> {
  double _searchRadius = 15.0;
  double _minRating = 0.0;
  String _businessType = '';
  
  @override
  void initState() {
    super.initState();
    // Récupérer les valeurs actuelles du provider
    final nearbyProvider = Provider.of<ImprovedNearbyProvider>(context, listen: false);
    _searchRadius = nearbyProvider.searchRadius;
    _minRating = nearbyProvider.minRating;
    _businessType = nearbyProvider.businessType;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.applyFilters,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          
          // Contenu des filtres
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rayon de recherche
                Text(
                  localizations.searchRadius,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _searchRadius,
                        min: ImprovedNearbyProvider.MIN_SEARCH_RADIUS,
                        max: ImprovedNearbyProvider.MAX_SEARCH_RADIUS,
                        divisions: (ImprovedNearbyProvider.MAX_SEARCH_RADIUS - ImprovedNearbyProvider.MIN_SEARCH_RADIUS).toInt(),
                        label: '${_searchRadius.round()} km',
                        onChanged: (value) {
                          setState(() {
                            _searchRadius = value;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_searchRadius.round()} km',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Note minimum
                Text(
                  localizations.minimumRating,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _minRating,
                         min: ImprovedNearbyProvider.MIN_SEARCH_RADIUS,
                        max: ImprovedNearbyProvider.MAX_SEARCH_RADIUS,
                        divisions: (ImprovedNearbyProvider.MAX_SEARCH_RADIUS - ImprovedNearbyProvider.MIN_SEARCH_RADIUS).toInt(),
                        label: _minRating == 0.0 
                            ? 'Toutes les notes' 
                            : '${_minRating.toStringAsFixed(1)} ⭐',
                        onChanged: (value) {
                          setState(() {
                            _minRating = value;
                          });
                        },
                        activeColor: Colors.amber,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_minRating > 0.0) ...[
                            Text(
                              _minRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                          ] else ...[
                            const Text(
                              'Toutes',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Type d'entreprise
                Text(
                  localizations.businessType,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBusinessTypeChip('', 'Tous'),
                    _buildBusinessTypeChip('Entreprise', localizations.company),
                    _buildBusinessTypeChip('Freelance', localizations.freelance),
                    _buildBusinessTypeChip('Particulier', localizations.individual),
                  ],
                ),
              ],
            ),
          ),
          
          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Bouton Reset
                Expanded(
                  child: TextButton(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      localizations.reset,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Bouton Appliquer
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      localizations.applyFilters,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTypeChip(String value, String label) {
    final isSelected = _businessType == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _businessType = selected ? value : '';
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected 
            ? Theme.of(context).primaryColor 
            : Colors.grey[300]!,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _searchRadius = 15.0;
      _minRating = 0.0;
      _businessType = '';
    });
  }

  void _applyFilters() {
    // Appliquer les filtres au provider
    final nearbyProvider = Provider.of<ImprovedNearbyProvider>(context, listen: false);
    
    nearbyProvider.searchNearbyProviders(
      radius: _searchRadius,
      minRating: _minRating,
      businessType: _businessType,
      forceRefresh: true,
    );
    
    // Notifier les changements
    widget.onFiltersChanged?.call();
    
    // Fermer le widget
    widget.onClose();
    
    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtres appliqués: ${nearbyProvider.resultsCount} prestataires trouvés'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}