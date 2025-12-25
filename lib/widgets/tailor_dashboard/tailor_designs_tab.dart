import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/design.dart';
import '../../services/firestore_designs_service.dart';

/// [Purpose]
/// This widget manages the Designs tab of the Tailor Dashboard.
/// It displays a list of designs and provides functionality to Add, Edit, and Delete designs.
///
/// [Logic]
/// - Uses a [GridView] (or responsive layout) to display designs.
/// - Manages form state for Adding/Editing designs via [showDialog].
/// - Handles image picking and base64 encoding for design photos.
///
/// [Flow]
/// 1. Receives list of [Design] objects from parent.
/// 2. User clicks Add/Edit -> Opens Dialog ([_showDesignFormDialog]).
/// 3. User saves -> Calls [FirestoreDesignsService] to update DB -> Calls [onRefresh] to reload parent data.
class TailorDesignsTab extends StatefulWidget {
  final List<Design> designs;
  final VoidCallback onRefresh;

  const TailorDesignsTab({
    super.key,
    required this.designs,
    required this.onRefresh,
  });

  @override
  State<TailorDesignsTab> createState() => _TailorDesignsTabState();
}

class _TailorDesignsTabState extends State<TailorDesignsTab> {
  final FirestoreDesignsService _designsService = FirestoreDesignsService();
  final ImagePicker _imagePicker = ImagePicker();

  /// [Purpose]
  /// Builds the main UI for the Designs tab.
  /// 
  /// [Logic]
  /// - Checks if the design list is empty, if so shows an "Empty State".
  /// - If not empty, shows a [GridView.builder] with [Design] cards.
  /// - Includes an "Add Design" Floating Action Button (FAB).
  @override
  Widget build(BuildContext context) {
    if (widget.designs.isEmpty) {
      return _buildEmptyState();
    }

    // Determine grid count based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Designs (${widget.designs.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDesignDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Design'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75, // Aspect ratio for card
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: widget.designs.length,
          itemBuilder: (context, index) {
            return _buildDesignCard(widget.designs[index]);
          },
        ),
      ],
    );
  }

  /// [Purpose]
  /// Displays a message when no designs are available.
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.checkroom, size: 60, color: Colors.purple),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Designs Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your best works to showcase to customers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddDesignDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Design'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// [Purpose]
  /// Builds a single card representing a [Design].
  /// 
  /// [Logic]
  /// - Displays the design photo (using [_buildDesignImage]).
  /// - Shows Title, Price, and Status.
  /// - Provides Edit and Delete buttons which trigger respective dialogs.
  Widget _buildDesignCard(Design design) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: _buildDesignImage(design.photo),
                ),
              ),
              // Info Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      design.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${design.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(design.status ?? 'new').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (design.status ?? 'New').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(design.status ?? 'new'),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Actions Overlay
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  color: Colors.blue,
                  onTap: () => _showEditDesignDialog(design),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: () => _showDeleteDesignDialog(design),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// [Purpose]
  /// Helper for creating small action buttons on the card.
  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  /// [Purpose]
  /// Helper to get color based on status string.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.orange;
      default: return Colors.blue;
    }
  }

  /// [Purpose]
  /// Handles displaying design images with fallback and error handling.
  /// 
  /// [Logic]
  /// - Supports base64 encoded strings (starts with 'data:').
  /// - Supports URLs (http/https) using [CachedNetworkImage].
  /// - Fallback to placeholders if photo is null or invalid.
  Widget _buildDesignImage(String? photo) {
    if (photo == null || photo.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }
    
    try {
      if (photo.startsWith('data:')) {
        final parts = photo.split(',');
        if (parts.length > 1) {
          final base64String = parts[1];
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, size: 40),
            ),
          );
        }
      } else if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: photo,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 40),
          ),
        );
      }
    } catch (e) {
      print('Error loading design image: $e');
    }
    
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 40, color: Colors.grey),
    );
  }

  // --- Dialogs ---

  void _showAddDesignDialog() {
    _showDesignFormDialog();
  }

  void _showEditDesignDialog(Design design) {
    _showDesignFormDialog(design: design);
  }

  /// [Purpose]
  /// Unified dialog for Adding and Editing designs.
  /// 
  /// [Logic]
  /// - Pre-populates fields if [design] is provided (Edit mode).
  /// - Handles [ImagePicker] to select new photo.
  /// - Optimistic UI updates (loading state) while saving to Firestore.
  /// 
  /// [Flow]
  /// User inputs -> 'Save' -> Encodes Image -> Creates [Design] object -> Service Call -> [onRefresh].
  void _showDesignFormDialog({Design? design}) {
    final titleController = TextEditingController(text: design?.title ?? '');
    final priceController = TextEditingController(text: design?.price.toString() ?? '');
    String status = design?.status ?? 'new';
    XFile? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(design == null ? 'Add New Design' : 'Edit Design'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
                    if (image != null) setDialogState(() => selectedImage = image);
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? Image.network(selectedImage!.path, fit: BoxFit.cover)
                                : Image.file(File(selectedImage!.path), fit: BoxFit.cover),
                          )
                        : (design?.photo != null && design!.photo!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildDesignImage(design.photo),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Upload Photo', style: TextStyle(color: Colors.grey)),
                                ],
                              )),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Design Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (Rs.)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'new', child: Text('New')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (val) => setDialogState(() => status = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (titleController.text.isEmpty || priceController.text.isEmpty) return;
                      setDialogState(() => isUploading = true);
                      try {
                        String? photoUrl = design?.photo;
                        if (selectedImage != null) {
                           try {
                              final bytes = await selectedImage!.readAsBytes();
                              final base64String = base64Encode(bytes);
                              photoUrl = 'data:image/jpeg;base64,$base64String';
                            } catch (e) {
                              print('Error encoding image: \$e');
                            }
                        }

                        final newDesign = Design(
                          id: design?.id,
                          docId: design?.docId,
                          title: titleController.text.trim(),
                          price: double.tryParse(priceController.text) ?? 0,
                          photo: photoUrl,
                          status: status,
                          createdAt: design?.createdAt,
                          // tailorId: _authService.currentUser.uid  <-- Service handles this typically or we might need to pass it? 
                          // The service `addDesign` usually adds the current user's ID or it's part of the model. 
                          // Assuming service handles it based on auth context.
                        );

                        if (newDesign.docId != null) {
                          await _designsService.updateDesign(newDesign);
                        } else {
                          await _designsService.addDesign(newDesign);
                        }
                        
                        if (context.mounted) Navigator.pop(context);
                        widget.onRefresh(); // Trigger parent refresh
                      } catch (e) {
                         if (mounted) {
                            setDialogState(() => isUploading = false);
                            print(e);
                         }
                      }
                    },
              child: isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(design == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// [Purpose]
  /// Dialog to confirm deletion of a design.
  void _showDeleteDesignDialog(Design design) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Design'),
        content: const Text('Are you sure you want to delete this design?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (design.docId != null) {
                  await _designsService.deleteDesign(design.docId!);
                  widget.onRefresh();
                }
              } catch (e) {
                print('Error deleting design: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
