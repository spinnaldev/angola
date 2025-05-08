// lib/ui/widgets/quote_request_form.dart - Widget modal pour la demande de devis

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quote_provider.dart';
import '../common/app_button.dart';
import '../common/app_textfield.dart';
import '../widgets/loading_indicator.dart';

class QuoteRequestForm extends StatefulWidget {
  final int providerId;
  final VoidCallback onClose;

  const QuoteRequestForm({
    Key? key,
    required this.providerId,
    required this.onClose,
  }) : super(key: key);

  @override
  _QuoteRequestFormState createState() => _QuoteRequestFormState();
}

class _QuoteRequestFormState extends State<QuoteRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitQuoteRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      
      final budget = _budgetController.text.isNotEmpty 
          ? double.parse(_budgetController.text) 
          : 0.0;
      
      final success = await quoteProvider.createQuoteRequest(
        widget.providerId,
        _subjectController.text,
        budget,
        _descriptionController.text,
      );

      if (mounted) {
        if (success) {
          // Fermer le formulaire
          widget.onClose();
          
          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Demande de devis envoyée avec succès')),
          );
        } else {
          // Afficher un message d'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(quoteProvider.errorMessage ?? 'Erreur lors de l\'envoi de la demande'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onClose, // Ferme le modal si on clique en dehors
        child: Container(
          color: Colors.black54,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Empêche la fermeture si on clique sur le modal
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Demander un devis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    
                    // Formulaire
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Objet de demande'),
                              SizedBox(height: 8),
                              AppTextField(
                                label: 'Objet...',
                                controller: _subjectController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un objet';
                                  }
                                  return null;
                                },
                              ),
                              
                              SizedBox(height: 16),
                              Text('Votre budget'),
                              SizedBox(height: 8),
                              AppTextField(
                                label: 'Budget...',
                                controller: _budgetController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    try {
                                      double.parse(value);
                                    } catch (e) {
                                      return 'Veuillez entrer un montant valide';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              
                              SizedBox(height: 16),
                              Text('Votre demande'),
                              SizedBox(height: 8),
                              AppTextField(
                                label: 'Saisissez une description...',
                                controller: _descriptionController,
                                // maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez décrire votre demande';
                                  }
                                  return null;
                                },
                              ),
                              
                              SizedBox(height: 24),
                              AppButton(
                                text: 'Envoyer',
                                onPressed: _submitQuoteRequest,
                                isLoading: _isSubmitting,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}