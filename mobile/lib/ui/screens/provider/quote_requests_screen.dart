import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ AJOUT
import 'package:teyago/ui/screens/base_screen.dart';
import '../../../providers/quote_provider.dart';
import '../../../core/models/quote_request.dart';
import '../../widgets/loading_indicator.dart';

class QuoteRequestsScreen extends StatefulWidget {
  const QuoteRequestsScreen({Key? key}) : super(key: key);

  @override
  _QuoteRequestsScreenState createState() => _QuoteRequestsScreenState();
}

class _QuoteRequestsScreenState extends State<QuoteRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Provider.of<QuoteProvider>(context, listen: false)
        .fetchUserQuoteRequests();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      currentIndex: 1, // messaging est sélectionné
      body: _buildQuoteContent(),
    );
  }

  Widget _buildQuoteContent() {
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUT

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quoteRequests), // ✅ TRADUIT
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.pending), // ✅ TRADUIT
            Tab(text: l10n.accepted), // ✅ TRADUIT
            Tab(text: l10n.completed), // ✅ TRADUIT
          ],
        ),
      ),
      body: Consumer<QuoteProvider>(
        builder: (context, quoteProvider, _) {
          if (quoteProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          // Filtrer les demandes par statut
          final pendingRequests = quoteProvider.quoteRequests
              .where((request) => request.status == 'pending')
              .toList();

          final acceptedRequests = quoteProvider.quoteRequests
              .where((request) => request.status == 'accepted')
              .toList();

          final completedRequests = quoteProvider.quoteRequests
              .where((request) =>
                  request.status == 'completed' || request.status == 'rejected')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab En attente
              _buildRequestsList(pendingRequests, 'pending', l10n), // ✅ PASSER l10n

              // Tab Acceptées
              _buildRequestsList(acceptedRequests, 'accepted', l10n), // ✅ PASSER l10n

              // Tab Terminées
              _buildRequestsList(completedRequests, 'completed', l10n), // ✅ PASSER l10n
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(List<QuoteRequest> requests, String type, AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
    if (requests.isEmpty) {
      return Center(
        child: Padding( // ✅ AJOUT de padding pour éviter les problèmes d'espace
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _getEmptyStateMessage(type, l10n), // ✅ MÉTHODE TRADUITE
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center, // ✅ AJOUT
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator( // ✅ AJOUT pour pull-to-refresh
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _showRequestDetails(request, l10n), // ✅ PASSER l10n
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.subject,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2, // ✅ AUGMENTÉ pour éviter la troncature
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8), // ✅ AJOUT d'espace
                        _buildStatusChip(request.status, l10n), // ✅ PASSER l10n
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.client}: ${_getClientName(request)}', // ✅ TRADUIT + méthode helper
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded( // ✅ AJOUT pour éviter overflow
                          child: Text(
                            _getBudgetDisplay(request, l10n), // ✅ MÉTHODE TRADUITE
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8), // ✅ AJOUT d'espace
                        Text(
                          DateFormat('dd/MM/yyyy').format(request.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Boutons d'action
                    if (type == 'pending') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _updateRequestStatus(request, 'rejected', l10n), // ✅ PASSER l10n
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(l10n.reject), // ✅ TRADUIT
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _updateRequestStatus(request, 'accepted', l10n), // ✅ PASSER l10n
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white, // ✅ AJOUT
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(l10n.accept), // ✅ TRADUIT
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (type == 'accepted') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateRequestStatus(request, 'completed', l10n), // ✅ PASSER l10n
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white, // ✅ AJOUT
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(l10n.markAsCompleted), // ✅ TRADUIT
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ Méthodes utilitaires pour traduction
  String _getEmptyStateMessage(String type, AppLocalizations l10n) {
    switch (type) {
      case 'pending':
        return l10n.noPendingRequests;
      case 'accepted':
        return l10n.noAcceptedRequests;
      case 'completed':
        return l10n.noCompletedRequests;
      default:
        return l10n.noRequests;
    }
  }

  String _getClientName(QuoteRequest request) {
    // TODO: Récupérer le vrai nom du client depuis l'API
    return 'John Doe'; // Placeholder pour le moment
  }

  String _getBudgetDisplay(QuoteRequest request, AppLocalizations l10n) {
    if (request.budget > 0) {
      return '${l10n.budget}: ${request.budget.toStringAsFixed(0)} AOA';
    } else {
      return '${l10n.budget}: ${l10n.notSpecified}';
    }
  }

  Widget _buildStatusChip(String status, AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showRequestDetails(QuoteRequest request, AppLocalizations l10n) { // ✅ PARAMÈTRE l10n
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ AJOUT pour contenu long
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet( // ✅ AJOUT pour meilleure UX
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView( // ✅ AJOUT pour scroll
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête avec handle de drag
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.requestDetails, // ✅ TRADUIT
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusChip(request.status, l10n),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Titre de la demande
                    Text(
                      l10n.requestSubject, // ✅ TRADUIT
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Informations client et date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.client, // ✅ TRADUIT
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getClientName(request),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.date, // ✅ TRADUIT
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(request.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Budget
                    Text(
                      l10n.budget, // ✅ TRADUIT
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getBudgetDisplay(request, l10n),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      l10n.description, // ✅ TRADUIT
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        request.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Boutons d'action
                    if (request.status == 'pending') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateRequestStatus(request, 'rejected', l10n);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12), // ✅ AJOUT
                              ),
                              child: Text(l10n.reject), // ✅ TRADUIT
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateRequestStatus(request, 'accepted', l10n);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12), // ✅ AJOUT
                              ),
                              child: Text(l10n.accept), // ✅ TRADUIT
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (request.status == 'accepted') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateRequestStatus(request, 'completed', l10n);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12), // ✅ AJOUT
                          ),
                          child: Text(l10n.markAsCompleted), // ✅ TRADUIT
                        ),
                      ),
                    ],
                    
                    // Espace pour le handle de navigation
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateRequestStatus(
      QuoteRequest request, String newStatus, AppLocalizations l10n) async { // ✅ PARAMÈTRE l10n
    try {
      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      final success =
          await quoteProvider.updateQuoteRequestStatus(request.id!, newStatus);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.statusUpdatedSuccessfully), // ✅ TRADUIT
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quoteProvider.errorMessage ??
                l10n.errorUpdatingStatus), // ✅ TRADUIT
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error} ${e.toString()}'), // ✅ TRADUIT
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}