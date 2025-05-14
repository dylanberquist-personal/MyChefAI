// lib/components/recipe_content_section.dart
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../components/header_text.dart';
import '../services/recipe_service.dart';

class RecipeContentSection extends StatefulWidget {
  final Recipe recipe;
  final String? currentUserId;
  final Function() onRecipeUpdated;
  
  const RecipeContentSection({
    Key? key,
    required this.recipe,
    this.currentUserId,
    required this.onRecipeUpdated,
  }) : super(key: key);

  @override
  _RecipeContentSectionState createState() => _RecipeContentSectionState();
}

class _RecipeContentSectionState extends State<RecipeContentSection> {
  final RecipeService _recipeService = RecipeService();
  bool _isEditingIngredients = false;
  bool _isEditingInstructions = false;
  bool _isSaving = false;
  
  // Text editing controllers
  late List<TextEditingController> _ingredientControllers;
  late List<TextEditingController> _instructionControllers;
  
  // Define consistent left padding for text alignment
  final double textLeftPadding = 32.0;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  @override
  void didUpdateWidget(RecipeContentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe != widget.recipe) {
      _disposeControllers();
      _initializeControllers();
    }
  }
  
  void _initializeControllers() {
    // Initialize ingredients controllers
    _ingredientControllers = widget.recipe.ingredients
        .map((ingredient) => TextEditingController(text: ingredient))
        .toList();
    
    // Initialize instructions controllers
    _instructionControllers = widget.recipe.instructions
        .map((instruction) => TextEditingController(text: instruction))
        .toList();
  }
  
  void _disposeControllers() {
    // Dispose all controllers to prevent memory leaks
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
  }
  
  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
  
  bool _isRecipeOwner() {
    return widget.currentUserId != null && 
           widget.recipe.creator.uid == widget.currentUserId;
  }
  
  // Check if a string is a section header (ends with a colon)
  bool _isSectionHeader(String text) {
    return text.trim().endsWith(':');
  }
  
  // Add an ingredient field
  void _addIngredientField() {
    setState(() {
      _ingredientControllers.add(TextEditingController(text: ''));
    });
  }
  
  // Remove an ingredient field
  void _removeIngredientField(int index) {
    if (_ingredientControllers.length <= 1) {
      // Don't allow removing the last ingredient
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe must have at least one ingredient')),
      );
      return;
    }
    
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }
  
  // Add an instruction field
  void _addInstructionField() {
    setState(() {
      _instructionControllers.add(TextEditingController(text: ''));
    });
  }
  
  // Remove an instruction field
  void _removeInstructionField(int index) {
    if (_instructionControllers.length <= 1) {
      // Don't allow removing the last instruction
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe must have at least one instruction')),
      );
      return;
    }
    
    setState(() {
      _instructionControllers[index].dispose();
      _instructionControllers.removeAt(index);
    });
  }
  
  // Add a section header
  void _addSectionHeader(List<TextEditingController> controllers, String sectionType) {
    setState(() {
      controllers.add(TextEditingController(text: 'For the $sectionType: '));
    });
  }
  
  // Save the recipe changes
  Future<void> _saveRecipeChanges() async {
    if (!_isRecipeOwner() || widget.recipe.id == null) return;
    
    // Validate all fields are non-empty
    bool hasEmptyIngredient = _ingredientControllers.any((controller) => controller.text.trim().isEmpty);
    bool hasEmptyInstruction = _instructionControllers.any((controller) => controller.text.trim().isEmpty);
    
    if (hasEmptyIngredient || hasEmptyInstruction) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields must be filled in')),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Get the updated ingredients and instructions
      List<String> updatedIngredients = _ingredientControllers
          .map((controller) => controller.text.trim())
          .toList();
      
      List<String> updatedInstructions = _instructionControllers
          .map((controller) => controller.text.trim())
          .toList();
      
      // Create updated recipe
      final updatedRecipe = Recipe(
        id: widget.recipe.id,
        title: widget.recipe.title,
        image: widget.recipe.image,
        ingredients: updatedIngredients,
        instructions: updatedInstructions,
        categoryTags: widget.recipe.categoryTags,
        creator: widget.recipe.creator,
        averageRating: widget.recipe.averageRating,
        numberOfRatings: widget.recipe.numberOfRatings,
        numberOfFavorites: widget.recipe.numberOfFavorites,
        nutritionInfo: widget.recipe.nutritionInfo,
        isPublic: widget.recipe.isPublic,
        isFavorited: widget.recipe.isFavorited,
        createdAt: widget.recipe.createdAt,
      );
      
      // Update the recipe in Firestore
      await _recipeService.updateRecipe(updatedRecipe);
      
      // Call the callback to notify parent of update
      widget.onRecipeUpdated();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe updated successfully')),
      );
      
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating recipe: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditingIngredients = false;
          _isEditingInstructions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _isRecipeOwner();
    // Position for bullet points (closer to text)
    final double bulletLeftPosition = textLeftPadding - 14;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ingredients Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HeaderText(text: 'Ingredients'),
            if (isOwner)
              IconButton(
                icon: Icon(_isEditingIngredients ? Icons.check : Icons.edit),
                onPressed: _isSaving 
                    ? null 
                    : () {
                        if (_isEditingIngredients) {
                          _saveRecipeChanges();
                        } else {
                          setState(() {
                            _isEditingIngredients = true;
                          });
                        }
                      },
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Ingredients List (Editable or Display)
        if (_isEditingIngredients)
          // Editable ingredients
          Column(
            children: [
              ..._ingredientControllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;
                
                // Check if this is likely a section header
                bool isSectionHeader = _isSectionHeader(controller.text);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // For section headers, remove the bullet point and left indent
                      SizedBox(
                        width: isSectionHeader ? 0 : bulletLeftPosition,
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            // Hint for section headers
                            hintText: isSectionHeader ? 'For the section: ' : 'Ingredient',
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Open Sans',
                            fontWeight: isSectionHeader ? FontWeight.bold : FontWeight.normal,
                            fontStyle: isSectionHeader ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle),
                        color: Colors.red,
                        onPressed: () => _removeIngredientField(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              // Add ingredient and section buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _addIngredientField,
                        icon: Icon(Icons.add),
                        label: Text('Add Ingredient'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Color(0xFFFFFFC1),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _addSectionHeader(_ingredientControllers, 'section'),
                        icon: Icon(Icons.playlist_add),
                        label: Text('Add Section'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.grey[200],
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          // Display ingredients with proper handling of section headers
          ...widget.recipe.ingredients.map((ingredient) {
            // Check if this is a section header
            bool isSectionHeader = _isSectionHeader(ingredient);
            
            if (isSectionHeader) {
              // Special styling for section headers (no bullet, bold, italic)
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  ingredient,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            } else {
              // Regular ingredient with bullet point
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Stack(
                  children: [
                    // Text with consistent padding
                    Padding(
                      padding: EdgeInsets.only(left: textLeftPadding),
                      child: Text(
                        ingredient,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Open Sans',
                          // Add font features for special characters
                          fontFeatures: [
                            FontFeature.enable('kern'),
                            FontFeature.enable('liga'),
                          ],
                        ),
                        softWrap: true,
                        textWidthBasis: TextWidthBasis.longestLine,
                      ),
                    ),
                    // Bullet point positioned closer to text
                    Positioned(
                      left: bulletLeftPosition,
                      top: 8, // Vertically center with the text
                      child: Icon(Icons.circle, size: 8, color: Colors.black87),
                    ),
                  ],
                ),
              );
            }
          }).toList(),
        const SizedBox(height: 24),

        // Instructions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HeaderText(text: 'Instructions'),
            if (isOwner)
              IconButton(
                icon: Icon(_isEditingInstructions ? Icons.check : Icons.edit),
                onPressed: _isSaving 
                    ? null 
                    : () {
                        if (_isEditingInstructions) {
                          _saveRecipeChanges();
                        } else {
                          setState(() {
                            _isEditingInstructions = true;
                          });
                        }
                      },
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Instructions List (Editable or Display)
        if (_isEditingInstructions)
          // Editable instructions
          Column(
            children: [
              ..._instructionControllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;
                
                // Check if this is a section header
                bool isSectionHeader = _isSectionHeader(controller.text);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // For section headers, remove the number and add appropriate padding
                      if (!isSectionHeader) 
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFFFC1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(right: 8, top: 12),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        SizedBox(width: 0),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            // Hint for section headers
                            hintText: isSectionHeader ? 'For the section: ' : 'Instruction step',
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Open Sans',
                            fontWeight: isSectionHeader ? FontWeight.bold : FontWeight.normal,
                            fontStyle: isSectionHeader ? FontStyle.italic : FontStyle.normal,
                          ),
                          maxLines: 3,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle),
                        color: Colors.red,
                        onPressed: () => _removeInstructionField(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              // Add instruction and section buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _addInstructionField,
                        icon: Icon(Icons.add),
                        label: Text('Add Step'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Color(0xFFFFFFC1),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _addSectionHeader(_instructionControllers, 'section'),
                        icon: Icon(Icons.playlist_add),
                        label: Text('Add Section'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.grey[200],
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          // Display instructions with proper handling of section headers
          ...widget.recipe.instructions.asMap().entries.map((entry) {
            int index = entry.key;
            String instruction = entry.value;
            
            // Check if this is a section header
            bool isSectionHeader = _isSectionHeader(instruction);
            
            if (isSectionHeader) {
              // Special styling for section headers (no number, bold, italic)
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  instruction,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            } else {
              // Regular instruction with number
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number circle positioned closer to text
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFFFC1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(right: 8, top: 2), // Reduced right margin
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        instruction,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Open Sans',
                          // Add font features for special characters
                          fontFeatures: [
                            FontFeature.enable('kern'),
                            FontFeature.enable('liga'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }).toList(),
          
        // Show a loading indicator when saving
        if (_isSaving)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}