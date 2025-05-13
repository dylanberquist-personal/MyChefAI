// lib/components/recipe_chat_preview.dart
import 'package:flutter/material.dart';
import '../services/recipe_generator_service.dart';
import '../components/category_tags.dart';

class RecipeChatPreview extends StatelessWidget {
  final RecipeGenerationResult recipe;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onSave;

  const RecipeChatPreview({
    Key? key,
    required this.recipe,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isExpanded 
        ? _buildExpandedView() 
        : _buildPreviewView();
  }

  Widget _buildPreviewView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe title
        Text(
          recipe.title,
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
            color: Color(0xFF030303),
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
        ...recipe.ingredients.take(3).map((ingredient) {
          return Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.black87),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ingredient,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (recipe.ingredients.length > 3)
          InkWell(
            onTap: onToggleExpand,
            child: Text(
              '...and ${recipe.ingredients.length - 3} more ingredients +',  // Added + sign
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Open Sans',
                fontStyle: FontStyle.italic,
                color: Color(0xFF673AB7),  // Changed to purple
                decoration: TextDecoration.none,  // Removed underline
              ),
            ),
          ),
        SizedBox(height: 16),
        
        // Button to save recipe
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFFFC1),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
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
    // Expanded view remains unchanged
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe title
        Text(
          recipe.title,
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
            color: Color(0xFF030303),
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
        ...recipe.ingredients.map((ingredient) {
          return Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.black87),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ingredient,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ),
              ],
            ),
          );
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
        ...recipe.instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: EdgeInsets.only(right: 8, top: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFFC1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
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
                      fontSize: 16,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
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
        Text(
          'Serving size: ${recipe.nutrition.servingSize}',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Open Sans',
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calories: ${recipe.nutrition.caloriesPerServing} kcal',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Protein: ${recipe.nutrition.protein}${recipe.nutrition.unit}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Fat: ${recipe.nutrition.fat}${recipe.nutrition.unit}',
                    style: TextStyle(fontSize: 16),
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
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Fiber: ${recipe.nutrition.fiber}${recipe.nutrition.unit}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Sugar: ${recipe.nutrition.sugar}${recipe.nutrition.unit}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Button to save recipe
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFFFC1),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
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
}