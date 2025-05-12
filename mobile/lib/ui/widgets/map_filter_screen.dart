// lib/ui/widgets/map_filter_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/models/service.dart';

class MapFilterScreen extends StatefulWidget {
  final VoidCallback onClose;
  
  const MapFilterScreen({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  _MapFilterScreenState createState() => _MapFilterScreenState();
}

class _MapFilterScreenState extends State<MapFilterScreen> {
  // Simuler des données de services pour la démo
  List<Map<String, dynamic>> services = [];
  
  // Filtres
  double _radius = 5.0; // Rayon de recherche en km
  RangeValues _priceRange = const RangeValues(0, 200);
  List<String> _selectedCategories = [];
  List<String> _selectedBusinessTypes = [];
  double _minRating = 0.0;
  
  // Options des filtres
  final List<String> categories = [
    'Maison & Construction',
    'Bien-être & Beauté',
    'Événements & Artistiques',
    'Transport & Logistique',
    'Services Professionnels',
    'Services Numériques',
  ];
  
  final List<String> businessTypes = [
    'Entreprise',
    'Freelance',
  ];
  
  bool _isFilterVisible = false;
  
  @override
  void initState() {
    super.initState();
    _generateDemoServices();
  }
  
  void _generateDemoServices() {
    // Simuler des services à proximité
    final random = math.Random();
    final serviceNames = [
      'Plombier',
      'Électricien',
      'Peintre',
      'Jardinier',
      'Nettoyage',
      'Serrurier',
      'Menuisier',
      'Maçon',
    ];
    
    final businessTypes = ['Entreprise', 'Freelance'];
    final categoryNames = [
      'Maison & Construction',
      'Bien-être & Beauté',
      'Événements & Artistiques',
      'Transport & Logistique',
      'Services Professionnels',
      'Services Numériques',
    ];
    
    // Générer des coordonnées aléatoires autour d'un point central
    const centerLat = 6.3702; // Cotonou, Bénin
    const centerLng = 2.3912;
    
    services = List.generate(20, (index) {
      // Coordonnées aléatoires à proximité
      final lat = centerLat + (random.nextDouble() - 0.5) * 0.05;
      final lng = centerLng + (random.nextDouble() - 0.5) * 0.05;
      
      return {
        'id': index,
        'name': '${serviceNames[random.nextInt(serviceNames.length)]} Pro',
        'category': categoryNames[random.nextInt(categoryNames.length)],
        'businessType': businessTypes[random.nextInt(businessTypes.length)],
        'rating': 3.0 + random.nextDouble() * 2.0,
        'price': 50.0 + random.nextInt(150) * 1.0,
        'distance': 0.5 + random.nextDouble() * 9.5, // En km
        'latitude': lat,
        'longitude': lng,
      };
    });
  }
  
  // Filtrer les services selon les critères
  List<Map<String, dynamic>> _getFilteredServices() {
    return services.where((service) {
      final bool distanceOk = service['distance'] <= _radius;
      final bool priceOk = service['price'] >= _priceRange.start && 
                          service['price'] <= _priceRange.end;
      final bool ratingOk = service['rating'] >= _minRating;
      
      bool categoryOk = true;
      if (_selectedCategories.isNotEmpty) {
        categoryOk = _selectedCategories.contains(service['category']);
      }
      
      bool businessTypeOk = true;
      if (_selectedBusinessTypes.isNotEmpty) {
        businessTypeOk = _selectedBusinessTypes.contains(service['businessType']);
      }
      
      return distanceOk && priceOk && ratingOk && categoryOk && businessTypeOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = _getFilteredServices();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services à proximité'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
        actions: [
          IconButton(
            icon: Icon(_isFilterVisible ? Icons.close : Icons.filter_list),
            onPressed: () {
              setState(() {
                _isFilterVisible = !_isFilterVisible;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Carte de géolocalisation (simulée)
              Container(
                height: 300,
                color: Colors.grey[200],
                child: Stack(
                  children: [
                    // Ici, vous intégreriez une vraie carte avec Google Maps ou autre
                    Center(
                      child: Image.network(
                        'https://maps.googleapis.com/maps/api/staticmap?center=6.3702,2.3912&zoom=14&size=600x300&maptype=roadmap&markers=color:red|6.3702,2.3912&key=YOUR_API_KEY',
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        // En production, utilisez une vraie clé API Google Maps
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Carte de géolocalisation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Services à proximité de votre position',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Simuler des marqueurs de position
                    ...filteredServices.map((service) {
                      // Calculer une position relative pour la démo
                      final relX = (service['longitude'] - 2.3912) * 10000;
                      final relY = (service['latitude'] - 6.3702) * 10000;
                      
                      return Positioned(
                        left: relX != null ? (300 + relX).toDouble() : null,
                        top: relY != null ? (150 + relY).toDouble() : null,
                        child: GestureDetector(
                          onTap: () {
                            _showServiceDetails(service);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF142FE2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                service['id'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              // Liste des services filtrés
              Expanded(
                child: filteredServices.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun service trouvé avec ces critères',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF142FE2),
                              child: Text(
                                service['id'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(service['name']),
                            subtitle: Text('${service['category']} • ${service['distance'].toStringAsFixed(1)} km'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    Text(service['rating'].toStringAsFixed(1)),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Text('${service['price'].toInt()} FCFA', 
                                  style: const TextStyle(
                                    color: Color(0xFF142FE2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              _showServiceDetails(service);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          
          // Panneau de filtres
          if (_isFilterVisible)
            _buildFilterPanel(),
        ],
      ),
    );
  }
  
  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtres',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Rayon de recherche
            const Text(
              'Rayon de recherche',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _radius,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '${_radius.round()} km',
                    onChanged: (value) {
                      setState(() {
                        _radius = value;
                      });
                    },
                  ),
                ),
                Text('${_radius.round()} km'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Fourchette de prix
            const Text(
              'Fourchette de prix',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 500,
                    divisions: 50,
                    labels: RangeLabels(
                      '${_priceRange.start.round()} FCFA',
                      '${_priceRange.end.round()} FCFA',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_priceRange.start.round()} FCFA'),
                Text('${_priceRange.end.round()} FCFA'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Note minimale
            const Text(
              'Note minimale',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                final rating = index + 1.0;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _minRating = rating;
                    });
                  },
                  child: Icon(
                    Icons.star,
                    size: 36,
                    color: rating <= _minRating ? Colors.amber : Colors.grey[300],
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 20),
            
            // Catégories
            const Text(
              'Catégories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Wrap(
              spacing: 8,
              children: categories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: const Color(0xFF142FE2).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF142FE2),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Type d'entreprise
            const Text(
              'Type de prestataire',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Wrap(
              spacing: 8,
              children: businessTypes.map((type) {
                final isSelected = _selectedBusinessTypes.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: const Color(0xFF142FE2).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF142FE2),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedBusinessTypes.add(type);
                      } else {
                        _selectedBusinessTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 30),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        // Réinitialiser tous les filtres
                        _radius = 5.0;
                        _priceRange = const RangeValues(0, 200);
                        _selectedCategories = [];
                        _selectedBusinessTypes = [];
                        _minRating = 0.0;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isFilterVisible = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF142FE2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showServiceDetails(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF142FE2),
                    radius: 24,
                    child: Text(
                      service['id'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${service['category']} • ${service['businessType']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          service['rating'].toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Distance: ${service['distance'].toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Prix: ${service['price'].toInt()} FCFA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF142FE2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Naviguer vers la carte avec itinéraire
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Itinéraire'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Naviguer vers la page de détails
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Détails'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF142FE2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}