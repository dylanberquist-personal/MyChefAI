import 'package:flutter/material.dart';
import '../models/nutrition.dart';
import '../components/header_text.dart';
import '../components/category_tags.dart';

class GeneratedRecipeView extends StatelessWidget {
  final String title;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> categoryTags;
  final Nutrition? nutrition;
  final bool respectsDietaryRestrictions;
  final String? dietaryRestrictions;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback? onTryAgain;

  const GeneratedRecipeView({
    Key? key,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.categoryTags,
    this.nutrition,
    required this.respectsDietaryRestrictions,
    this.dietaryRestrictions,
    required this.isLoading,
    required this.onSave,
    this.onTryAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(text: 'Generated Recipe'),
        SizedBox(height: 16),
        
        // Dietary restrictions badge
        if (dietaryRestrictions != null && dietaryRestrictions!.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: respectsDietaryRestrictions 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: respectsDietaryRestrictions ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  respectsDietaryRestrictions 
                      ? Icons.check_circle 
                      : Icons.warning,
                  color: respectsDietaryRestrictions ? Colors.green : Colors.red,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  respectsDietaryRestrictions 
                      ? 'Respects your dietary preferences' 
                      : 'May not respect all dietary preferences',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w500,
                    color: respectsDietaryRestrictions ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        
        // Recipe Title
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
            color: Color(0xFF030303),
          ),
        ),
        SizedBox(height: 24),
        
        // Category Tags
        CategoryTags(tags: categoryTags),
        SizedBox(height: 24),
        
        // Ingredients Section
        Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
            color: Color(0xFF030303),
          ),
        ),
        SizedBox(height: 8),
        ...List.generate(ingredients.length, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.circle, size: 8, color: Colors.black),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  ingredients[index],
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ),
            ],
          ),
        )),
        SizedBox(height: 24),
        
        // Instructions Section
        Text(
          'Instructions',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
            color: Color(0xFF030303),
          ),
        ),
        SizedBox(height: 8),
        ...List.generate(instructions.length, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}.',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  instructions[index],
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ),
            ],
          ),
        )),
        SizedBox(height: 24),
        
        // Nutrition Info
        if (nutrition != null) ...[
          Text(
            'Nutrition (per serving)',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              color: Color(0xFF030303),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Serving size: ${nutrition!.servingSize}',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Open Sans',
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Calories: ${nutrition!.caloriesPerServing} kcal',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Open Sans',
            ),
          ),
          Text(
            'Protein: ${nutrition!.protein}${nutrition!.unit}',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Open Sans',
            ),
          ),
          Text(
            'Carbs: ${nutrition!.carbs}${nutrition!.unit}',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Open Sans',
            ),
          ),
          Text(
            'Fat: ${nutrition!.fat}${nutrition!.unit}',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Open Sans',
            ),
          ),
        ],
        
        // Save Button
        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFFFC1),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 2,
            ),
            child: isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                )
              : Text(
                  'Save Recipe',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ),
        
        // Try again button
        if (onTryAgain != null && !respectsDietaryRestrictions) ...[
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: onTryAgain,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: BorderSide(color: Colors.black),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        
        SizedBox(height: 40), // Bottom padding
      ],
    );
  }
}