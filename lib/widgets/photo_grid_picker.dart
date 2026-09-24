import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bumble/services/profile_service.dart'; 
import 'package:bumble/constants/app_colors.dart';

class PhotoGridPicker extends StatefulWidget {
  final String userId;
  final List<String> initialPhotos;
  final ProfileService profileService;

  const PhotoGridPicker({
    super.key,
    required this.userId,
    required this.initialPhotos,
    required this.profileService,
  });

  @override
  State<PhotoGridPicker> createState() => _PhotoGridPickerState();
}

class _PhotoGridPickerState extends State<PhotoGridPicker> {
  final int maxPhotos = 6;
  late List<String> _photos;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final Uint8List bytes = await image.readAsBytes();
      final extension = image.name.split('.').last;

      // Upload via service
      final newUrl = await widget.profileService.uploadPhoto(
        userId: widget.userId,
        bytes: bytes,
        fileExtension: extension,
      );

      setState(() {
        _photos.add(newUrl);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePhoto(String url) async {
    setState(() => _isLoading = true);

    try {
      await widget.profileService.deletePhoto(
        userId: widget.userId,
        photoUrl: url,
      );

      setState(() {
        _photos.remove(url);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), 
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7, 
          ),
          itemCount: maxPhotos,
          itemBuilder: (context, index) {
            // kondisi Terisi Foto
            if (index < _photos.length) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _photos[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Ikon Hapus
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: IconButton(
                      onPressed: () => _deletePhoto(_photos[index]),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: AppColors.error, size: 16),
                      ),
                    ),
                  ),
                  // Label "Foto Utama"
                  if (index == 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary, 
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Utama',
                          style: TextStyle(color: AppColors.onPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            }

            // kondisi Tombol + ada slot
            if (index == _photos.length) {
              return GestureDetector(
                onTap: _isLoading ? null : _pickAndUploadPhoto,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryDeep, width: 2, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Icon(Icons.add_a_photo, size: 32, color: AppColors.primaryDeep),
                  ),
                ),
              );
            }

            // kondisi tidak ada slot
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
              ),
            );
          },
        ),

        // Loading Overlay
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}