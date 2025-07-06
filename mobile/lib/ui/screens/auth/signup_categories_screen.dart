import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../core/models/category.dart';
import '../../common/app_button.dart';

class SignupCategoriesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const SignupCategoriesScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  _SignupCategoriesScreenState createState() => _SignupCategoriesScreenState();
}

class _SignupCategoriesScreenState extends State<SignupCategoriesScreen> {
  List<int> _selectedCategories = [];
  bool _isLoading = false;
  static const int MAX_CATEGORIES = 5;

  @override
  void initState() {
    super.initState();
    // Charger les catégories depuis l'API au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  void _toggleCategory(int categoryId) {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        if (_selectedCategories.length < MAX_CATEGORIES) {
          _selectedCategories.add(categoryId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.maxCategoriesSelectionLimit(MAX_CATEGORIES)),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  Future<void> _completeRegistration() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectAtLeastOneCategory),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ajouter les catégories sélectionnées aux données utilisateur
      final completeUserData = {
        ...widget.userData,
        'selectedCategories': _selectedCategories,
      };

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Enregistrer l'utilisateur avec les catégories
      final success = await authProvider.registerWithCategories(
        completeUserData['username'],
        completeUserData['email'],
        completeUserData['password'],
        completeUserData['firstName'],
        completeUserData['lastName'],
        completeUserData['phoneNumber'],
        'provider',
        completeUserData['selectedCategories'],
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? l10n.registrationError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.chooseYourDomains,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.expertiseDomains,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.selectUpToCategoriesDescription(MAX_CATEGORIES),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.selectedCategories(_selectedCategories.length, MAX_CATEGORIES),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des catégories
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                if (categoryProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (categoryProvider.categories.isEmpty) {
                  return Center(
                    child: Text(l10n.noCategoriesAvailable),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: categoryProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = categoryProvider.categories[index];
                    final isSelected = _selectedCategories.contains(category.id);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 2 : 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _toggleCategory(category.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Icône de catégorie
                              Icon(
                                _getCategoryIcon(category.id),
                                color: Colors.grey[700],
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              
                              // Infos catégorie
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      category.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Checkbox
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleCategory(category.id),
                                activeColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
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
          ),
          
          // Bouton de validation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142FE2), // Bleu royal
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                    l10n.finishRegistration,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Fonction pour obtenir l'icône appropriée pour chaque catégorie
  IconData _getCategoryIcon(int categoryId) {
    switch(categoryId) {
      case 1: return Icons.home;
      case 2: return Icons.spa;
      case 3: return Icons.event;
      case 4: return Icons.local_shipping;
      case 5: return Icons.favorite;
      case 6: return Icons.work;
      case 7: return Icons.computer;
      case 8: return Icons.pets;
      case 9: return Icons.miscellaneous_services;
      default: return Icons.category;
    }
  }
}