// lib/ui/screens/service_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/service.dart';
import '../../core/models/provider_model.dart'; // Renommé pour éviter la confusion avec le package provider
import '../../providers/service_provider.dart';
import '../../providers/provider_detail_provider.dart';
import '../common/bottom_navigation.dart';
import 'profile_screen.dart';
class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;

  const ServiceDetailScreen({Key? key, required this.serviceId}) : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les détails du service et du prestataire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServiceProvider>(context, listen: false).fetchServiceDetails(widget.serviceId);
      Provider.of<ProviderDetailProvider>(context, listen: false).fetchProviderByServiceId(widget.serviceId);
    });
  }
  void _handleNavigation(int index) {
    if (index == 0) {
      // Déjà sur Explorer
    } else if (index == 1) {
      // Navigation vers Messages
    } else if (index == 2) {
      // Navigation vers Profil
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer2<ServiceProvider, ProviderDetailProvider>(
          builder: (context, serviceProvider, providerDetailProvider, _) {
            if (serviceProvider.isLoading || providerDetailProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final service = serviceProvider.currentService;
            final provider = providerDetailProvider.currentProvider;

            if (service == null || provider == null) {
              return const Center(child: Text('Données non disponibles'));
            }

            return Column(
              children: [
                // En-tête avec le titre du profil
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Profil prestataire',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Pour équilibrer avec le bouton retour
                    ],
                  ),
                ),
                
                // Image d'en-tête
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      child: service.imageUrl.isNotEmpty
                          ? Image.network(
                              service.imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image, size: 50, color: Colors.grey),
                              ),
                            ),
                    ),
                    
                    // Info du prestataire sur l'image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.black.withOpacity(0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: provider.profileImageUrl.isNotEmpty
                                      ? NetworkImage(provider.profileImageUrl)
                                      : null,
                                  child: provider.profileImageUrl.isEmpty
                                      ? Text(
                                          provider.name.substring(0, 1),
                                          style: const TextStyle(fontSize: 20),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      provider.businessType,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF142FE2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        provider.rating.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${provider.reviewCount})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Bouton Demander un devis
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Action demander un devis
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF142FE2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Demander un devis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // TabBar pour naviguer entre les sections
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF142FE2),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF142FE2),
                  tabs: const [
                    Tab(text: 'Présentation'),
                    Tab(text: 'Évaluations'),
                    Tab(text: 'Galerie'),
                  ],
                ),
                
                // Contenu des tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab Présentation
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section À propos
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'À propos',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF142FE2),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    provider.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Section Services proposés
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Services proposés',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF142FE2),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...provider.services.map((service) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          service.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Sur devis',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tab Évaluations
                      const Center(child: Text('Évaluations')),
                      
                      // Tab Galerie
                      const Center(child: Text('Galerie')),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      
      // Barre de navigation inférieure
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0, // Explore screen est l'index 0
        onTap: _handleNavigation,
      ),
    );
  }
}