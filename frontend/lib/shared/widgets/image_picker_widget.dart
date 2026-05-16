import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../theme/colors.dart';

/// Custom widget for picking and displaying images
class ImagePickerWidget extends StatefulWidget {
  final Function(List<String>) onImagesSelected;
  final List<String> initialImages;
  final int maxImages;
  final bool allowCamera;
  final bool allowGallery;
  final double imageHeight;
  final double imageWidth;
  final String dossierId; // ✅ إضافة dossierId للرفع إلى Firebase

  const ImagePickerWidget({
    super.key,
    required this.onImagesSelected,
    this.initialImages = const [],
    this.maxImages = 10,
    this.allowCamera = true,
    this.allowGallery = true,
    this.imageHeight = 100,
    this.imageWidth = 100,
    required this.dossierId,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  List<String> _imageUrls = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImages);
  }

  Future<void> _uploadImageToFirebase(File imageFile) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final storageRef = FirebaseStorage.instance.ref().child(
        'dossiers/${widget.dossierId}/images/$fileName',
      );

      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _imageUrls.add(downloadUrl);
      });
      widget.onImagesSelected(_imageUrls);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur upload: $e'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imageUrls.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Maximum ${widget.maxImages} images atteint'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _isUploading = true);
        final file = File(pickedFile.path);
        await _uploadImageToFirebase(file);
      }
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    if (_imageUrls.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Maximum ${widget.maxImages} images atteint'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() => _isUploading = true);

        final remainingSlots = widget.maxImages - _imageUrls.length;
        final filesToAdd = pickedFiles.take(remainingSlots).toList();

        for (final file in filesToAdd) {
          final imageFile = File(file.path);
          await _uploadImageToFirebase(imageFile);
        }

        setState(() => _isUploading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
    widget.onImagesSelected(_imageUrls);
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📸 Ajouter une image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (widget.allowCamera)
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.medicalBlue,
                ),
                title: const Text('📷 Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            if (widget.allowGallery)
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.medicalBlue,
                ),
                title: const Text('🖼️ Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            if (widget.maxImages > 1 && widget.allowGallery)
              ListTile(
                leading: const Icon(
                  Icons.collections_rounded,
                  color: AppColors.medicalBlue,
                ),
                title: Text(
                  '📚 Choisir plusieurs images (max ${widget.maxImages})',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Bouton d'ajout
        InkWell(
          onTap: _showImagePickerDialog,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.medicalBlue, width: 1.5),
              borderRadius: BorderRadius.circular(16),
              color: AppColors.medicalBlue.withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUploading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: AppColors.medicalBlue,
                  ),
                const SizedBox(width: 10),
                Text(
                  '🖼️ Ajouter une image (${_imageUrls.length}/${widget.maxImages})',
                  style: const TextStyle(
                    color: AppColors.medicalBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ✅ Grille d'images
        if (_imageUrls.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: widget.imageWidth / widget.imageHeight,
            ),
            itemCount: _imageUrls.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      _imageUrls[index],
                      height: widget.imageHeight,
                      width: widget.imageWidth,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 14),
                        color: Colors.white,
                        onPressed: () => _removeImage(index),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// Widget pour afficher un aperçu d'image avec possibilité de zoom
class ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  final String? title;

  const ImagePreviewDialog({super.key, required this.imageUrl, this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              height: MediaQuery.of(context).size.height * 0.6,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Fermer'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
