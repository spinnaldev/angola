import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../common/bottom_navigation.dart';
// import '../../providers/project_provider.dart';
import '../../core/models/user.dart';
// import '../../core/models/project.dart';

import 'package:w3_loc/core/models/project.dart' as models;
import 'package:w3_loc/providers/project_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les projets de l'utilisateur au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).fetchUserProjects();
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
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final User? user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mon profil',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () {
              // Action d'édition du profil
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section profil utilisateur
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                        ? NetworkImage(user.profilePicture!)
                        : null,
                    child: user.profilePicture == null || user.profilePicture!.isEmpty
                        ? Text(
                            user.firstName.isNotEmpty ? user.firstName[0] : 'U',
                            style: const TextStyle(fontSize: 28),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section Adresse
            _buildInfoSection(
              icon: Icons.location_on_outlined,
              title: 'Adresse',
              value: user.location ?? 'Angola',
            ),

            // Section Date d'inscription
            _buildInfoSection(
              icon: Icons.calendar_today_outlined,
              title: 'Membre depuis Mars 2025',
              value: '',
            ),

            const SizedBox(height: 24),

            // Section Mes projets
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes projets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Description projet
                  if (projectProvider.userProjects.isNotEmpty) ...[
                    Text(
                      projectProvider.userProjects.first.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // Voir plus de détails sur les projets
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Voir plus'),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                    
                    // Liste des prestataires associés au projet
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: projectProvider.userProjects.first.providers.map((provider) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: provider.imageUrl.isNotEmpty
                                      ? NetworkImage(provider.imageUrl)
                                      : null,
                                  child: provider.imageUrl.isEmpty
                                      ? Text(
                                          provider.name.substring(0, 1),
                                          style: const TextStyle(fontSize: 20),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      provider.specialty,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ] else if (projectProvider.isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else ...[
                    Text(
                      'Vous n\'avez pas encore de projets',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // Barre de navigation inférieure
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0, // Explore screen est l'index 0
        onTap: _handleNavigation,
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[800]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (value.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}