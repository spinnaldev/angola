// lib/ui/screens/provider/add_edit_service_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/subcategory_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/models/service.dart';
import '../../../core/models/subcategory.dart';
import '../../../core/models/user.dart';
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
  
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  String _priceType = 'quote'; // Default to 'Sur devis'
  File? _imageFile;
  bool _isLoading = false;
  bool _isFetchingSubcategories = false;

  List<Subcategory> _availableSubcategories = [];
  List<int> _expertiseCategories = []; // IDs des catégories d'expertise du prestataire

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
    
    // Récupérer les catégories d'expertise du prestataire
    _loadProviderExpertiseCategories();
    
    // Remplir le formulaire si en mode édition
    if (widget.serviceToEdit != null) {
      _titleController.text = widget.serviceToEdit!.title;
      _descriptionController.text = widget.serviceToEdit!.description;
      _priceType = widget.serviceToEdit!.priceType;
      _selectedCategoryId = widget.serviceToEdit!.categoryId;
      _selectedSubcategoryId = widget.serviceToEdit!.subcategoryId;
      
      if (widget.serviceToEdit!.price > 0) {
        _priceController.text = widget.serviceToEdit!.price.toString();
      }
      
      // Charger les sous-catégories de cette catégorie
      if (_selectedCategoryId != null) {
        _loadSubcategoriesForCategory(_selectedCategoryId!);
      }
    }
  }

  Future<void> _loadProviderExpertiseCategories() async {
    try {
      // Récupérer les catégories d'expertise depuis l'API
      final expertiseCategories = await Provider.of<ServiceProvider>(context, listen: false).getProviderExpertiseCategories();
      
      setState(() {
        _expertiseCategories = expertiseCategories;
      });
      
      // Si nous sommes en mode édition, nous avons déjà chargé les sous-catégories
      if (widget.serviceToEdit == null && _expertiseCategories.isNotEmpty) {
        // Par défaut, sélectionner la première catégorie d'expertise
        setState(() {
          _selectedCategoryId = _expertiseCategories.first;
        });
        
        // Charger les sous-catégories pour cette catégorie
        _loadSubcategoriesForCategory(_expertiseCategories.first);
      }
    } catch (e) {
      print('Erreur lors du chargement des catégories d\'expertise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement de vos catégories d\'expertise'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSubcategoriesForCategory(int categoryId) async {
    setState(() {
      _isFetchingSubcategories = true;
      _selectedSubcategoryId = null; // Réinitialiser la sous-catégorie sélectionnée
    });

    try {
      // Récupérer les sous-catégories pour cette catégorie
      final subcategories = await Provider.of<SubcategoryProvider>(context, listen: false).fetchSubcategoriesForCategory(categoryId);
      
      setState(() {
        _availableSubcategories = subcategories;
        _isFetchingSubcategories = false;
      });
      
      // Si nous sommes en mode édition et que la sous-catégorie appartient à cette catégorie, la sélectionner
      if (widget.serviceToEdit != null && 
          _availableSubcategories.any((subcategory) => subcategory.id == widget.serviceToEdit!.subcategoryId)) {
        setState(() {
          _selectedSubcategoryId = widget.serviceToEdit!.subcategoryId;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des sous-catégories: $e');
      setState(() {
        _isFetchingSubcategories = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des sous-catégories'),
          backgroundColor: Colors.red,
        ),
      );
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
    
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedSubcategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une sous-catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceToEdit != null ? 'Modifier le service' : 'Ajouter un service'),
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
                        : widget.serviceToEdit != null && widget.serviceToEdit!.imageUrl.isNotEmpty
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
                  
                  // Sélection de catégorie
                  Text('Catégorie'),
                  SizedBox(height: 8),
                  Consumer<ServiceProvider>(
                    builder: (context, serviceProvider, child) {
                      // S'il n'y a pas de catégories d'expertise, afficher un message
                      if (_expertiseCategories.isEmpty) {
                        return Text(
                          'Vous n\'avez pas encore sélectionné de catégories d\'expertise',
                          style: TextStyle(color: Colors.red),
                        );
                      }
                      
                      return DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        hint: Text('Sélectionner une catégorie'),
                        isExpanded: true,
                        items: _expertiseCategories.map((categoryId) {
                          final category = serviceProvider.getCategoryById(categoryId);
                          return DropdownMenuItem<int>(
                            value: categoryId,
                            child: Text(category?.name ?? 'Catégorie $categoryId'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                          
                          if (value != null) {
                            _loadSubcategoriesForCategory(value);
                          }
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Sélection de sous-catégorie
                  Text('Sous-catégorie'),
                  SizedBox(height: 8),
                  _isFetchingSubcategories
                    ? Center(child: CircularProgressIndicator())
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
                        items: _availableSubcategories.map((subcategory) {
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
                    text: widget.serviceToEdit != null ? 'Mettre à jour' : 'Ajouter le service',
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