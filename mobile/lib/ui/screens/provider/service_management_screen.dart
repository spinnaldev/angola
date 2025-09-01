import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  // ✅ AJOUT: Map pour tracker les services en cours de modification
  final Set<int> _servicesBeingToggled = <int>{};

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
    final l10n = AppLocalizations.of(context)!;
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
        actions: [
          // ✅ AJOUT: Bouton de rafraîchissement
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: serviceProvider.isLoading 
          ? Center(child: LoadingIndicator()) 
          : serviceProvider.myServices.isEmpty 
            ? _buildEmptyState(l10n)
            : _buildServiceList(serviceProvider.myServices, l10n),
      ),
      
      floatingActionButton: ProtectedFloatingActionButton(
        actionDescription: l10n.addService, 
        onPressed: () => _navigateToAddService(context),
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
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

  Widget _buildServiceList(List<Service> services, AppLocalizations l10n) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(service, l10n);
      },
    );
  }

  // ✅ AMÉLIORATION: Card de service avec meilleur design et gestion d'état
  Widget _buildServiceCard(Service service, AppLocalizations l10n) {
    final isBeingToggled = _servicesBeingToggled.contains(service.id);
    
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
              // En-tête avec titre et toggle amélioré
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: service.isAvailable ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                  // ✅ AMÉLIORATION: Toggle avec état visuel et gestion d'erreur
                  _buildServiceToggle(service, l10n, isBeingToggled),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Description avec indicateur d'état
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: service.isAvailable ? Colors.grey[700] : Colors.grey[500],
                      ),
                    ),
                  ),
                  // ✅ AJOUT: Indicateur visuel d'état
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: service.isAvailable ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      service.isAvailable ? l10n.available : l10n.unavailable,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: service.isAvailable ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Prix et actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    service.priceType == 'quote' 
                      ? l10n.onQuote 
                      : '${service.price} AOA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: service.isAvailable 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[500],
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
                        onPressed: () => _showDeleteConfirmation(service, l10n),
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
  }

  // ✅ NOUVEAU: Widget de toggle amélioré avec état de chargement
  Widget _buildServiceToggle(Service service, AppLocalizations l10n, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          )
        else
          Tooltip(
            message: service.isAvailable ? l10n.available : l10n.unavailable,
            child: Switch(
              value: service.isAvailable,
              onChanged: (value) => _toggleServiceAvailability(service, value, l10n),
              activeColor: Theme.of(context).primaryColor,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
      ],
    );
  }

  void _navigateToAddService(BuildContext context) async {
    await Provider.of<SubcategoryProvider>(context, listen: false).fetchSubcategories(0);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditServiceScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToEditService(BuildContext context, Service service) async {
    await Provider.of<SubcategoryProvider>(context, listen: false).fetchSubcategories(0);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditServiceScreen(serviceToEdit: service),
      ),
    ).then((_) => _loadData());
  }

  // ✅ AMÉLIORATION MAJEURE: Gestion complète des erreurs et feedback utilisateur
  void _toggleServiceAvailability(Service service, bool isAvailable, AppLocalizations l10n) async {
    // Éviter les appels multiples simultanés
    if (_servicesBeingToggled.contains(service.id)) return;
    
    setState(() {
      _servicesBeingToggled.add(service.id);
    });

    try {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      
      // Appel à l'API
      await serviceProvider.updateServiceAvailability(service.id, isAvailable);

      // Succès - Afficher un message de confirmation discret
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(isAvailable 
                  ? 'Service activé avec succès' 
                  : 'Service désactivé avec succès'),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        String errorMessage = _getErrorMessage(e.toString(), l10n);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Erreur de mise à jour',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(errorMessage, style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () => _toggleServiceAvailability(service, isAvailable, l10n),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _servicesBeingToggled.remove(service.id);
        });
      }
    }
  }

  // ✅ NOUVEAU: Méthode pour traduire les erreurs
  String _getErrorMessage(String error, AppLocalizations l10n) {
    if (error.contains('403') || error.toLowerCase().contains('forbidden')) {
      return 'Vous n\'êtes pas autorisé à modifier ce service';
    } else if (error.contains('401') || error.toLowerCase().contains('unauthorized')) {
      return 'Vous devez être connecté pour modifier ce service';
    } else if (error.toLowerCase().contains('network') || error.toLowerCase().contains('connection')) {
      return 'Erreur de connexion. Vérifiez votre réseau';
    } else if (error.contains('404') || error.toLowerCase().contains('not found')) {
      return 'Service non trouvé. Il a peut-être été supprimé';
    } else {
      return 'Une erreur technique est survenue';
    }
  }

  void _showDeleteConfirmation(Service service, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.confirmDeletion), 
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteServiceConfirm),
              SizedBox(height: 8),
              Text(
                'Service: "${service.title}"',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel), 
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteService(service, l10n);
              },
              child: Text(
                l10n.delete, 
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ), 
            ),
          ],
        );
      },
    );
  }

  void _deleteService(Service service, AppLocalizations l10n) async {
    try {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      await serviceProvider.deleteService(service.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(l10n.serviceDeletedSuccess),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Erreur lors de la suppression du service'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleProtectedAction(BuildContext context, Function(BuildContext) action) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final l10n = AppLocalizations.of(context)!;

    if (user?.isVerified == true) {
      action(context);
    } else {
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