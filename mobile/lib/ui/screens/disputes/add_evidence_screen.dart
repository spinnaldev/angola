// lib/ui/screens/disputes/add_evidence_screen.dart - Version internationalisée
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image/image.dart' as img;
import '../../../providers/dispute_provider.dart';
import '../../widgets/loading_indicator.dart';

class AddEvidenceScreen extends StatefulWidget {
  final int disputeId;

  const AddEvidenceScreen({
    Key? key,
    required this.disputeId,
  }) : super(key: key);

  @override
  _AddEvidenceScreenState createState() => _AddEvidenceScreenState();
}

class _AddEvidenceScreenState extends State<AddEvidenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  File? _selectedFile;
  bool _isSubmitting = false;
  String _fileType = 'image'; // 'image' or 'document'

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Demander à l'utilisateur de choisir la source
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (pickedImage != null) {
      // Compresser l'image pour éviter les timeouts
      final compressedFile = await _compressImage(File(pickedImage.path));
      
      setState(() {
        _selectedFile = compressedFile;
        _fileType = 'image';
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    final l10n = AppLocalizations.of(context)!;
    
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectImageSource),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.camera),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.gallery),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<File> _compressImage(File imageFile) async {
    try {
      // Lire l'image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return imageFile;
      
      // Redimensionner si nécessaire (max 1200px)
      final resized = image.width > 1200 || image.height > 1200
          ? img.copyResize(image, width: 1200)
          : image;
      
      // Compresser en JPEG avec qualité 70
      final compressedBytes = img.encodeJpg(resized, quality: 70);
      
      // Écrire dans un nouveau fichier temporaire
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);
      
      print('Image compressée: ${imageFile.lengthSync()} -> ${tempFile.lengthSync()} bytes');
      
      return tempFile;
    } catch (e) {
      print('Erreur compression image: $e');
      return imageFile; // Retourner l'original si la compression échoue
    }
  }

  Future<void> _pickDocument() async {
    // Pour les documents, utiliser file_picker serait mieux
    // Ici on simule avec l'image picker
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _fileType = 'document';
      });
    }
  }

  Future<void> _submitEvidence() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseSelectFile),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Vérifier la taille du fichier (max 10MB)
    final fileSizeInBytes = await _selectedFile!.length();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    
    if (fileSizeInMB > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fileTooLarge),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final disputeProvider = Provider.of<DisputeProvider>(context, listen: false);
      final success = await disputeProvider.addEvidence(
        widget.disputeId,
        _descriptionController.text,
        _selectedFile!,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.evidenceAddedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retourner un résultat pour actualiser
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(disputeProvider.errorMessage ?? l10n.errorAddingEvidence),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Messages d'erreur spécifiques
        if (errorMessage.contains('timeout') || errorMessage.contains('expired')) {
          errorMessage = l10n.uploadTimeout;
        } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
          errorMessage = l10n.networkError;
        } else if (errorMessage.contains('413') || errorMessage.contains('too large')) {
          errorMessage = l10n.fileTooLarge;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.retry,
              textColor: Colors.white,
              onPressed: _submitEvidence,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getFileSizeString(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addEvidence),
        elevation: 0,
        backgroundColor: const Color(0xFF142FE2),
        foregroundColor: Colors.white,
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LoadingIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.uploadingEvidence,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.pleaseWait,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Description de la preuve
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.evidenceDescription,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: l10n.description,
                              hintText: l10n.explainWhatThisProves,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.description),
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.pleaseEnterDescription;
                              }
                              if (value.trim().length < 10) {
                                return l10n.descriptionTooShort;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sélection du type de fichier
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.evidenceType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.image),
                                  label: Text(l10n.image),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    foregroundColor: _fileType == 'image' 
                                        ? Colors.white 
                                        : const Color(0xFF142FE2),
                                    backgroundColor: _fileType == 'image' 
                                        ? const Color(0xFF142FE2)
                                        : Colors.transparent,
                                    side: const BorderSide(color: Color(0xFF142FE2)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickDocument,
                                  icon: const Icon(Icons.insert_drive_file),
                                  label: Text(l10n.document),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    foregroundColor: _fileType == 'document' 
                                        ? Colors.white 
                                        : const Color(0xFF142FE2),
                                    backgroundColor: _fileType == 'document' 
                                        ? const Color(0xFF142FE2)
                                        : Colors.transparent,
                                    side: const BorderSide(color: Color(0xFF142FE2)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Fichier sélectionné
                  if (_selectedFile != null)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.selectedFile,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            if (_fileType == 'image' && _selectedFile != null)
                              Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedFile!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.insert_drive_file, size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedFile!.path.split('/').last,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          FutureBuilder<int>(
                                            future: _selectedFile!.length(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Text(
                                                  _getFileSizeString(snapshot.data!),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                });
                              },
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: Text(
                                l10n.removeFile,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Informations sur les limites
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.fileLimitsInfo,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton soumettre
                  ElevatedButton(
                    onPressed: _submitEvidence,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF142FE2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      l10n.submitEvidence,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}