// mobile/lib/ui/screens/post_project_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import ajouté
import '../../core/models/category.dart';
import '../../core/models/subcategory.dart';
import '../../providers/category_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/subcategory_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import 'dart:io';

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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.postProject,
          style: const TextStyle(
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
                : Text(
                    l10n.publish,
                    style: const TextStyle(
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
              // _buildContactPreferencesSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final l10n = AppLocalizations.of(context)!;
    
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
          Expanded(
            child: Text(
              l10n.receiveQuotesDetail,
              style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
    
    return _buildSection(
      title: l10n.basicInformation,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: l10n.projectTitle,
            hintText: l10n.projectTitleHint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.titleRequired;
            }
            if (value.length < 10) {
              return l10n.titleMinLength;
            }
            return null;
          },
          maxLength: 200,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: l10n.detailedDescription,
            hintText: l10n.detailedDescriptionHint,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.descriptionRequired;
            }
            if (value.length < 50) {
              return l10n.descriptionMinLength;
            }
            return null;
          },
          maxLength: 2000,
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    final l10n = AppLocalizations.of(context)!;
    
    return _buildSection(
      title: l10n.category,
      children: [
        Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            return DropdownButtonFormField<Category>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: l10n.chooseCategory,
                border: const OutlineInputBorder(),
              ),
              items: categoryProvider.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.getLocalizedName(
                    Provider.of<LanguageProvider>(context, listen: false).currentLocale.languageCode
                  )),
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
                  return l10n.chooseCategoryValidation;
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    final l10n = AppLocalizations.of(context)!;
    
    return _buildSection(
      title: l10n.budget,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedBudgetRange,
          decoration: InputDecoration(
            labelText: l10n.approximateBudget,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
                value: 'moins_500', child: Text(l10n.lessThan500)),
            DropdownMenuItem(value: '500_1000', child: Text(l10n.between500And1000)),
            DropdownMenuItem(
                value: '1000_10000', child: Text(l10n.between1000And10000)),
            DropdownMenuItem(
                value: '10000_plus', child: Text(l10n.moreThan10000)),
            DropdownMenuItem(
                value: 'sur_devis', child: Text(l10n.requestQuote)),
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
                  decoration: InputDecoration(
                    labelText: l10n.maxBudget,
                    border: const OutlineInputBorder(),
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
              const Icon(Icons.star, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.budgetTip,
                  style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
    
    return _buildSection(
      title: l10n.location,
      children: [
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: l10n.interventionLocation,
            hintText: l10n.locationHint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.locationRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: Text(l10n.remoteWorkPossible),
          subtitle: Text(l10n.remoteWorkDescription),
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
    final l10n = AppLocalizations.of(context)!;
    
    return _buildSection(
      title: l10n.timingUrgency,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedUrgency,
          decoration: InputDecoration(
            labelText: l10n.projectUrgency,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'low', child: Text(l10n.notUrgent)),
            DropdownMenuItem(value: 'medium', child: Text(l10n.moderatelyUrgent)),
            DropdownMenuItem(value: 'high', child: Text(l10n.urgent)),
            DropdownMenuItem(value: 'very_high', child: Text(l10n.veryUrgent)),
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
            decoration: InputDecoration(
              labelText: l10n.desiredDeadline,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
              _selectedDeadline != null
                  // ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                  ? '${_selectedDeadline!.year}-${_selectedDeadline!.month}-${_selectedDeadline!.day}'
                  : l10n.chooseDate,
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
    final l10n = AppLocalizations.of(context)!;
    
    return _buildSection(
      title: l10n.requiredSkills,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skillController,
                decoration: InputDecoration(
                  labelText: l10n.addSkill,
                  hintText: l10n.skillHint,
                  border: const OutlineInputBorder(),
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
              child: Text(l10n.add),
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
            child: Text(
              l10n.noSkillsAdded,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    final l10n = AppLocalizations.of(context)!;
    
    return _buildSection(
      title: l10n.attachments,
      children: [
        Text(
          l10n.attachmentsDescription,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        _buildAttachmentTile(
            l10n.file1, _attachment1, (file) => _attachment1 = file),
        // const SizedBox(height: 8),
        // _buildAttachmentTile(
        //     l10n.file2, _attachment2, (file) => _attachment2 = file),
        // const SizedBox(height: 8),
        // _buildAttachmentTile(
        //     l10n.file3, _attachment3, (file) => _attachment3 = file),
      ],
    );
  }

  Widget _buildAttachmentTile(
      String label, File? file, Function(File?) onFileSelected) {
    final l10n = AppLocalizations.of(context)!;
    
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
            child: Text(file != null ? l10n.change : l10n.choose),
          ),
        ],
      ),
    );
  }

  // Widget _buildContactPreferencesSection() {
  //   final l10n = AppLocalizations.of(context)!;
  //   
  //   return _buildSection(
  //     title: l10n.contactPreferences,
  //     children: [
  //       CheckboxListTile(
  //         title: Text(l10n.platformPrivateMessaging),
  //         subtitle: Text(l10n.recommendedForSecurity),
  //         value: _contactViaPlatform,
  //         onChanged: (bool? value) {
  //           setState(() {
  //             _contactViaPlatform = value ?? true;
  //           });
  //         },
  //         controlAffinity: ListTileControlAffinity.leading,
  //       ),
  //       CheckboxListTile(
  //         title: Text(l10n.showEmailAddress),
  //         subtitle: Text(l10n.emailVisibleToProviders),
  //         value: _showEmail,
  //         onChanged: (bool? value) {
  //           setState(() {
  //             _showEmail = value ?? false;
  //           });
  //         },
  //         controlAffinity: ListTileControlAffinity.leading,
  //       ),
  //       CheckboxListTile(
  //         title: Text(l10n.showPhoneNumber),
  //         subtitle: Text(l10n.phoneVisibleToProviders),
  //         value: _showPhone,
  //         onChanged: (bool? value) {
  //           setState(() {
  //             _showPhone = value ?? false;
  //           });
  //         },
  //         controlAffinity: ListTileControlAffinity.leading,
  //       ),
  //     ],
  //   );
  // }

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
    final l10n = AppLocalizations.of(context)!;
    
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
        SnackBar(content: Text(l10n.fileSelectionError(e.toString()))),
      );
    }
  }

  Future<void> _submitProject() async {
    final l10n = AppLocalizations.of(context)!;
    
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
        SnackBar(
          content: Text(l10n.projectPublishedSuccess),
          backgroundColor: Colors.green,
        ),
      );

      // Retourner à l'écran précédent
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.publishingError(e.toString())),
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