// lib/components/recipe_image_section.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../services/storage_service.dart';

class RecipeImageSection extends StatefulWidget {
  final Recipe recipe;
  final String? currentUserId;
  final Function(String) onImageUpdated;
  
  const RecipeImageSection({
    Key? key,
    required this.recipe,
    required this.currentUserId,
    required this.onImageUpdated,
  }) : super(key: key);

  @override
  _RecipeImageSectionState createState() => _RecipeImageSectionState();
}

class _RecipeImageSectionState extends State<RecipeImageSection> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  
  bool _isUploadingImage = false;
  File? _selectedImage;

  // Check if user is the recipe owner
  bool _isRecipeOwner() {
    return widget.currentUserId != null && 
           widget.recipe.creator.uid == widget.currentUserId;
  }

  // Method to pick an image
  Future<void> _pickImage() async {
    if (widget.currentUserId == null || widget.recipe.id == null) {
      return;
    }

    // Check if user is the recipe owner
    if (!_isRecipeOwner()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only the recipe creator can change the image')),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Reduce image quality to save storage
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploadingImage = true; // Start showing loading state immediately
        });
        await _uploadRecipeImage();
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  // Method to upload the recipe image
  Future<void> _uploadRecipeImage() async {
    if (_selectedImage == null || widget.recipe.id == null) {
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Uploading recipe image...'),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );

      // Create a path based on recipe ID
      final imageUrl = await _storageService.uploadRecipeImage(
        widget.recipe.id!,
        _selectedImage!,
      );

      // Preload the image
      final imageProvider = NetworkImage(imageUrl);
      await precacheImage(imageProvider, context);

      // Call the callback to update the parent
      widget.onImageUpdated(imageUrl);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe image updated successfully!')),
      );
      
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      print('Error uploading recipe image: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Show a user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update recipe image. Please make sure you have permission to edit this recipe.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _selectedImage = null; // Clear the selected image on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _isRecipeOwner();
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Image area with improved handling
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _isUploadingImage
              // Show placeholder or selected image during upload
              ? (_selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/recipe_image_placeholder.png',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ))
              // Show network image when not uploading
              : (widget.recipe.image != null && widget.recipe.image!.isNotEmpty
                  ? FadeInImage.assetNetwork(
                      placeholder: 'assets/images/recipe_image_placeholder.png',
                      image: widget.recipe.image!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/recipe_image_placeholder.png',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/images/recipe_image_placeholder.png',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )),
        ),
        
        // Loading overlay during upload
        if (_isUploadingImage)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        
        // Camera icon for recipe owner
        if (isOwner)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _pickImage,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isUploadingImage 
                      ? Colors.grey.withOpacity(0.8) 
                      : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _isUploadingImage
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 24,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}