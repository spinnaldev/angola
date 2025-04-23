import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue, ${user.fullName}!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.role == 'client'
                        ? 'Vous êtes connecté en tant que client'
                        : 'Vous êtes connecté en tant que prestataire',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'C\'est la page d\'accueil temporaire. Ici, vous pourrez bientôt:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    'Rechercher des prestataires',
                    Icons.search,
                  ),
                  _buildFeatureItem(
                    'Voir les catégories de services',
                    Icons.category,
                  ),
                  _buildFeatureItem(
                    'Gérer votre profil',
                    Icons.person,
                  ),
                  _buildFeatureItem(
                    'Voir vos favoris',
                    Icons.favorite,
                  ),
                  _buildFeatureItem(
                    'Consulter vos messages',
                    Icons.message,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}