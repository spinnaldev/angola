import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return AlertDialog(
          title: Text(l10n.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languageProvider.supportedLanguages.map((language) {
              final isSelected = language['code'] == languageProvider.currentLanguageCode;
              
              return ListTile(
                leading: Text(
                  language['flag'],
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(language['name']),
                trailing: isSelected 
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
                onTap: () {
                  languageProvider.changeLanguage(language['code']);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }
}