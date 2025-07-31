
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FilePickerWidget extends StatelessWidget {
  final String label;
  final String? description;
  final File? selectedFile;
  final Function(File) onFileSelected;
  final bool required;
  final List<String> allowedTypes; // ['image', 'pdf']

  const FilePickerWidget({
    Key? key,
    required this.label,
    this.description,
    this.selectedFile,
    required this.onFileSelected,
    this.required = false,
    this.allowedTypes = const ['image'],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 8),
        
        // Zone de sélection/prévisualisation
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            height: selectedFile != null ? 120 : 80,
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedFile != null ? Colors.green : Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: selectedFile != null 
                  ? Colors.green.withOpacity(0.05)
                  : Colors.grey[50],
            ),
            child: selectedFile != null 
                ? _buildPreview()
                : _buildPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        Center(
          child: selectedFile!.path.toLowerCase().endsWith('.pdf')
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf, size: 32, color: Colors.red),
                    const SizedBox(height: 4),
                    Text(
                      selectedFile!.path.split('/').last,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    selectedFile!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          allowedTypes.contains('pdf') ? Icons.upload_file : Icons.add_a_photo,
          size: 32,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Appuyer pour sélectionner',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      if (allowedTypes.contains('image') && allowedTypes.length == 1) {
        // Seulement images
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        
        if (pickedFile != null) {
          onFileSelected(File(pickedFile.path));
        }
      } else {
        // Images et/ou PDF - utiliser file_picker
        // TODO: Implémenter avec file_picker si nécessaire
        print('Multiple file types not implemented yet');
      }
    } catch (e) {
      print('Erreur sélection fichier: $e');
    }
  }
}