import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/subcategory_provider.dart';
import '../../../core/models/service.dart';
import '../../../ui/screens/provider/add_edit_service_screen.dart';
import 'add_edit_service_screen.dart';
import '../../widgets/loading_indicator.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({Key? key}) : super(key: key);

  @override
  _ServiceManagementScreenState createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Charger les services du prestataire connecté
    await Provider.of<ServiceProvider>(context, listen: false).fetchMyServices();
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.currentUser?.role != 'provider') {
      return Scaffold(
        body: Center(
          child: Text('Cette page est réservée aux prestataires.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion de mes services'),
        elevation: 0,
      ),
      body: serviceProvider.isLoading 
        ? Center(child: LoadingIndicator()) 
        : serviceProvider.myServices.isEmpty 
          ? _buildEmptyState() 
          : _buildServiceList(serviceProvider.myServices),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddService(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_repair_service_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Vous n\'avez pas encore de services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ajoutez vos premiers services pour être visible par les clients',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddService(context),
            icon: Icon(Icons.add),
            label: Text('Ajouter un service'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList(List<Service> services) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _navigateToEditService(context, service),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: service.isAvailable,
                        onChanged: (value) => _toggleServiceAvailability(service, value),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service.priceType == 'quote' 
                          ? 'Sur devis' 
                          : '${service.price} FCFA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, size: 20),
                            onPressed: () => _navigateToEditService(context, service),
                            tooltip: 'Modifier',
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(8),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(service),
                            tooltip: 'Supprimer',
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddService(BuildContext context) async {
    // Charger les sous-catégories pour le formulaire
    await Provider.of<SubcategoryProvider>(context, listen: false).fetchSubcategories(0);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditServiceScreen(),
      ),
    ).then((_) => _loadData()); // Recharger les données au retour
  }

  void _navigateToEditService(BuildContext context, Service service) async {
    // Charger les sous-catégories pour le formulaire
    await Provider.of<SubcategoryProvider>(context, listen: false).fetchSubcategories(0);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditServiceScreen(serviceToEdit: service),
      ),
    ).then((_) => _loadData()); // Recharger les données au retour
  }

  void _toggleServiceAvailability(Service service, bool isAvailable) async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    await serviceProvider.updateServiceAvailability(service.id, isAvailable);
    // Aucun besoin d'appeler _loadData() car le provider met déjà à jour l'état
  }

  void _showDeleteConfirmation(Service service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce service ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteService(service);
              },
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteService(Service service) async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    await serviceProvider.deleteService(service.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Service supprimé avec succès')),
    );
  }
}