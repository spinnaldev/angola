
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FilePickerWidget extends StatefulWidget {
  final String label;
  final String description;
  final File? selectedFile;
  final Function(File?) onFileSelected;
  final bool required;
  final List<String> allowedTypes; // ['image', 'pdf', 'document']

  const FilePickerWidget({
    Key? key,
    required this.label,
    required this.description,
    this.selectedFile,
    required this.onFileSelected,
    this.required = false,
    this.allowedTypes = const ['image'],
  }) : super(key: key);

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.selectedFile != null 
              ? Colors.green 
              : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.selectedFile != null 
                          ? Icons.check_circle
                          : Icons.upload_file,
                      color: widget.selectedFile != null 
                          ? Colors.green 
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.selectedFile != null 
                              ? Colors.green 
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (widget.required)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Requis',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Zone d'upload ou fichier sélectionné
          if (widget.selectedFile != null) 
            _buildSelectedFile()
          else
            _buildUploadZone(),
        ],
      ),
    );
  }

  Widget _buildUploadZone() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: InkWell(
        onTap: _showFilePickerOptions,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 32,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8),
              const Text(
                'Appuyer pour choisir un fichier',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getAllowedTypesText(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFile() {
    final fileName = widget.selectedFile!.path.split('/').last;
    final isImage = _isImageFile(fileName);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Aperçu ou icône
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey[200],
            ),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      widget.selectedFile!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                        );
                      },
                    ),
                  )
                : Icon(
                    _getFileIcon(fileName),
                    color: Colors.grey[600],
                    size: 24,
                  ),
          ),
          const SizedBox(width: 12),
          
          // Informations du fichier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName.length > 25 
                      ? '${fileName.substring(0, 22)}...'
                      : fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getFileSize(widget.selectedFile!),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Boutons d'action
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _showFilePickerOptions,
                icon: const Icon(Icons.edit, size: 18),
                color: Colors.blue,
                tooltip: 'Changer',
              ),
              IconButton(
                onPressed: () => widget.onFileSelected(null),
                icon: const Icon(Icons.delete, size: 18),
                color: Colors.red,
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choisir un fichier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Options selon les types autorisés
            if (widget.allowedTypes.contains('image')) ...[
              _buildOption(
                icon: Icons.camera_alt,
                title: 'Prendre une photo',
                subtitle: 'Utiliser l\'appareil photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              const SizedBox(height: 12),
              _buildOption(
                icon: Icons.photo_library,
                title: 'Galerie photos',
                subtitle: 'Choisir depuis la galerie',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
            
            if (widget.allowedTypes.contains('pdf') || widget.allowedTypes.contains('document')) ...[
              if (widget.allowedTypes.contains('image')) const SizedBox(height: 12),
              _buildOption(
                icon: Icons.file_present,
                title: 'Parcourir les fichiers',
                subtitle: 'PDF, documents...',
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        widget.onFileSelected(File(image.path));
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        widget.onFileSelected(File(image.path));
      }
    } catch (e) {
      _showError('Erreur lors de la sélection d\'image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _getAllowedExtensions(),
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Vérifier la taille (max 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          _showError('Le fichier est trop volumineux (max 5MB)');
          return;
        }
        
        widget.onFileSelected(file);
      }
    } catch (e) {
      _showError('Erreur lors de la sélection du document: $e');
    }
  }

  List<String> _getAllowedExtensions() {
    List<String> extensions = [];
    
    if (widget.allowedTypes.contains('image')) {
      extensions.addAll(['jpg', 'jpeg', 'png']);
    }
    if (widget.allowedTypes.contains('pdf')) {
      extensions.add('pdf');
    }
    if (widget.allowedTypes.contains('document')) {
      extensions.addAll(['doc', 'docx']);
    }
    
    return extensions;
  }

  String _getAllowedTypesText() {
    List<String> types = [];
    
    if (widget.allowedTypes.contains('image')) {
      types.add('Images (JPG, PNG)');
    }
    if (widget.allowedTypes.contains('pdf')) {
      types.add('PDF');
    }
    if (widget.allowedTypes.contains('document')) {
      types.add('Documents');
    }
    
    return '${types.join(', ')} • Max 5MB';
  }

  bool _isImageFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}