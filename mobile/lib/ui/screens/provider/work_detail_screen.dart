import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/completed_work.dart';
import '../../../providers/completed_work_provider.dart';
import '../../widgets/loading_indicator.dart';

class WorkDetailScreen extends StatefulWidget {
  final CompletedWork work;
  final int initialTabIndex;

  const WorkDetailScreen({
    Key? key,
    required this.work,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  _WorkDetailScreenState createState() => _WorkDetailScreenState();
}

class _WorkDetailScreenState extends State<WorkDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<File> _selectedImages = [];
  final List<String> _imageCaptions = [];
  final _captionControllers = <TextEditingController>[];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _captionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          _selectedImages.add(File(image.path));
          _imageCaptions.add('');
          _captionControllers.add(TextEditingController());
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageCaptions.removeAt(index);
      final controller = _captionControllers.removeAt(index);
      controller.dispose();
    });
  }

  Future<void> _saveImages() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Mettre à jour les légendes depuis les contrôleurs
      for (int i = 0; i < _captionControllers.length; i++) {
        _imageCaptions[i] = _captionControllers[i].text;
      }

      final result = await Provider.of<CompletedWorkProvider>(
        context,
        listen: false,
      ).addWorkImages(
        widget.work.id!,
        _selectedImages,
        _imageCaptions,
      );

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Images ajoutées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedImages.clear();
          _imageCaptions.clear();
          for (var controller in _captionControllers) {
            controller.dispose();
          }
          _captionControllers.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<CompletedWorkProvider>(context, listen: false)
                      .errorMessage ??
                  'Erreur lors de l\'ajout des images',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.work.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Détails'),
            Tab(text: 'Ajouter des images'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildAddImagesTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final dateFormat = DateFormat('dd MMMM yyyy');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images du travail
          if (widget.work.imageUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.work.imageUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.work.imageUrls[index],
                        fit: BoxFit.cover,
                        width: 300,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 300,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 300,
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 42,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Informations du travail
          const Text(
            'Informations du travail',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Titre', widget.work.title),
          _buildInfoRow('Description', widget.work.description),
          _buildInfoRow('Lieu', widget.work.location),
          _buildInfoRow('Date de réalisation', dateFormat.format(widget.work.completionDate)),
          _buildInfoRow('Client', widget.work.clientName),
          _buildInfoRow('Contact du client', widget.work.clientContact),
          _buildInfoRow('Date d\'ajout', dateFormat.format(widget.work.createdAt ?? DateTime.now())),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImagesTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajouter des images pour "${widget.work.title}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous pouvez ajouter jusqu\'à 10 images par travail. Chaque image peut avoir une légende facultative.',
                style: TextStyle(
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Bouton pour sélectionner des images
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Sélectionner des images'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Afficher les images sélectionnées
              if (_selectedImages.isNotEmpty) ...[
                const Text(
                  'Images sélectionnées',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    if (_captionControllers.length <= index) {
                      _captionControllers.add(TextEditingController());
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Image ${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _selectedImages[index].path.split('/').last,
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
                                  onPressed: () => _removeImage(index),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _captionControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Légende (facultative)',
                                hintText: 'Ajouter une description pour cette image',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 100,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Bouton pour enregistrer les images
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveImages,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      'Enregistrer les images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
        
        // Indicateur de chargement
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: LoadingIndicator(),
            ),
          ),
      ],
    );
  }
}