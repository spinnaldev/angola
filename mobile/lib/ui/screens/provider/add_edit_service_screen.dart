// lib/ui/screens/provider/add_edit_service_screen.dart - Version internationalisée
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ AJOUTÉ
import '../../../core/models/service_option.dart';
import '../../../providers/language_provider.dart';
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
  List<int> _expertiseCategories = [];

  // Types de prix dynamiques selon la langue
  List<Map<String, dynamic>> _getPriceTypes(AppLocalizations l10n) {
    return [
      {'value': 'fixed', 'label': l10n.fixedPrice},
      {'value': 'hourly', 'label': l10n.hourlyPrice},
      {'value': 'daily', 'label': l10n.dailyPrice},
      {'value': 'negotiable', 'label': l10n.negotiablePrice},
      {'value': 'quote', 'label': l10n.onQuote},
    ];
  }

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
    final l10n = AppLocalizations.of(context)!;
    
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
          content: Text(l10n.errorLoadingExpertiseCategories),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSubcategoriesForCategory(int categoryId) async {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() {
      _isFetchingSubcategories = true;
      _selectedSubcategoryId = null;
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
          content: Text(l10n.errorLoadingSubcategories),
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

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImageFiles.removeAt(index);
      _imageCaptions.removeAt(index);
      final controller = _captionControllers.removeAt(index);
      controller.dispose();
    });
  }

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

  void _removeServiceOption(int index) {
    setState(() {
      _serviceOptions.removeAt(index);
    });
  }

  void _updateServiceOption(int index, ServiceOption updatedOption) {
    setState(() {
      _serviceOptions[index] = updatedOption;
    });
  }

  Future<void> _saveService() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectCategory),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSubcategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectSubcategory),
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
          content: Text(l10n.pleaseAddAtLeastOneGalleryImage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (totalGalleryImages > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotAddMoreThan10Images),
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
            content: Text(l10n.optionMustHaveDescription(option.name)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Si l'option n'est pas incluse et a un nom, elle doit avoir un prix
      if (option.name.isNotEmpty && !option.isIncluded && (option.price == null || option.price! <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.optionMustHavePrice(option.name)),
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
            SnackBar(content: Text(l10n.serviceAddedSuccessfully)),
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
            SnackBar(content: Text(l10n.serviceUpdatedSuccessfully)),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: ${e.toString()}')),
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
    final l10n = AppLocalizations.of(context)!; // ✅ AJOUTÉ
    final priceTypes = _getPriceTypes(l10n);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceToEdit != null
            ? l10n.editService // ✅ MODIFIÉ
            : l10n.addCompletedWork), // ✅ MODIFIÉ
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
                    // Section d'image principale
                    Text(
                      l10n.mainImage, // ✅ MODIFIÉ
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
                                        l10n.addMainImage, // ✅ MODIFIÉ
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
                      l10n.basicInformation, // ✅ MODIFIÉ
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Champ titre
                    AppTextField(
                      label: l10n.serviceTitle, // ✅ MODIFIÉ
                      controller: _titleController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterTitle; // ✅ MODIFIÉ
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Sélection de catégorie
                    Text(l10n.category), // ✅ MODIFIÉ
                    SizedBox(height: 8),
                    Consumer<ServiceProvider>(
                      builder: (context, serviceProvider, child) {
                        // S'il n'y a pas de catégories d'expertise, afficher un message
                        if (_expertiseCategories.isEmpty) {
                          return Text(
                            l10n.noExpertiseCategoriesSelected, // ✅ MODIFIÉ
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
                          hint: Text(l10n.selectCategory), // ✅ MODIFIÉ
                          isExpanded: true,
                          items: _expertiseCategories.map((categoryId) {
                            final category =
                                serviceProvider.getCategoryById(categoryId);
                            return DropdownMenuItem<int>(
                              value: categoryId,
                              child: Text(
                                  category?.getLocalizedName(
                                    Provider.of<LanguageProvider>(context, listen: false).currentLocale.languageCode
                                  )  ?? '${l10n.category} $categoryId'),
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
                    Text(l10n.subcategory), // ✅ MODIFIÉ
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
                            hint: Text(l10n.selectSubcategory), // ✅ MODIFIÉ
                            isExpanded: true,
                            items: _availableSubcategories.map((subcategory) {
                              return DropdownMenuItem<int>(
                                value: subcategory.id,
                                child: Text(subcategory.getLocalizedName(
                                  Provider.of<LanguageProvider>(context, listen: false).currentLocale.languageCode
                                )),
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
                      label: l10n.description, // ✅ MODIFIÉ
                      controller: _descriptionController,
                      keyboardType: TextInputType.multiline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterDescription; // ✅ MODIFIÉ
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Type de prix
                    Text(l10n.priceType), // ✅ MODIFIÉ
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
                      items: priceTypes.map((type) {
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
                            label: l10n.priceAOA, // ✅ MODIFIÉ
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_priceType != 'quote' &&
                                  (value == null || value.isEmpty)) {
                                return l10n.pleaseEnterPrice; // ✅ MODIFIÉ
                              }
                              if (value != null && value.isNotEmpty) {
                                try {
                                  double.parse(value);
                                } catch (e) {
                                  return l10n.pleaseEnterValidPrice; // ✅ MODIFIÉ
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
                          l10n.imageGallery, // ✅ MODIFIÉ
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
                          label: Text(l10n.add), // ✅ MODIFIÉ
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      l10n.galleryImageDescription(_galleryImageFiles.length), // ✅ MODIFIÉ
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
                                              l10n.imageNumber(index + 1), // ✅ MODIFIÉ
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
                                      labelText: l10n.optionalCaption, // ✅ MODIFIÉ
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
                            l10n.existingImages, // ✅ MODIFIÉ
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
                          l10n.serviceOptions, // ✅ MODIFIÉ
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addServiceOption,
                          icon: Icon(Icons.add),
                          label: Text(l10n.add), // ✅ MODIFIÉ
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      l10n.serviceOptionsDescription, // ✅ MODIFIÉ
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
                              index, _serviceOptions[index], l10n);
                        },
                      )
                    else
                      Center(
                        child: Text(
                          l10n.noOptionsAdded, // ✅ MODIFIÉ
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    // Bouton de sauvegarde
                    SizedBox(height: 32),
                    AppButton(
                      text: widget.serviceToEdit != null
                          ? l10n.update // ✅ MODIFIÉ
                          : l10n.addWork, // ✅ MODIFIÉ
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
  Widget _buildServiceOptionItem(int index, ServiceOption option, AppLocalizations l10n) {
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
                  l10n.optionNumber(index + 1), // ✅ MODIFIÉ
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
                labelText: l10n.optionName, // ✅ MODIFIÉ
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
                labelText: l10n.description, // ✅ MODIFIÉ
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
                Expanded(child: Text(l10n.optionIncludedInBasePrice)), // ✅ MODIFIÉ
              ],
            ),
            if (!option.isIncluded) ...[
              SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: l10n.additionalPriceAOA, // ✅ MODIFIÉ
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