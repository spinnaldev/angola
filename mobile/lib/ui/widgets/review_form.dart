// lib/ui/widgets/review_form.dart - Widget modal pour laisser un avis

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/review_provider.dart';
import '../common/app_button.dart';
import '../widgets/loading_indicator.dart';

class ReviewForm extends StatefulWidget {
  final int providerId;
  final VoidCallback onClose;

  const ReviewForm({
    Key? key,
    required this.providerId,
    required this.onClose,
  }) : super(key: key);

  @override
  _ReviewFormState createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reviewController = TextEditingController();
  
  int _rating = 0;
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage();
    
    if (pickedImages.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
          pickedImages.map((image) => File(image.path)).toList(),
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez attribuer une note')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      
      final success = await reviewProvider.createReview(
        widget.providerId,
        _rating.toDouble(),
        _reviewController.text,
        _selectedImages,
      );

      if (mounted) {
        if (success) {
          // Fermer le formulaire
          widget.onClose();
          
          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Avis envoyé avec succès')),
          );
        } else {
          // Afficher un message d'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reviewProvider.errorMessage ?? 'Erreur lors de l\'envoi de l\'avis'),
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
                            'Quelle est votre note ?',
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
                    
                    // Formulaire
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Système de notation
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rating = index + 1;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(
                                        index < _rating ? Icons.star : Icons.star_border,
                                        color: index < _rating ? Colors.amber : Colors.grey,
                                        size: 32,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              
                              SizedBox(height: 24),
                              
                              // Commentaire
                              Text(
                                'N\'hésitez pas à partager votre opinion à propos du produit',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              TextFormField(
                                controller: _reviewController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: 'Votre avis',
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.all(16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez saisir votre avis';
                                  }
                                  return null;
                                },
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Ajouter des photos
                              Text(
                                'Ajouter des photos (optionnel)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              
                              // Aperçu des images sélectionnées
                              if (_selectedImages.isNotEmpty)
                                Container(
                                  height: 80,
                                  margin: EdgeInsets.only(bottom: 16),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedImages.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(right: 8),
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: FileImage(_selectedImages[index]),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 8,
                                            top: 0,
                                            child: InkWell(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.7),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.close, size: 16),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              
                              // Bouton pour ajouter des photos
                              OutlinedButton.icon(
                                onPressed: _pickImages,
                                icon: Icon(Icons.camera_alt),
                                label: Text('Ajouter des photos'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).primaryColor,
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: 24),
                              
                              // Bouton d'envoi
                              AppButton(
                                text: 'ENVOYER UN AVIS',
                                onPressed: _submitReview,
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