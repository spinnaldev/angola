// lib/ui/utils/dialog_util.dart
import 'package:flutter/material.dart';

class DialogUtil {
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color confirmColor = Colors.blue,
    Color cancelColor = Colors.grey,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: cancelColor,
              ),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: confirmColor,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    return await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  static Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    required String hint,
    String initialValue = '',
    String confirmText = 'OK',
    String cancelText = 'Annuler',
    Function(String)? validator,
  }) async {
    final TextEditingController controller = TextEditingController(text: initialValue);
    String? errorText;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hint,
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      if (validator != null) {
                        setState(() {
                          errorText = validator(value);
                        });
                      }
                    },
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  child: Text(cancelText),
                ),
                TextButton(
                  onPressed: () {
                    if (validator != null) {
                      final error = validator(controller.text);
                      if (error != null) {
                        setState(() {
                          errorText = error;
                        });
                        return;
                      }
                    }
                    Navigator.of(context).pop(controller.text);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                  child: Text(confirmText),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> showLoadingDialog(
    BuildContext context, {
    String message = 'Chargement en cours...',
  }) async {
    return await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  static Future<int?> showOptionsDialog(
    BuildContext context, {
    required String title,
    required List<String> options,
    String cancelText = 'Annuler',
  }) async {
    return await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                options.length,
                (index) => ListTile(
                  title: Text(options[index]),
                  onTap: () => Navigator.of(context).pop(index),
                ),
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: Text(cancelText),
            ),
          ],
        );
      },
    );
  }
}