// lib/components/recipe_options_helper.dart
import 'package:flutter/material.dart';
import '../components/nutrition_info_dialog.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RecipeOptionsHelper {
  final BuildContext context;
  final Recipe recipe;
  final String? currentUserId;
  final Function() onImagePickRequested;
  final Function() onRefreshRecipe;
  final RecipeService recipeService;
  
  RecipeOptionsHelper({
    required this.context,
    required this.recipe,
    required this.currentUserId,
    required this.onImagePickRequested,
    required this.onRefreshRecipe,
    required this.recipeService,
  });
  
  // Check if current user is the recipe owner
  bool isRecipeOwner() {
    return currentUserId != null && recipe.creator.uid == currentUserId;
  }
  
  // Toggle public/private status of recipe
  Future<void> togglePublicStatus() async {
    if (!isRecipeOwner() || recipe.id == null) return;
    
    try {
      // Update the recipe in Firestore
      final updatedRecipe = Recipe(
        id: recipe.id,
        title: recipe.title,
        image: recipe.image,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        categoryTags: recipe.categoryTags,
        creator: recipe.creator,
        averageRating: recipe.averageRating,
        numberOfRatings: recipe.numberOfRatings,
        numberOfFavorites: recipe.numberOfFavorites,
        nutritionInfo: recipe.nutritionInfo,
        isPublic: !recipe.isPublic, // Toggle the value
        isFavorited: recipe.isFavorited,
        createdAt: recipe.createdAt,
      );
      
      await recipeService.updateRecipe(updatedRecipe);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe is now ${!recipe.isPublic ? 'public' : 'private'}')),
      );
      
      // Refresh the recipe data
      onRefreshRecipe();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating recipe: ${e.toString()}')),
      );
    }
  }
  
  // Show nutrition info dialog
  void showNutritionInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NutritionInfoDialog(
          nutritionInfo: recipe.nutritionInfo,
        );
      },
    );
  }

  Future<void> deleteRecipe(Function() onSuccess) async {
  if (!isRecipeOwner() || recipe.id == null) return;
  
  // Ask for confirmation before deleting
  bool confirmDelete = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Recipe?',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF030303),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'This will permanently delete "${recipe.title}". This action cannot be undone.',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF030303),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: Color(0xFFD3D3D3)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF030303),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Delete Recipe',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ) ?? false;
  
  if (!confirmDelete) return;
  
  try {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
    );
    
    // Delete the recipe
    await recipeService.deleteRecipe(recipe.id!, recipe.creator.uid);
    
    // Close the loading dialog
    Navigator.of(context).pop();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recipe deleted successfully')),
    );
    
    // Call the success callback
    onSuccess();
  } catch (e) {
    // Close the loading dialog
    Navigator.of(context).pop();
    
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error deleting recipe: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // Handle options menu selection
  void showOptionsMenu(GlobalKey optionsButtonKey) {
    final bool isOwner = isRecipeOwner();
    
    // Get the render box from the button's key
    final RenderBox renderBox = optionsButtonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    
    // Build menu items
    List<PopupMenuItem> menuItems = [
      // Nutrition Info Option
      PopupMenuItem(
        height: 48, // Reduced height from 56
        padding: EdgeInsets.zero, // Remove default padding
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: isOwner ? Radius.zero : Radius.circular(16),
            ),
          ),
          child: ListTile(
            dense: true, // Makes the ListTile more compact
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
            leading: Icon(Icons.restaurant_menu, color: Colors.green, size: 22), // Slightly smaller icon
            title: Text(
              'Nutrition Info',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF030303),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              showNutritionInfo();
            },
          ),
        ),
      ),
    ];
    
    // Add Change Image Option - only for recipe owners
    if (isOwner) {
      menuItems.add(
        PopupMenuItem(
          height: 48, // Reduced height from 56
          padding: EdgeInsets.zero, // Remove default padding
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.zero,
                bottom: Radius.zero,
              ),
            ),
            child: ListTile(
              dense: true, // Makes the ListTile more compact
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
              leading: Icon(
                Icons.image,
                color: Colors.blue,
                size: 22, // Slightly smaller icon
              ),
              title: Text(
                'Change Image',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF030303),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onImagePickRequested();
              },
            ),
          ),
        )
      );
    }
    
    // Add Public/Private Toggle - only for recipe owners
    if (isOwner) {
      menuItems.add(
        PopupMenuItem(
          height: 48, // Reduced height from 56
          padding: EdgeInsets.zero, // Remove default padding
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.zero,
                bottom: Radius.zero, // Changed to zero since we're adding another item
              ),
            ),
            child: ListTile(
              dense: true, // Makes the ListTile more compact
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
              leading: Icon(
                recipe.isPublic ? Icons.public : Icons.lock,
                color: recipe.isPublic ? Colors.blue : Colors.orange,
                size: 22, // Slightly smaller icon
              ),
              title: Text(
                recipe.isPublic ? 'Make Private' : 'Make Public',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF030303),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                togglePublicStatus();
              },
            ),
          ),
        )
      );
    }
    
    // Add Delete Option - only for recipe owners
    if (isOwner) {
      menuItems.add(
        PopupMenuItem(
          height: 48, // Reduced height from 56
          padding: EdgeInsets.zero, // Remove default padding
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.zero,
                bottom: Radius.circular(16), // Bottom item, so has rounded bottom
              ),
            ),
            child: ListTile(
              dense: true, // Makes the ListTile more compact
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
              leading: Icon(
                Icons.delete,
                color: Colors.red,
                size: 22, // Slightly smaller icon
              ),
              title: Text(
                'Delete Recipe',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Close the menu
                // We'll need to pass a callback for navigation after deletion
                deleteRecipe(() {
                  // This will be called on successful deletion, typically to navigate back
                  Navigator.of(context).pop(); // Navigate back after deletion
                });
              },
            ),
          ),
        )
      );
    }
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
      ),
      items: menuItems,
      elevation: 8,
      // Style the popup menu to match app design
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
    );
  }
}