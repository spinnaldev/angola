// lib/ui/widgets/subcategory_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/subcategory.dart';
import '../../providers/language_provider.dart';

class SubcategoryTab extends StatelessWidget {
  final Subcategory subcategory;
  final bool isSelected;
  final VoidCallback onTap;

  const SubcategoryTab({
    Key? key,
    required this.subcategory,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Style pour les onglets dans l'Image 1 (style souligné en bleu)
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF142FE2) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          subcategory.getLocalizedName(
            Provider.of<LanguageProvider>(context, listen: false).currentLocale.languageCode
          ),
          style: TextStyle(
            color: isSelected ? const Color(0xFF142FE2) : Colors.black,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}