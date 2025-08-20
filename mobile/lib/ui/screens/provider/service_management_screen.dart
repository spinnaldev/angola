import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ AJOUTÉ
import 'package:teyago/ui/widgets/verification/protected_floating_action_button.dart';
import 'package:teyago/ui/widgets/verification/protected_action_button.dart';
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
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUTÉ
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.currentUser?.role != 'provider') {
      return Scaffold(
        body: Center(
          child: Text(l10n.providerOnlyPage), 
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageMyServices), 
        elevation: 0,
      ),
      body: serviceProvider.isLoading 
        ? Center(child: LoadingIndicator()) 
        : serviceProvider.myServices.isEmpty 
          ? _buildEmptyState(l10n) // ✅ PASSÉ l10n
          : _buildServiceList(serviceProvider.myServices, l10n), // ✅ PASSÉ l10n
      
      // ✅ BOUTON FLOTTANT AVEC VÉRIFICATION DU PROFIL
      floatingActionButton: ProtectedFloatingActionButton(
        actionDescription: l10n.addService, 
        onPressed: () => _navigateToAddService(context),
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) { // ✅ PARAMÈTRE AJOUTÉ
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
            l10n.noServicesYet, 
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            l10n.addFirstServices, 
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          
          // ✅ BOUTON AVEC VÉRIFICATION DU PROFIL
          ElevatedButton.icon(
            onPressed: () => _handleProtectedAction(context, _navigateToAddService),
            icon: Icon(Icons.add),
            label: Text(l10n.addService),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList(List<Service> services, AppLocalizations l10n) { // ✅ PARAMÈTRE AJOUTÉ
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
                      // ✅ SWITCH AVEC TOOLTIPS TRADUITS
                      Tooltip(
                        message: service.isAvailable ? l10n.available : l10n.unavailable,
                        child: Switch(
                          value: service.isAvailable,
                          onChanged: (value) => _toggleServiceAvailability(service, value),
                          activeColor: Theme.of(context).primaryColor,
                        ),
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
                          ? l10n.onQuote 
                          : '${service.price} AOA',
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
                            tooltip: l10n.edit, 
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(8),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(service, l10n), // ✅ PASSÉ l10n
                            tooltip: l10n.delete, 
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

  void _showDeleteConfirmation(Service service, AppLocalizations l10n) { // ✅ PARAMÈTRE AJOUTÉ
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.confirmDeletion), 
          content: Text(l10n.deleteServiceConfirm), 
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel), 
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteService(service, l10n); // ✅ PASSÉ l10n
              },
              child: Text(l10n.delete, style: TextStyle(color: Colors.red)), 
            ),
          ],
        );
      },
    );
  }

  void _deleteService(Service service, AppLocalizations l10n) async { // ✅ PARAMÈTRE AJOUTÉ
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    await serviceProvider.deleteService(service.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.serviceDeletedSuccess)), 
    );
  }

  // ✅ MÉTHODE DE VÉRIFICATION POUR LES ACTIONS PROTÉGÉES
  void _handleProtectedAction(BuildContext context, Function(BuildContext) action) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final l10n = AppLocalizations.of(context)!;

    // Vérifier si l'utilisateur est vérifié
    if (user?.isVerified == true) {
      action(context); // Exécuter l'action si vérifié
    } else {
      // Afficher un dialogue de vérification requise
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.verificationRequired), 
          content: Text(l10n.verificationRequiredMessage), 
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel), 
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Rediriger vers la page de vérification
                Navigator.pushNamed(context, '/provider-verification');
              },
              child: Text(l10n.verify), 
            ),
          ],
        ),
      );
    }
  }
}