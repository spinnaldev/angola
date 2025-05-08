// lib/ui/screens/client/my_quote_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/quote_provider.dart';
import '../../../core/models/quote_request.dart';
import '../../widgets/loading_indicator.dart';

class MyQuoteRequestsScreen extends StatefulWidget {
  const MyQuoteRequestsScreen({Key? key}) : super(key: key);

  @override
  _MyQuoteRequestsScreenState createState() => _MyQuoteRequestsScreenState();
}

class _MyQuoteRequestsScreenState extends State<MyQuoteRequestsScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes demandes de devis'),
        elevation: 0,
      ),
      body: Consumer<QuoteProvider>(
        builder: (context, quoteProvider, _) {
          if (quoteProvider.isLoading) {
            return Center(child: LoadingIndicator());
          }

          final requests = quoteProvider.quoteRequests;
          
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
                    'Vous n\'avez pas encore de demandes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Explorez les services et faites vos premières demandes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
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
                          'Prestataire: Nom du prestataire', // À remplacer par le nom réel
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
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
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
                'Prestataire: Nom du prestataire', // À remplacer par le nom réel
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
            ],
          ),
        );
      },
    );
  }
}