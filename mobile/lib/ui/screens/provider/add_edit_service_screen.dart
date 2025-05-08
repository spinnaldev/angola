// lib/ui/screens/provider/add_edit_service_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/subcategory_provider.dart';
import '../../../core/models/service.dart';
import '../../../core/models/subcategory.dart';
import '../../widgets/loading_indicator.dart';
import '../../common/app_button.dart';
import '../../common/app_textfield.dart';

class AddEditServiceScreen extends StatefulWidget {
  final Service? serviceToEdit;

  const AddEditServiceScreen({Key? key, this.serviceToEdit}) : super(key: key);

  @override
  _AddEditServiceScreenState createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  int? _selectedSubcategoryId;
  String _priceType = 'quote'; // Default to 'Sur devis'
  File? _imageFile;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _priceTypes = [
    {'value': 'fixed', 'label': 'Prix fixe'},
    {'value': 'hourly', 'label': 'Prix horaire'},
    {'value': 'daily', 'label': 'Prix journalier'},
    {'value': 'negotiable', 'label': 'Prix négociable'},
    {'value': 'quote', 'label': 'Sur devis'},
  ];

  @override
  void initState() {

    super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubcategoryProvider>(context, listen: false).fetchAllSubcategories();
      
      // Debug pour voir si ça fonctionne
      print("Chargement des sous-catégories...");
    });
    // Remplir le formulaire si en mode édition
    if (widget.serviceToEdit != null) {
      _titleController.text = widget.serviceToEdit!.title;
      _descriptionController.text = widget.serviceToEdit!.description;
      _priceType = widget.serviceToEdit!.priceType;
      
      if (widget.serviceToEdit!.price > 0) {
        _priceController.text = widget.serviceToEdit!.price.toString();
      }
      
      // L'ID de la sous-catégorie sera défini lors du chargement des données
      _selectedSubcategoryId = widget.serviceToEdit!.subcategoryId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedSubcategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner une sous-catégorie')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {

    print("Début de la sauvegarde du service");
    print("Image sélectionnée: ${_imageFile != null ? 'Oui' : 'Non'}");
    
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      final double price = _priceController.text.isEmpty ? 0.0 : double.parse(_priceController.text);
      
      if (widget.serviceToEdit == null) {
        // Ajouter un nouveau service
        await serviceProvider.addService(
          _titleController.text,
          _descriptionController.text,
          _selectedSubcategoryId!,
          price,
          _priceType,
          _imageFile,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Service ajouté avec succès')),
          );
          Navigator.pop(context);
        }
      } else {
        // Mettre à jour un service existant
        await serviceProvider.updateService(
          widget.serviceToEdit!.id,
          _titleController.text,
          _descriptionController.text,
          _selectedSubcategoryId!,
          price,
          _priceType,
          _imageFile,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Service mis à jour avec succès')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subcategoryProvider = Provider.of<SubcategoryProvider>(context);
    final isEditing = widget.serviceToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le service' : 'Ajouter un service'),
        elevation: 0,
      ),
      body: _isLoading
        ? Center(child: LoadingIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image du service
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : isEditing && widget.serviceToEdit!.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.serviceToEdit!.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 48,
                                  color: Colors.grey[500],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ajouter une image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Champ titre
                  AppTextField(
                    label: 'Titre du service',
                    controller: _titleController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un titre';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Sélection de sous-catégorie
                  Text('Sous-catégorie'),
                  SizedBox(height: 8),
                  subcategoryProvider.isLoading
                    ? LoadingIndicator(size: 24)
                    : DropdownButtonFormField<int>(
                        value: _selectedSubcategoryId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        hint: Text('Sélectionner une sous-catégorie'),
                        isExpanded: true,
                        
                        items: subcategoryProvider.subcategories.map((subcategory) {
                          return DropdownMenuItem<int>(
                            value: subcategory.id,
                            child: Text(subcategory.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubcategoryId = value;
                          });
                        },
                      ),
                  SizedBox(height: 16),
                  
                  // Description
                  AppTextField(
                    label: 'Description',
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    // maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Type de prix
                  Text('Type de prix'),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _priceType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    isExpanded: true,
                    items: _priceTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['label']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _priceType = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Prix (affiché uniquement si le type n'est pas 'Sur devis')
                  if (_priceType != 'quote')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Prix (FCFA)',
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_priceType != 'quote' && (value == null || value.isEmpty)) {
                              return 'Veuillez entrer un prix';
                            }
                            if (value != null && value.isNotEmpty) {
                              try {
                                double.parse(value);
                              } catch (e) {
                                return 'Veuillez entrer un prix valide';
                              }
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  
                  // Bouton de sauvegarde
                  AppButton(
                    text: isEditing ? 'Mettre à jour' : 'Ajouter le service',
                    onPressed: _saveService,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
    );
  }
}