import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/completed_work_provider.dart';
import '../../../core/models/subcategory.dart';
import '../../widgets/loading_indicator.dart';

class AddWorkScreen extends StatefulWidget {
  const AddWorkScreen({Key? key}) : super(key: key);

  @override
  _AddWorkScreenState createState() => _AddWorkScreenState();
}

class _AddWorkScreenState extends State<AddWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs de texte
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientContactController = TextEditingController();
  
  // Données du formulaire
  DateTime _completionDate = DateTime.now();
  Subcategory? _selectedSubcategory;
  
  // Images et légendes
  final List<File> _selectedImages = [];
  final List<String> _imageCaptions = [];
  final _captionControllers = <TextEditingController>[];
  
  // État de chargement
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _clientNameController.dispose();
    _clientContactController.dispose();
    
    for (var controller in _captionControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  // Charger les catégories pour le sélecteur
  Future<void> _loadCategories() async {
    await Provider.of<CategoriesProvider>(context, listen: false).fetchCategories();
  }

  // Sélectionner la date de réalisation
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _completionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null && pickedDate != _completionDate) {
      setState(() {
        _completionDate = pickedDate;
      });
    }
  }

  // Sélectionner des images depuis la galerie
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          if (_selectedImages.length < 10) { // Maximum 10 images
            _selectedImages.add(File(image.path));
            _imageCaptions.add('');
            _captionControllers.add(TextEditingController());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 10 images autorisées'),
                backgroundColor: Colors.red,
              ),
            );
            break;
          }
        }
      });
    }
  }

  // Supprimer une image
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageCaptions.removeAt(index);
      final controller = _captionControllers.removeAt(index);
      controller.dispose();
    });
  }

  // Soumettre le formulaire
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins une image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Mettre à jour les légendes depuis les contrôleurs
      for (int i = 0; i < _captionControllers.length; i++) {
        _imageCaptions[i] = _captionControllers[i].text;
      }
      
      final result = await Provider.of<CompletedWorkProvider>(
        context,
        listen: false,
      ).createCompletedWork(
        _titleController.text,
        _descriptionController.text,
        _locationController.text,
        _completionDate,
        _selectedSubcategory!.id,
        _clientNameController.text,
        _clientContactController.text,
        _selectedImages,
        _imageCaptions,
      );
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Travail ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<CompletedWorkProvider>(context, listen: false)
                      .errorMessage ??
                  'Erreur lors de l\'ajout du travail',
            ),
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un travail effectué'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Consumer<CategoriesProvider>(
            builder: (context, categoriesProvider, _) {
              final subcategories = categoriesProvider.subcategories;
              
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations du travail',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ: Titre
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre du travail',
                          hintText: 'Ex: Rénovation complète d\'une salle de bain',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un titre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ: Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Décrivez le travail que vous avez réalisé',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer une description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ: Lieu
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Lieu',
                          hintText: 'Ex: Cotonou, Bénin',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un lieu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ: Date de réalisation
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de réalisation',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMMM yyyy').format(_completionDate),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ: Catégorie
                      DropdownButtonFormField<Subcategory>(
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Sélectionnez une catégorie'),
                        value: _selectedSubcategory,
                        items: subcategories.map((subcategory) {
                          return DropdownMenuItem<Subcategory>(
                            value: subcategory,
                            child: Text(subcategory.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubcategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ: Nom du client
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du client',
                          hintText: 'Ex: Jean Dupont',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le nom du client';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Champ: Contact du client
                      TextFormField(
                        controller: _clientContactController,
                        decoration: const InputDecoration(
                          labelText: 'Contact du client',
                          hintText: 'Ex: contact@example.com ou +229 97123456',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le contact du client';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Section: Images
                      const Text(
                        'Images du travail',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez au moins une image et jusqu\'à 10 images montrant votre travail. La première image sera utilisée comme aperçu.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Bouton pour ajouter des images
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Ajouter des images'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Afficher les images sélectionnées
                      if (_selectedImages.isNotEmpty) ...[
                        Text(
                          '${_selectedImages.length} image(s) sélectionnée(s)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            if (_captionControllers.length <= index) {
                              _captionControllers.add(TextEditingController());
                            }
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.file(
                                            _selectedImages[index],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Image ${index + 1}${index == 0 ? ' (principale)' : ''}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _selectedImages[index].path.split('/').last,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _removeImage(index),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _captionControllers[index],
                                      decoration: const InputDecoration(
                                        labelText: 'Légende (facultative)',
                                        hintText: 'Ajouter une description pour cette image',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLength: 100,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Bouton de soumission
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: const Text(
                            'Ajouter ce travail',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Indicateur de chargement
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: LoadingIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}