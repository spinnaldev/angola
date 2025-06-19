// mobile/lib/ui/screens/post_project_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/category.dart';
import '../../core/models/subcategory.dart';
import '../../providers/category_provider.dart';
import '../../providers/subcategory_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import 'dart:io';
import '../../core/models/subcategory.dart';

class PostProjectScreen extends StatefulWidget {
  const PostProjectScreen({Key? key}) : super(key: key);

  @override
  State<PostProjectScreen> createState() => _PostProjectScreenState();
}

class _PostProjectScreenState extends State<PostProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Contrôleurs de texte
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();

  // Variables de state
  Category? _selectedCategory;
  Subcategory? _selectedSubcategory;
  String _selectedBudgetRange = 'sur_devis';
  String _selectedUrgency = 'medium';
  bool _remotePossible = false;
  bool _contactViaPlatform = true;
  bool _showEmail = false;
  bool _showPhone = false;
  DateTime? _selectedDeadline;

  // Fichiers
  File? _attachment1;
  File? _attachment2;
  File? _attachment3;

  // Compétences
  final List<String> _requiredSkills = [];
  final _skillController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Déposer un projet',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitProject,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Publier',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 24),
              _buildBudgetSection(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 24),
              _buildTimingSection(),
              const SizedBox(height: 24),
              _buildSkillsSection(),
              const SizedBox(height: 24),
              _buildAttachmentsSection(),
              const SizedBox(height: 24),
              _buildContactPreferencesSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF142FE2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF142FE2).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF6366F1),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Recevez au moins 18 devis en détaillant votre projet',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Informations de base',
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Titre du projet *',
            hintText: 'Ex: Création d\'un site web e-commerce',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le titre est obligatoire';
            }
            if (value.length < 10) {
              return 'Le titre doit contenir au moins 10 caractères';
            }
            return null;
          },
          maxLength: 200,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description détaillée *',
            hintText: 'Décrivez précisément vos besoins, vos attentes...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La description est obligatoire';
            }
            if (value.length < 50) {
              return 'La description doit contenir au moins 50 caractères';
            }
            return null;
          },
          maxLength: 2000,
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return _buildSection(
      title: 'Catégorie',
      children: [
        Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            return DropdownButtonFormField<Category>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Choisir une catégorie *',
                border: OutlineInputBorder(),
              ),
              items: categoryProvider.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (Category? value) {
                setState(() {
                  _selectedCategory = value;
                  _selectedSubcategory = null;
                });
                if (value != null) {
                  _loadSubcategories(value.id);
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez choisir une catégorie';
                }
                return null;
              },
            );
          },
        ),
        const SizedBox(height: 16),
        Consumer<SubcategoryProvider>(
          builder: (context, subcategoryProvider, child) {
            return DropdownButtonFormField<Subcategory>(
              value: _selectedSubcategory,
              decoration: const InputDecoration(
                labelText: 'Sous-catégorie (optionnel)',
                border: OutlineInputBorder(),
              ),
              items: subcategoryProvider.subcategories.map((subcategory) {
                return DropdownMenuItem(
                  value: subcategory,
                  child: Text(subcategory.name),
                );
              }).toList(),
              onChanged: (Subcategory? value) {
                setState(() {
                  _selectedSubcategory = value;
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    return _buildSection(
      title: 'Budget',
      children: [
        DropdownButtonFormField<String>(
          value: _selectedBudgetRange,
          decoration: const InputDecoration(
            labelText: 'Budget approximatif *',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'moins_500', child: Text('Moins de 500 €')),
            DropdownMenuItem(value: '500_1000', child: Text('500 à 1000 €')),
            DropdownMenuItem(
                value: '1000_10000', child: Text('1000 à 10 000 €')),
            DropdownMenuItem(
                value: '10000_plus', child: Text('10 000 € et plus')),
            DropdownMenuItem(
                value: 'sur_devis', child: Text('Demande de devis')),
          ],
          onChanged: (String? value) {
            setState(() {
              _selectedBudgetRange = value!;
            });
          },
        ),
        if (_selectedBudgetRange != 'sur_devis') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _maxBudgetController,
                  decoration: const InputDecoration(
                    labelText: 'Budget max (€)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '99% des clients trouvent un freelance dans leur budget',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _buildSection(
      title: 'Localisation',
      children: [
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Lieu d\'intervention *',
            hintText: 'Ex: Paris, Lyon, France...',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le lieu est obligatoire';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Télétravail possible'),
          subtitle: const Text('Le prestataire peut travailler à distance'),
          value: _remotePossible,
          onChanged: (bool? value) {
            setState(() {
              _remotePossible = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildTimingSection() {
    return _buildSection(
      title: 'Délais et urgence',
      children: [
        DropdownButtonFormField<String>(
          value: _selectedUrgency,
          decoration: const InputDecoration(
            labelText: 'Urgence du projet *',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Pas urgent')),
            DropdownMenuItem(value: 'medium', child: Text('Modérément urgent')),
            DropdownMenuItem(value: 'high', child: Text('Urgent')),
            DropdownMenuItem(value: 'very_high', child: Text('Très urgent')),
          ],
          onChanged: (String? value) {
            setState(() {
              _selectedUrgency = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectDeadline,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date limite souhaitée (optionnel)',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _selectedDeadline != null
                  // ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                  ? '${_selectedDeadline!.year}-${_selectedDeadline!.month}-${_selectedDeadline!.day}'
                  : 'Choisir une date',
              style: TextStyle(
                color: _selectedDeadline != null
                    ? Colors.black87
                    : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return _buildSection(
      title: 'Compétences requises',
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skillController,
                decoration: const InputDecoration(
                  labelText: 'Ajouter une compétence',
                  hintText: 'Ex: PHP, Design graphique...',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: _addSkill,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _addSkill(_skillController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF142FE2),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_requiredSkills.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _requiredSkills.map((skill) {
              return Chip(
                label: Text(skill),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeSkill(skill),
                backgroundColor: const Color(0xFF142FE2).withOpacity(0.1),
                deleteIconColor: const Color(0xFF142FE2),
              );
            }).toList(),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Text(
              'Aucune compétence ajoutée. Les compétences aident les prestataires à mieux comprendre vos besoins.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return _buildSection(
      title: 'Fichiers joints (optionnel)',
      children: [
        const Text(
          'Ajoutez des documents pour mieux expliquer votre projet (cahier des charges, maquettes, etc.)',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        _buildAttachmentTile(
            'Fichier 1', _attachment1, (file) => _attachment1 = file),
        const SizedBox(height: 8),
        _buildAttachmentTile(
            'Fichier 2', _attachment2, (file) => _attachment2 = file),
        const SizedBox(height: 8),
        _buildAttachmentTile(
            'Fichier 3', _attachment3, (file) => _attachment3 = file),
      ],
    );
  }

  Widget _buildAttachmentTile(
      String label, File? file, Function(File?) onFileSelected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            file != null ? Icons.attach_file : Icons.add,
            color: const Color(0xFF142FE2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              file != null ? file.path.split('/').last : label,
              style: TextStyle(
                color: file != null ? Colors.black87 : Colors.grey[600],
                fontWeight: file != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (file != null) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  onFileSelected(null);
                });
              },
              icon: const Icon(Icons.close, color: Colors.red),
            ),
          ],
          TextButton(
            onPressed: () => _pickFile(onFileSelected),
            child: Text(file != null ? 'Changer' : 'Choisir'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPreferencesSection() {
    return _buildSection(
      title: 'Préférences de contact',
      children: [
        CheckboxListTile(
          title: const Text('Messagerie privée de la plateforme'),
          subtitle: const Text('Recommandé pour la sécurité'),
          value: _contactViaPlatform,
          onChanged: (bool? value) {
            setState(() {
              _contactViaPlatform = value ?? true;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Afficher mon adresse email'),
          subtitle: const Text('(sera affiché aux prestataires)'),
          value: _showEmail,
          onChanged: (bool? value) {
            setState(() {
              _showEmail = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Afficher mon numéro de téléphone'),
          subtitle: const Text('(sera affiché aux prestataires)'),
          value: _showPhone,
          onChanged: (bool? value) {
            setState(() {
              _showPhone = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Future<void> _loadSubcategories(int categoryId) async {
    final subcategoryProvider =
        Provider.of<SubcategoryProvider>(context, listen: false);
    await subcategoryProvider.fetchSubcategoriesForCategory(categoryId);
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  void _addSkill(String skill) {
    if (skill.trim().isNotEmpty && !_requiredSkills.contains(skill.trim())) {
      setState(() {
        _requiredSkills.add(skill.trim());
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _requiredSkills.remove(skill);
    });
  }

  Future<void> _pickFile(Function(File?) onFileSelected) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          onFileSelected(File(result.files.first.path!));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
      );
    }
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) {
      // Défiler vers le premier champ avec erreur
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Préparer les données du projet
      final projectData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory!.id,
        'subcategory': _selectedSubcategory?.id,
        'budget_range': _selectedBudgetRange,
        'min_budget': _minBudgetController.text.isNotEmpty
            ? double.parse(_minBudgetController.text)
            : null,
        'max_budget': _maxBudgetController.text.isNotEmpty
            ? double.parse(_maxBudgetController.text)
            : null,
        'location': _locationController.text.trim(),
        'remote_possible': _remotePossible,
        // 'deadline': _selectedDeadline?.toIso8601String(),
        'urgency': _selectedUrgency,
        'contact_via_platform': _contactViaPlatform,
        'show_email': _showEmail,
        'show_phone': _showPhone,
        'required_skills': _requiredSkills
            .map((skill) => {
                  'name': skill,
                  'is_required': true,
                })
            .toList(),
      };

      // Ajouter la date limite si sélectionnée
      if (_selectedDeadline != null) {
        // Format correct YYYY-MM-DD demandé par l'API
        projectData['deadline'] =
            DateFormat('yyyy-MM-dd').format(_selectedDeadline!);
      }

      // Créer le projet
      await apiService.createProject(projectData, [
        _attachment1,
        _attachment2,
        _attachment3,
      ]);

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Projet publié avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      // Retourner à l'écran précédent
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la publication: $e'),
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _skillController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
