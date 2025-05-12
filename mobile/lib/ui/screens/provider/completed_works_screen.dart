// lib/ui/screens/provider/completed_works_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/completed_work_provider.dart';
import '../../../providers/provider_verification_provider.dart';
import '../../../core/models/completed_work.dart';
import '../../widgets/loading_indicator.dart';
import 'add_work_screen.dart';
import 'provider_verification_screen.dart';

class CompletedWorksScreen extends StatefulWidget {
  const CompletedWorksScreen({Key? key}) : super(key: key);

  @override
  _CompletedWorksScreenState createState() => _CompletedWorksScreenState();
}

class _CompletedWorksScreenState extends State<CompletedWorksScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Charger les travaux effectués
    await Provider.of<CompletedWorkProvider>(context, listen: false).fetchProviderWorks();
    
    // Vérifier si le prestataire est vérifié
    await Provider.of<ProviderVerificationProvider>(context, listen: false).fetchVerificationInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travaux effectués'),
        elevation: 0,
      ),
      body: Consumer2<CompletedWorkProvider, ProviderVerificationProvider>(
        builder: (context, workProvider, verificationProvider, _) {
          // Vérifier si le prestataire est vérifié ou en attente de vérification
          if (!verificationProvider.isLoading && 
              verificationProvider.verification == null) {
            // Aucune vérification soumise, afficher un message pour inciter à se vérifier
            return _buildVerificationRequired(context);
          }
          
          // Si la vérification est en attente
          if (!verificationProvider.isLoading && 
              verificationProvider.verificationStatus == 'pending') {
            // Vérification en attente, permettre d'ajouter des travaux mais afficher un avertissement
            return _buildVerificationPending(context, workProvider);
          }
          
          if (workProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          final works = workProvider.works;
          
          if (works.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: works.length,
              itemBuilder: (context, index) {
                final work = works[index];
                return _buildWorkCard(work);
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<ProviderVerificationProvider>(
        builder: (context, verificationProvider, _) {
          // N'afficher le bouton que si la vérification est soumise ou en attente
          if (verificationProvider.verification != null) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddWorkScreen(),
                  ),
                ).then((_) => _loadData());
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
  
  Widget _buildVerificationRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Vérification requise',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pour ajouter vos travaux effectués, vous devez d\'abord compléter la vérification de votre compte.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderVerificationScreen(),
                  ),
                ).then((_) => _loadData());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Compléter la vérification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerificationPending(BuildContext context, CompletedWorkProvider workProvider) {
    final works = workProvider.works;
    
    return Column(
      children: [
        // Bannière d'information sur le statut de vérification
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.amber[100],
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[800]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vérification en cours',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Votre vérification est en cours de traitement. Vous pouvez ajouter des travaux en attendant.',
                      style: TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Liste des travaux
        Expanded(
          child: workProvider.isLoading
          ? const Center(child: LoadingIndicator())
          : works.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: works.length,
                itemBuilder: (context, index) {
                  final work = works[index];
                  return _buildWorkCard(work);
                },
              ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun travail effectué',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ajoutez vos réalisations pour mettre en valeur votre expertise',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWorkCard(CompletedWork work) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images du travail
          if (work.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: PageView.builder(
                  itemCount: work.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      work.imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          
          // Informations sur le travail
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      work.location,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(work.completionDate),
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  work.description,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Actions du travail
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bouton de suppression
                    TextButton.icon(
                      onPressed: () => _showDeleteConfirmation(work),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(CompletedWork work) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer le travail "${work.title}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final workProvider = Provider.of<CompletedWorkProvider>(context, listen: false);
                final success = await workProvider.deleteWork(work.id!);
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Travail supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}