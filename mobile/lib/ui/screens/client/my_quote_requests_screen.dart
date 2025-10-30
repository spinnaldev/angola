import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ AJOUT des traductions
import '../../../providers/quote_provider.dart';
import '../../../core/models/quote_request.dart';
import '../../widgets/loading_indicator.dart';

class MyQuoteRequestsScreen extends StatefulWidget {
  const MyQuoteRequestsScreen({Key? key}) : super(key: key);

  @override
  _MyQuoteRequestsScreenState createState() => _MyQuoteRequestsScreenState();
}

class _MyQuoteRequestsScreenState extends State<MyQuoteRequestsScreen> {
  String _selectedFilter = 'all'; // Filtre par statut

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Provider.of<QuoteProvider>(context, listen: false).fetchUserQuoteRequests();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ TRADUCTIONS
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myQuoteRequestsTitle), // ✅ TRADUIT
        elevation: 0,
        actions: [
          // ✅ AMÉLIORATION: Bouton de rafraîchissement
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: l10n.refresh, // ✅ TRADUIT
          ),
          // ✅ AMÉLIORATION: Menu de filtres
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Text('${l10n.allServices}'), // Tous
              ),
              PopupMenuItem(
                value: 'pending', 
                child: Text(l10n.pending), // ✅ TRADUIT
              ),
              PopupMenuItem(
                value: 'accepted',
                child: Text(l10n.accepted), // ✅ TRADUIT
              ),
              PopupMenuItem(
                value: 'completed',
                child: Text(l10n.completed), // ✅ TRADUIT
              ),
              PopupMenuItem(
                value: 'rejected',
                child: Text(l10n.rejected), // ✅ TRADUIT
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<QuoteProvider>(
          builder: (context, quoteProvider, _) {
            if (quoteProvider.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingIndicator(),
                    SizedBox(height: 16),
                    Text(
                      l10n.loadingRequests, // ✅ TRADUIT
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            // ✅ AMÉLIORATION: Filtrage des demandes
            List<QuoteRequest> requests = quoteProvider.quoteRequests;
            if (_selectedFilter != 'all') {
              requests = requests.where((request) => request.status == _selectedFilter).toList();
            }
            
            if (requests.isEmpty) {
              return _buildEmptyState(l10n);
            }

            return Column(
              children: [
                // ✅ AMÉLIORATION: Indicateur de filtre actuel
                if (_selectedFilter != 'all')
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${_getFilterLabel(l10n)} (${requests.length})',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'all';
                            });
                          },
                          child: Text('Voir tout'), // TODO: À traduire
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Liste des demandes
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return _buildQuoteRequestCard(request, l10n);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ✅ AMÉLIORATION: État vide avec traductions
  Widget _buildEmptyState(AppLocalizations l10n) {
    String title = l10n.noQuoteRequestsYet;
    String subtitle = l10n.exploreServicesAndRequest;
    
    if (_selectedFilter != 'all') {
      switch (_selectedFilter) {
        case 'pending':
          title = l10n.noPendingRequests;
          break;
        case 'accepted':
          title = l10n.noAcceptedRequests;
          break;
        case 'completed':
          title = l10n.noCompletedRequests;
          break;
        case 'rejected':
          title = l10n.noRequests;
          break;
      }
      subtitle = 'Aucune demande avec ce statut'; // TODO: À traduire
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          if (_selectedFilter != 'all') ...[
            SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'all';
                });
              },
              icon: Icon(Icons.clear_all),
              label: Text('Voir toutes les demandes'), // TODO: À traduire
            ),
          ],
        ],
      ),
    );
  }

  // ✅ AMÉLIORATION: Card de demande avec meilleur design
  Widget _buildQuoteRequestCard(QuoteRequest request, AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(request, l10n),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec sujet et statut
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.subject,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        // ✅ AMÉLIORATION: ID de la demande
                        Text(
                          l10n.requestId( request.id.toString()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  _buildStatusChip(request.status, l10n),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Informations du prestataire et budget
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${l10n.provider}:', // ✅ TRADUIT
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          request.providerName ?? 'Prestataire non assigné',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            request.budget > 0
                                ? l10n.budgetAmount(request.budget.toStringAsFixed(0)) // ✅ TRADUIT
                                : l10n.budgetNotSpecified, // ✅ TRADUIT
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(request.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // ✅ AMÉLIORATION: Description courte si disponible
              if (request.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              
              // ✅ AMÉLIORATION: Bouton d'action
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showRequestDetails(request, l10n),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text(l10n.viewDetails), // ✅ TRADUIT
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ AMÉLIORATION: Statut avec traductions
  Widget _buildStatusChip(String status, AppLocalizations l10n) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = l10n.pending; // ✅ TRADUIT
        break;
      case 'accepted':
        color = Colors.blue;
        label = l10n.accepted; // ✅ TRADUIT
        break;
      case 'completed':
        color = Colors.green;
        label = l10n.completed; // ✅ TRADUIT
        break;
      case 'rejected':
        color = Colors.red;
        label = l10n.rejected; // ✅ TRADUIT
        break;
      default:
        color = Colors.grey;
        label = l10n.unknown; // ✅ TRADUIT
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color:  Colors.orange[800],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ✅ AMÉLIORATION: Modal avec traductions et meilleur design
  void _showRequestDetails(QuoteRequest request, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle pour glisser
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // En-tête avec titre et statut
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.requestDetailsTitle, // ✅ TRADUIT
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          l10n.requestId(request.id.toString()),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(request.status, l10n),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Contenu défilable
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sujet
                      _buildDetailRow(
                        l10n.requestSubject, // ✅ TRADUIT
                        request.subject,
                        Icons.subject,
                      ),
                      
                      // Prestataire
                      _buildDetailRow(
                        l10n.provider, // ✅ TRADUIT
                        request.providerName ?? 'Prestataire non assigné',
                        Icons.business,
                      ),
                      
                      // Date
                      _buildDetailRow(
                        l10n.dateLabel, // ✅ TRADUIT
                        l10n.createdOn( DateFormat('dd/MM/yyyy à HH:mm').format(request.createdAt)),
                        Icons.calendar_today,
                      ),
                      
                      // Budget
                      _buildDetailRow(
                        l10n.budget, // ✅ TRADUIT
                        request.budget > 0
                            ? l10n.budgetAmount( request.budget.toStringAsFixed(0))
                            : l10n.budgetNotSpecified,
                        Icons.account_balance_wallet,
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Description
                      Text(
                        '${l10n.descriptionLabel}:', // ✅ TRADUIT
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          request.description.isNotEmpty 
                              ? request.description 
                              : l10n.notSpecified, // ✅ TRADUIT
                          style: TextStyle(
                            color: request.description.isNotEmpty 
                                ? Colors.grey[800] 
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Bouton de fermeture
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(l10n.closeDetails), // ✅ TRADUIT
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ NOUVEAU: Helper pour les lignes de détail
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NOUVEAU: Helper pour les labels de filtres
  String _getFilterLabel(AppLocalizations l10n) {
    switch (_selectedFilter) {
      case 'pending':
        return l10n.pending;
      case 'accepted':
        return l10n.accepted;
      case 'completed':
        return l10n.completed;
      case 'rejected':
        return l10n.rejected;
      default:
        return 'Tout'; // TODO: À traduire
    }
  }
}