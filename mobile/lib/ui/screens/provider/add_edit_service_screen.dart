// lib/ui/screens/provider/add_edit_service_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/service_option.dart';
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
  List<File> _galleryImageFiles = [];
  List<String> _imageCaptions = [];
  List<TextEditingController> _captionControllers = [];

  List<ServiceOption> _serviceOptions = [];

  List<Subcategory> _availableSubcategories = [];
  List<int> _expertiseCategories =
      []; // IDs des catégories d'expertise du prestataire

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

      // Si en mode édition, initialiser les options
      if (widget.serviceToEdit != null) {
        _serviceOptions = List.from(widget.serviceToEdit!.options);
      }
    }
  }

  Future<void> _loadProviderExpertiseCategories() async {
    try {
      // Récupérer les catégories d'expertise depuis l'API
      final expertiseCategories =
          await Provider.of<ServiceProvider>(context, listen: false)
              .getProviderExpertiseCategories();

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
          content:
              Text('Erreur lors du chargement de vos catégories d\'expertise'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSubcategoriesForCategory(int categoryId) async {
    setState(() {
      _isFetchingSubcategories = true;
      _selectedSubcategoryId =
          null; // Réinitialiser la sous-catégorie sélectionnée
    });

    try {
      // Récupérer les sous-catégories pour cette catégorie
      final subcategories =
          await Provider.of<SubcategoryProvider>(context, listen: false)
              .fetchSubcategoriesForCategory(categoryId);

      setState(() {
        _availableSubcategories = subcategories;
        _isFetchingSubcategories = false;
      });

      // Si nous sommes en mode édition et que la sous-catégorie appartient à cette catégorie, la sélectionner
      if (widget.serviceToEdit != null &&
          _availableSubcategories.any((subcategory) =>
              subcategory.id == widget.serviceToEdit!.subcategoryId)) {
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

  Future<void> _pickGalleryImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _galleryImageFiles.add(File(pickedImage.path));
        _imageCaptions.add('');
        _captionControllers.add(TextEditingController());
      });
    }
  }

  // Méthode pour supprimer une image
  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImageFiles.removeAt(index);
      _imageCaptions.removeAt(index);
      final controller = _captionControllers.removeAt(index);
      controller.dispose();
    });
  }

  // Méthode pour ajouter une option
  void _addServiceOption() {
    setState(() {
      _serviceOptions.add(
        ServiceOption(
          name: '',
          description: '',
          isIncluded: true,
        ),
      );
    });
  }

  // Méthode pour supprimer une option
  void _removeServiceOption(int index) {
    setState(() {
      _serviceOptions.removeAt(index);
    });
  }

  // Méthode pour mettre à jour une option
  void _updateServiceOption(int index, ServiceOption updatedOption) {
    setState(() {
      _serviceOptions[index] = updatedOption;
    });
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
    final totalGalleryImages = _galleryImageFiles.length +
        (widget.serviceToEdit?.galleryImages.length ?? 0);

    if (totalGalleryImages == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez ajouter au moins une image à la galerie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (totalGalleryImages > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous ne pouvez pas ajouter plus de 10 images'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


    // Validation des options seulement si elles existent
    for (int i = 0; i < _serviceOptions.length; i++) {
      final option = _serviceOptions[i];
      
      // Si une option a un nom, elle doit avoir au minimum une description
      if (option.name.isNotEmpty && option.description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('L\'option "${option.name}" doit avoir une description'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Si l'option n'est pas incluse et a un nom, elle doit avoir un prix
      if (option.name.isNotEmpty && !option.isIncluded && (option.price == null || option.price! <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('L\'option "${option.name}" doit avoir un prix car elle n\'est pas incluse'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });
    for (int i = 0; i < _captionControllers.length; i++) {
      _imageCaptions[i] = _captionControllers[i].text;
    }
    try {
      final serviceProvider =
          Provider.of<ServiceProvider>(context, listen: false);
      final double price = _priceController.text.isEmpty
          ? 0.0
          : double.parse(_priceController.text);

      // Filtrer les options valides (celles qui ont au moins un nom)
      final validOptions = _serviceOptions
        .where((option) => option.name.isNotEmpty)
        .toList();

      if (widget.serviceToEdit == null) {
        // Ajouter un nouveau service
        await serviceProvider.addService(
          _titleController.text,
          _descriptionController.text,
          _selectedSubcategoryId!,
          price,
          _priceType,
          _imageFile,
          _galleryImageFiles,
          _imageCaptions,
          validOptions, 
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
          _galleryImageFiles,
          _imageCaptions,
          validOptions,
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
        title: Text(widget.serviceToEdit != null
            ? 'Modifier le travail'
            : 'Ajouter un travail éffectué'),
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
                    // Section d'image principale (existant)
                    Text(
                      'Image principale',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),

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
                            : widget.serviceToEdit != null &&
                                    widget.serviceToEdit!.imageUrl.isNotEmpty
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
                                        'Ajouter une image principale',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Section informations de base
                    Text(
                      'Informations de base',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

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
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          hint: Text('Sélectionner une catégorie'),
                          isExpanded: true,
                          items: _expertiseCategories.map((categoryId) {
                            final category =
                                serviceProvider.getCategoryById(categoryId);
                            return DropdownMenuItem<int>(
                              value: categoryId,
                              child: Text(
                                  category?.name ?? 'Catégorie $categoryId'),
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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            label: 'Prix (AOA)',
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_priceType != 'quote' &&
                                  (value == null || value.isEmpty)) {
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

                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Galerie d\'images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _galleryImageFiles.length < 10
                              ? _pickGalleryImage
                              : null,
                          icon: Icon(Icons.add_photo_alternate),
                          label: Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ajoutez entre 1 et 10 images pour votre galerie (${_galleryImageFiles.length}/10)',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Liste des images de galerie
                    if (_galleryImageFiles.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _galleryImageFiles.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color : Colors.white,
                            margin: EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _galleryImageFiles[index],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Image ${index + 1}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              _galleryImageFiles[index]
                                                  .path
                                                  .split('/')
                                                  .last,
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
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _removeGalleryImage(index),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  TextField(
                                    controller: _captionControllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Légende (optionnelle)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Images existantes (en mode édition)
                    if (widget.serviceToEdit != null &&
                        widget.serviceToEdit!.galleryImages.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Images existantes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount:
                                widget.serviceToEdit!.galleryImages.length,
                            itemBuilder: (context, index) {
                              final image =
                                  widget.serviceToEdit!.galleryImages[index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      image.imageUrl ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: Icon(Icons.broken_image,
                                              color: Colors.grey[500]),
                                        );
                                      },
                                    ),
                                    if (image.caption.isNotEmpty)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          color: Colors.black.withOpacity(0.5),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 8),
                                          child: Text(
                                            image.caption,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                    // Section des options de service
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Options du service',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addServiceOption,
                          icon: Icon(Icons.add),
                          label: Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ajoutez des options ou caractéristiques incluses dans votre service',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Liste des options
                    if (_serviceOptions.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _serviceOptions.length,
                        itemBuilder: (context, index) {
                          return _buildServiceOptionItem(
                              index, _serviceOptions[index]);
                        },
                      )
                    else
                      Center(
                        child: Text(
                          'Aucune option ajoutée',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    // Bouton de sauvegarde
                    SizedBox(height: 32),
                    // Bouton de sauvegarde
                    AppButton(
                      text: widget.serviceToEdit != null
                          ? 'Mettre à jour'
                          : 'Ajouter le travail',
                      onPressed: _saveService,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget pour les options de service
  Widget _buildServiceOptionItem(int index, ServiceOption option) {
    // Utiliser des contrôleurs pour chaque option
    final nameController = TextEditingController(text: option.name);
    final descriptionController =
        TextEditingController(text: option.description);
    final priceController = TextEditingController(
      text: option.price?.toString() ?? '',
    );

    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Option ${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeServiceOption(index),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom de l\'option',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _updateServiceOption(
                  index,
                  ServiceOption(
                    id: option.id,
                    name: value,
                    description: option.description,
                    price: option.price,
                    isIncluded: option.isIncluded,
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) {
                _updateServiceOption(
                  index,
                  ServiceOption(
                    id: option.id,
                    name: option.name,
                    description: value,
                    price: option.price,
                    isIncluded: option.isIncluded,
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: option.isIncluded,
                  onChanged: (value) {
                    _updateServiceOption(
                      index,
                      ServiceOption(
                        id: option.id,
                        name: option.name,
                        description: option.description,
                        price: option.price,
                        isIncluded: value ?? true,
                      ),
                    );
                  },
                ),
                Text('Option incluse dans le prix de base'),
              ],
            ),
            if (!option.isIncluded) ...[
              SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Prix supplémentaire (AOA)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _updateServiceOption(
                    index,
                    ServiceOption(
                      id: option.id,
                      name: option.name,
                      description: option.description,
                      price: value.isEmpty ? null : double.tryParse(value),
                      isIncluded: option.isIncluded,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
