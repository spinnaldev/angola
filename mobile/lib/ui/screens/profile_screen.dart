// lib/ui/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/project_provider.dart';
import '../../core/models/user.dart';
import '../../core/models/service.dart';
import '../../core/models/project.dart';
import '../common/bottom_navigation.dart';
import 'edit_profile_screen.dart';
import 'service_detail_screen.dart';
import 'package:intl/intl.dart';
import './base_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      if (user.role == 'provider') {
        // Charger les services du prestataire
        Provider.of<ServiceProvider>(context, listen: false).fetchMyServices();
      } else {
        // Charger les projets du client
        Provider.of<ProjectProvider>(context, listen: false).fetchUserProjects();
      }
    }
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(context, '/explore', (route) => false);
    } else if (index == 2) {
      Navigator.pushNamedAndRemoveUntil(context, '/messages', (route) => false);
    }
    // index 3 = profil actuel, ne rien faire
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      currentIndex: 3, // messaging est sélectionné
      body: _buildProfilContent(),
    );
  }
  Widget _buildProfilContent(){
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: Column(
              children: [
                // Header avec titre et crayon d'édition
                _buildHeader(),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Section profil utilisateur
                        _buildUserProfileSection(user),
                        
                        _buildDivider(),
                        
                        // Section adresse et membre depuis
                        _buildLocationAndMemberSection(user),
                        
                        _buildDivider(),
                        
                        // Section Mes projets/services
                        _buildProjectsSection(user),
                        
                        const SizedBox(height: 100), // Espace pour la bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mon profil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) => _loadData()); // Recharger après modification
            },
            icon: const Icon(
              Icons.edit,
              color: Colors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'En ligne • il y a une minute',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF142FE2),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: user.profilePicture == null || user.profilePicture!.isEmpty
                  ? Text(
                      user.firstName.isNotEmpty ? user.firstName[0] : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
              backgroundColor: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndMemberSection(User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Adresse
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 24,
                color: Colors.black87,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adresse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.location ?? 'Angola',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Membre depuis
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 24,
                color: Colors.black87,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Membre depuis ${DateFormat('MMMM yyyy', 'fr_FR').format(user.dateJoined)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes projets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          if (user.role == 'provider')
            _buildProviderServicesCarousel()
          else
            _buildClientProjectsCarousel(),
        ],
      ),
    );
  }

  Widget _buildProviderServicesCarousel() {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, child) {
        if (serviceProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final services = serviceProvider.myServices;
        
        if (services.isEmpty) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_repair_service_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun service ajouté',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _buildServiceCard(service);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Navigation vers tous les services
                    Navigator.pushNamed(context, '/service-management');
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Voir plus'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF142FE2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF142FE2),
                        child: Text(
                          Provider.of<AuthProvider>(context).currentUser?.firstName[0] ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Provider.of<AuthProvider>(context).currentUser?.fullName ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildClientProjectsCarousel() {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        if (projectProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final projects = projectProvider.userProjects;
        
        if (projects.isEmpty) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun projet créé',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return _buildProjectCard(project);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Navigation vers tous les projets
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Voir plus'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF142FE2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF142FE2),
                        child: Text(
                          Provider.of<AuthProvider>(context).currentUser?.firstName[0] ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Provider.of<AuthProvider>(context).currentUser?.fullName ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(serviceId: service.id , providerId: service.provider_id, ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: service.imageUrl.isNotEmpty
                  ? Image.network(
                      service.imageUrl,
                      width: 160,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 160,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      width: 160,
                      height: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.priceType == 'quote' 
                          ? 'Sur devis' 
                          : '${service.price.toInt()} FCFA',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF142FE2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            
            // Prestataires associés
            if (project.providers.isNotEmpty)
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: project.providers.first.imageUrl.isNotEmpty
                        ? NetworkImage(project.providers.first.imageUrl)
                        : null,
                    child: project.providers.first.imageUrl.isEmpty
                        ? Text(
                            project.providers.first.name[0],
                            style: const TextStyle(fontSize: 10),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.providers.first.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          project.providers.first.specialty,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.grey[300],
    );
  }
}