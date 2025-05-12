import 'package:flutter/material.dart';
import '../components/header_text.dart';

class RecipeForm extends StatelessWidget {
  final TextEditingController promptController;
  final String? dietaryRestrictions;
  final String? errorMessage;
  final bool isLoading;
  final bool isRecipeGenerated;
  final VoidCallback onGenerate;

  const RecipeForm({
    Key? key,
    required this.promptController,
    this.dietaryRestrictions,
    this.errorMessage,
    required this.isLoading,
    required this.isRecipeGenerated,
    required this.onGenerate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prompt Section
        HeaderText(text: 'What would you like to cook?'),
        SizedBox(height: 16),
        
        // Show dietary restrictions if available
        if (dietaryRestrictions != null && dietaryRestrictions!.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFFFFFC1).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(0xFFFFFFC1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.black87,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recipe will account for your dietary preferences: $dietaryRestrictions',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Open Sans',
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
        
        Text(
          'Describe the recipe you want, including ingredients, cuisine type, or dietary preferences.',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Open Sans',
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        
        // Prompt Input Field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(0xFFD3D3D3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: TextField(
            controller: promptController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g., "A healthy pasta dish with mushrooms and spinach"',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Error Message
        if (errorMessage != null)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        
        // Generate Button
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading || (isRecipeGenerated && !isLoading) ? null : onGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFFFC1),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 2,
            ),
            child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Generating...',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Generate Recipe',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}