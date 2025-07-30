// lib/ui/widgets/map_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/improved_nearby_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/models/category.dart';

class MapFilterWidget extends StatefulWidget {
  final VoidCallback onFiltersChanged;
  final VoidCallback onClose;

  const MapFilterWidget({
    Key? key,
    required this.onFiltersChanged,
    required this.onClose,
  }) : super(key: key);

  @override
  _MapFilterWidgetState createState() => _MapFilterWidgetState();
}

class _MapFilterWidgetState extends State<MapFilterWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Valeurs locales pour les filtres
  double _localRadius = 10.0;
  double _localMinRating = 0.0;
  String _localBusinessType = '';
  int? _localCategoryId;
  String _localCategoryName = '';

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadCurrentFilters();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  void _loadCurrentFilters() {
    final nearbyProvider = Provider.of<ImprovedNearbyProvider>(context, listen: false);
    setState(() {
      _localRadius = nearbyProvider.searchRadius;
      _localMinRating = nearbyProvider.minRating;
      _localBusinessType = nearbyProvider.businessType;
      _localCategoryName = nearbyProvider.selectedCategory;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 300),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildFilterContent(),
          ),
        );
      },
    );
  }

  Widget _buildFilterContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildHeader(),
          
          const SizedBox(height: 20),
          
          // Filtre de rayon
          _buildRadiusFilter(),
          
          const SizedBox(height: 20),
          
          // Filtre de catégorie
          _buildCategoryFilter(),
          
          const SizedBox(height: 20),
          
          // Filtre de note minimum
          _buildRatingFilter(),
          
          const SizedBox(height: 20),
          
          // Filtre de type d'entreprise
          _buildBusinessTypeFilter(),
          
          const SizedBox(height: 24),
          
          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.tune,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Filtres de recherche',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }

  Widget _buildRadiusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.radio_button_checked, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.searchRadius,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_localRadius.toInt()} km',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blue,
            thumbColor: Colors.blue,
            overlayColor: Colors.blue.withOpacity(0.2),
            valueIndicatorColor: Colors.blue,
          ),
          child: Slider(
            value: _localRadius,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            label: '${_localRadius.toInt()} km',
            onChanged: (value) {
              setState(() {
                _localRadius = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category, size: 20, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Catégorie',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _localCategoryId,
                  hint: const Text('Toutes les catégories'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Toutes les catégories'),
                    ),
                    ...categoryProvider.categories.map((category) {
                      return DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _localCategoryId = value;
                      if (value != null) {
                        final category = categoryProvider.categories
                            .firstWhere((cat) => cat.id == value);
                        _localCategoryName = category.name;
                      } else {
                        _localCategoryName = '';
                      }
                    });
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, size: 20, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.minimumRating,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _localMinRating == 0 ? 'Toutes' : '${_localMinRating.toInt()}⭐+',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            final rating = index.toDouble();
            final isSelected = _localMinRating == rating;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _localMinRating = rating;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  rating == 0 ? 'Toutes' : '${rating.toInt()}⭐+',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBusinessTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.business, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.businessType,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBusinessTypeChip('', 'Tous'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBusinessTypeChip('Entreprise', 'Entreprises'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBusinessTypeChip('Freelance', 'Freelances'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessTypeChip(String value, String label) {
    final isSelected = _localBusinessType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _localBusinessType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Bouton Réinitialiser
        Expanded(
          child: OutlinedButton(
            onPressed: _resetFilters,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              AppLocalizations.of(context)!.reset,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Bouton Appliquer
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 2,
            ),
            child: Text(
              AppLocalizations.of(context)!.applyFilters,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Méthodes d'action
  void _resetFilters() {
    setState(() {
      _localRadius = 10.0;
      _localMinRating = 0.0;
      _localBusinessType = '';
      _localCategoryId = null;
      _localCategoryName = '';
    });
    
    final nearbyProvider = Provider.of<ImprovedNearbyProvider>(context, listen: false);
    nearbyProvider.resetFilters();
    
    widget.onFiltersChanged();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtres réinitialisés'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _applyFilters() async {
    final nearbyProvider = Provider.of<ImprovedNearbyProvider>(context, listen: false);
    
    // Appliquer les filtres
    await nearbyProvider.searchNearbyProviders(
      radius: _localRadius,
      categoryId: _localCategoryId,
      minRating: _localMinRating,
      businessType: _localBusinessType,
      forceRefresh: true,
    );
    
    widget.onFiltersChanged();
    widget.onClose();
    
    // Afficher un feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filtres appliqués: ${nearbyProvider.resultsCount} prestataires trouvés',
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () {
            // L'utilisateur peut voir les résultats sur la carte
          },
        ),
      ),
    );
  }
}