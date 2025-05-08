// lib/ui/screens/provider/quote_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/quote_provider.dart';
import '../../../core/models/quote_request.dart';
import '../../widgets/loading_indicator.dart';

class QuoteRequestsScreen extends StatefulWidget {
  const QuoteRequestsScreen({Key? key}) : super(key: key);

  @override
  _QuoteRequestsScreenState createState() => _QuoteRequestsScreenState();
}

class _QuoteRequestsScreenState extends State<QuoteRequestsScreen> with SingleTickerProviderStateMixin {
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
    await Provider.of<QuoteProvider>(context, listen: false).fetchUserQuoteRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demandes de devis'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'En attente'),
            Tab(text: 'Acceptées'),
            Tab(text: 'Terminées'),
          ],
        ),
      ),
      body: Consumer<QuoteProvider>(
        builder: (context, quoteProvider, _) {
          if (quoteProvider.isLoading) {
            return Center(child: LoadingIndicator());
          }

          // Filtrer les demandes par statut
          final pendingRequests = quoteProvider.quoteRequests
              .where((request) => request.status == 'pending')
              .toList();
          
          final acceptedRequests = quoteProvider.quoteRequests
              .where((request) => request.status == 'accepted')
              .toList();
          
          final completedRequests = quoteProvider.quoteRequests
              .where((request) => request.status == 'completed' || request.status == 'rejected')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab En attente
              _buildRequestsList(pendingRequests, 'pending'),
              
              // Tab Acceptées
              _buildRequestsList(acceptedRequests, 'accepted'),
              
              // Tab Terminées
              _buildRequestsList(completedRequests, 'completed'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(List<QuoteRequest> requests, String type) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              type == 'pending'
                  ? 'Aucune demande en attente'
                  : type == 'accepted'
                      ? 'Aucune demande acceptée'
                      : 'Aucune demande terminée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showRequestDetails(request),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          request.subject,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusChip(request.status),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Client: John Doe', // À remplacer par le nom réel du client
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        request.budget > 0
                            ? 'Budget: ${request.budget.toStringAsFixed(0)} FCFA'
                            : 'Budget: Non spécifié',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(request.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  if (type == 'pending') ...[
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateRequestStatus(request, 'rejected'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Rejeter'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateRequestStatus(request, 'accepted'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Accepter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (type == 'accepted') ...[
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _updateRequestStatus(request, 'completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Marquer comme terminé'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'En attente';
        break;
      case 'accepted':
        color = Colors.blue;
        label = 'Acceptée';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Terminée';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejetée';
        break;
      default:
        color = Colors.grey;
        label = 'Inconnu';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  void _showRequestDetails(QuoteRequest request) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Détails de la demande',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(request.status),
                ],
              ),
              SizedBox(height: 16),
              Text(
                request.subject,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Client: John Doe', // À remplacer par le nom réel du client
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(request.createdAt)}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                request.budget > 0
                    ? 'Budget: ${request.budget.toStringAsFixed(0)} FCFA'
                    : 'Budget: Non spécifié',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Description:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(request.description),
              SizedBox(height: 24),
              
              if (request.status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateRequestStatus(request, 'rejected');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Rejeter'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateRequestStatus(request, 'accepted');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Accepter'),
                      ),
                    ),
                  ],
                ),
              
              if (request.status == 'accepted')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateRequestStatus(request, 'completed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Marquer comme terminé'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateRequestStatus(QuoteRequest request, String newStatus) async {
    try {
      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      final success = await quoteProvider.updateQuoteRequestStatus(request.id!, newStatus);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quoteProvider.errorMessage ?? 'Erreur lors de la mise à jour du statut'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}