// lib/components/recipe_chat_preview.dart
import 'package:flutter/material.dart';
import '../services/recipe_generator_service.dart';
import '../components/category_tags.dart';

class RecipeChatPreview extends StatelessWidget {
  final RecipeGenerationResult recipe;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onSave;
  final bool isSaving; // Add this parameter

  const RecipeChatPreview({
    Key? key,
    required this.recipe,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSave,
    this.isSaving = false, // Default to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isExpanded 
        ? _buildExpandedView() 
        : _buildPreviewView();
  }

  // Helper to check if a string is a section header (ends with a colon)
  bool _isSectionHeader(String text) {
    return text.trim().endsWith(':');
  }

  Widget _buildPreviewView() {
    // Define a consistent left padding for text alignment
    const double textLeftPadding = 32.0;
    // Position for bullet points
    const double bulletLeftPosition = textLeftPadding - 14;
    
    // Get first 3 ingredients for preview
    final previewIngredients = recipe.ingredients.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe title with right padding to avoid overlapping with checkmark
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(right: 40), // Add right padding to avoid checkmark overlap
          child: Text(
            recipe.title,
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              color: Color(0xFF030303),
              // Add font features for special characters
              fontFeatures: [
                FontFeature.enable('kern'),
                FontFeature.enable('liga'),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
        
        // Categories
        CategoryTags(tags: recipe.categoryTags),
        SizedBox(height: 16),
        
        // Preview of ingredients (first 3)
        Text(
          'Ingredients:',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        ...previewIngredients.map((ingredient) {
          // Check if this is a section header
          if (_isSectionHeader(ingredient)) {
            return Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                ingredient,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  // Add font features for special characters
                  fontFeatures: [
                    FontFeature.enable('kern'),
                    FontFeature.enable('liga'),
                  ],
                ),
              ),
            );
          } else {
            return Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Stack(
                children: [
                  // Text with consistent padding
                  Padding(
                    padding: EdgeInsets.only(left: textLeftPadding),
                    child: Text(
                      ingredient,
                      style: TextStyle(
                        fontSize: 16,
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
                    left: bulletLeftPosition, // Position bullet closer to text
                    top: 8, // Vertically center with the text
                    child: Icon(Icons.circle, size: 8, color: Colors.black87),
                  ),
                ],
              ),
            );
          }
        }),
        if (recipe.ingredients.length > 3)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // This creates the same horizontal space as the bullet points
              SizedBox(width: bulletLeftPosition),
              InkWell(
                onTap: onToggleExpand,
                child: Text(
                  '...and ${recipe.ingredients.length - 3} more ingredients +',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF673AB7),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        SizedBox(height: 16),
        
        // Button to save recipe - updated to show saving state
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: isSaving ? Colors.grey[300] : Color(0xFFFFFFC1),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Saving Recipe...',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Save Recipe',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView() {
    // Define a consistent left padding for text alignment
    const double textLeftPadding = 32.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe title with right padding to avoid overlapping with checkmark
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(right: 40), // Add right padding to avoid checkmark overlap
          child: Text(
            recipe.title,
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              color: Color(0xFF030303),
              // Add font features for special characters
              fontFeatures: [
                FontFeature.enable('kern'),
                FontFeature.enable('liga'),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
        
        // Categories
        CategoryTags(tags: recipe.categoryTags),
        SizedBox(height: 16),
        
        // All ingredients
        Text(
          'Ingredients:',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        
        // Build ingredients list with special handling for section headers
        ...recipe.ingredients.map((ingredient) {
          // Check if this is a section header
          if (_isSectionHeader(ingredient)) {
            return Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                ingredient,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  // Add font features for special characters
                  fontFeatures: [
                    FontFeature.enable('kern'),
                    FontFeature.enable('liga'),
                  ],
                ),
              ),
            );
          } else {
            return Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Stack(
                children: [
                  // Text with consistent padding
                  Padding(
                    padding: EdgeInsets.only(left: textLeftPadding),
                    child: Text(
                      ingredient,
                      style: TextStyle(
                        fontSize: 16,
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
                    left: textLeftPadding - 14, // Position bullet closer to text
                    top: 8, // Vertically center with the text
                    child: Icon(Icons.circle, size: 8, color: Colors.black87),
                  ),
                ],
              ),
            );
          }
        }),
        SizedBox(height: 16),
        
        // All instructions
        Text(
          'Instructions:',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8),
        
        // Process instructions with section headers
        _buildInstructionsWithSections(),
        
        SizedBox(height: 16),
        
        // Nutrition information
        Text(
          'Nutrition (per serving):',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Padding(
          padding: EdgeInsets.only(left: textLeftPadding), // Align with ingredient text
          child: Text(
            'Serving size: ${recipe.nutrition.servingSize}',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Open Sans',
              fontStyle: FontStyle.italic,
              // Add font features for special characters
              fontFeatures: [
                FontFeature.enable('kern'),
                FontFeature.enable('liga'),
              ],
            ),
          ),
        ),
        SizedBox(height: 4),
        Padding(
          padding: EdgeInsets.only(left: textLeftPadding), // Align with ingredient text
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calories: ${recipe.nutrition.caloriesPerServing} kcal',
                      style: TextStyle(
                        fontSize: 16,
                        // Add font features for special characters
                        fontFeatures: [
                          FontFeature.enable('kern'),
                          FontFeature.enable('liga'),
                        ],
                      ),
                    ),
                    Text(
                      'Protein: ${recipe.nutrition.protein}${recipe.nutrition.unit}',
                      style: TextStyle(
                        fontSize: 16,
                        // Add font features for special characters
                        fontFeatures: [
                          FontFeature.enable('kern'),
                          FontFeature.enable('liga'),
                        ],
                      ),
                    ),
                    Text(
                      'Fat: ${recipe.nutrition.fat}${recipe.nutrition.unit}',
                      style: TextStyle(
                        fontSize: 16,
                        // Add font features for special characters
                        fontFeatures: [
                          FontFeature.enable('kern'),
                          FontFeature.enable('liga'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carbs: ${recipe.nutrition.carbs}${recipe.nutrition.unit}',
                      style: TextStyle(
                        fontSize: 16,
                        // Add font features for special characters
                        fontFeatures: [
                          FontFeature.enable('kern'),
                          FontFeature.enable('liga'),
                        ],
                      ),
                    ),
                    Text(
                      'Fiber: ${recipe.nutrition.fiber}${recipe.nutrition.unit}',
                      style: TextStyle(
                        fontSize: 16,
                        // Add font features for special characters
                        fontFeatures: [
                          FontFeature.enable('kern'),
                          FontFeature.enable('liga'),
                        ],
                      ),
                    ),
                    Text(
                      'Sugar: ${recipe.nutrition.sugar}${recipe.nutrition.unit}',
                      style: TextStyle(
                        fontSize: 16,
                        // Add font features for special characters
                        fontFeatures: [
                          FontFeature.enable('kern'),
                          FontFeature.enable('liga'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Button to save recipe - updated to show saving state
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: isSaving ? Colors.grey[300] : Color(0xFFFFFFC1),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Saving Recipe...',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Save Recipe',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        // View less button
        SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: onToggleExpand,
            icon: Icon(Icons.keyboard_arrow_up, size: 18),
            label: Text(
              'View Less',
              style: TextStyle(fontSize: 16),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper method to build instructions with section headers
  Widget _buildInstructionsWithSections() {
    // Define a consistent left padding for text alignment
    const double textLeftPadding = 32.0;
    
    // Keep track of instruction numbers within each section
    int currentStepNumber = 1;
    
    // Create widgets for each instruction
    List<Widget> instructionWidgets = [];
    
    for (int i = 0; i < recipe.instructions.length; i++) {
      final instruction = recipe.instructions[i];
      
      // Check if this is a section header
      if (_isSectionHeader(instruction)) {
        // Reset step number for new section
        currentStepNumber = 1;
        
        instructionWidgets.add(
          Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                // Add font features for special characters
                fontFeatures: [
                  FontFeature.enable('kern'),
                  FontFeature.enable('liga'),
                ],
              ),
            ),
          ),
        );
      } else {
        // Regular instruction step
        instructionWidgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Stack(
              children: [
                // Text with consistent padding
                Padding(
                  padding: EdgeInsets.only(left: textLeftPadding),
                  child: Text(
                    instruction,
                    style: TextStyle(
                      fontSize: 16,
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
                // Number circle positioned closer to text
                Positioned(
                  left: textLeftPadding - 28, // Position number closer to text
                  top: 0, // Align with text top
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFFC1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${currentStepNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        
        // Increment step number
        currentStepNumber++;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: instructionWidgets,
    );
  }
}