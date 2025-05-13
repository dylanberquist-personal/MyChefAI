// lib/services/recipe_generator_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/nutrition.dart';

class RecipeGenerationResult {
  final String title;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> categoryTags;
  final bool respectsDietaryRestrictions;
  final Nutrition nutrition;

  RecipeGenerationResult({
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.categoryTags,
    required this.respectsDietaryRestrictions,
    required this.nutrition,
  });
}

// New class to hold previous recipe context for modifications
class RecipeModificationContext {
  final String title;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> categoryTags;

  RecipeModificationContext({
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.categoryTags,
  });
}

class RecipeGeneratorService {
  // Original method for generating a new recipe
  static Future<RecipeGenerationResult> generateRecipe(String prompt, String? dietaryRestrictions) async {
    // Add dietary restrictions to the prompt if available
    String dietaryPrompt = '';
    if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
      dietaryPrompt = '''
      IMPORTANT: This recipe MUST respect the following dietary restrictions/preferences:
      ${dietaryRestrictions}
      
      Do not include any ingredients that violate these restrictions. All ingredients and preparation methods must be fully compatible with these dietary needs.
      ''';
    }
    
    // Prepare the request prompt
    final String requestPrompt = '''
    Create a detailed recipe based on this request: "${prompt.trim()}"
    
    ${dietaryPrompt}
    
    Format your response as a JSON object with the following structure:
    {
      "title": "Recipe Title",
      "ingredients": ["Ingredient 1", "Ingredient 2", ...],
      "instructions": ["Step 1", "Step 2", ...],
      "categoryTags": ["Tag1", "Tag2", ...] (limit to 5 tags),
      "respectsDietaryRestrictions": true/false (whether this recipe respects the user's dietary restrictions),
      "nutrition": {
        "numberOfServings": 4,
        "caloriesPerServing": 300,
        "carbs": 30.5,
        "protein": 15.2,
        "fat": 12.1,
        "saturatedFat": 5.2,
        "polyunsaturatedFat": 2.1,
        "monounsaturatedFat": 4.8,
        "transFat": 0.0,
        "cholesterol": 25.0,
        "sodium": 500.0,
        "potassium": 350.0,
        "fiber": 4.5,
        "sugar": 8.2,
        "vitaminA": 20.0,
        "vitaminC": 35.0,
        "calcium": 120.0,
        "iron": 3.0,
        "unit": "g",
        "servingSize": "1 cup (240g)"
      }
    }
    
    IMPORTANT: 
    1. Return ONLY the JSON object without any markdown formatting, explanation, or code blocks.
    2. For ingredients or instructions that have sections (like "For the crust:" or "For the filling:"), include the section header as a separate item in the array with a colon at the end.
    3. NEVER include numbers (like "1.", "2.", etc.) at the beginning of instruction steps - these will be added automatically by the app.
    4. You can use special characters, such as degree symbols (°), fractions (½, ¼, etc.), and non-English letters with accents.
    
    Ensure all nutrition values are realistic for the recipe type, and provide detailed step-by-step instructions.
    ''';
    
    // Make API request and process as before
    return await _makeRecipeRequest(requestPrompt);
  }

  // New method for modifying an existing recipe
  static Future<RecipeGenerationResult> modifyRecipe(
    String prompt, 
    String? dietaryRestrictions,
    RecipeModificationContext context
  ) async {
    // Add dietary restrictions to the prompt if available
    String dietaryPrompt = '';
    if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
      dietaryPrompt = '''
      IMPORTANT: This recipe MUST respect the following dietary restrictions/preferences:
      ${dietaryRestrictions}
      
      Do not include any ingredients that violate these restrictions. All ingredients and preparation methods must be fully compatible with these dietary needs.
      ''';
    }
    
    // Format the context for the API prompt
    final String contextString = '''
    Here is the current recipe to modify:
    
    TITLE: ${context.title}
    
    INGREDIENTS:
    ${context.ingredients.map((i) => "- $i").join('\n')}
    
    INSTRUCTIONS:
    ${context.instructions.map((i) => "- $i").join('\n')}
    
    CATEGORY TAGS:
    ${context.categoryTags.join(', ')}
    ''';
    
    // Prepare the request prompt
    final String requestPrompt = '''
    Please modify the existing recipe based on the following request: "${prompt.trim()}"
    
    ${contextString}
    
    ${dietaryPrompt}
    
    Make appropriate changes to the recipe while maintaining its core identity unless specifically requested otherwise. Apply the modifications intelligently.
    
    Format your response as a JSON object with the following structure:
    {
      "title": "Recipe Title",
      "ingredients": ["Ingredient 1", "Ingredient 2", ...],
      "instructions": ["Step 1", "Step 2", ...],
      "categoryTags": ["Tag1", "Tag2", ...] (limit to 5 tags),
      "respectsDietaryRestrictions": true/false (whether this recipe respects the user's dietary restrictions),
      "nutrition": {
        "numberOfServings": 4,
        "caloriesPerServing": 300,
        "carbs": 30.5,
        "protein": 15.2,
        "fat": 12.1,
        "saturatedFat": 5.2,
        "polyunsaturatedFat": 2.1,
        "monounsaturatedFat": 4.8,
        "transFat": 0.0,
        "cholesterol": 25.0,
        "sodium": 500.0,
        "potassium": 350.0,
        "fiber": 4.5,
        "sugar": 8.2,
        "vitaminA": 20.0,
        "vitaminC": 35.0,
        "calcium": 120.0,
        "iron": 3.0,
        "unit": "g",
        "servingSize": "1 cup (240g)"
      }
    }
    
    IMPORTANT: 
    1. Return ONLY the JSON object without any markdown formatting, explanation, or code blocks.
    2. For ingredients or instructions that have sections (like "For the crust:" or "For the filling:"), include the section header as a separate item in the array with a colon at the end.
    3. NEVER include numbers (like "1.", "2.", etc.) at the beginning of instruction steps - these will be added automatically by the app.
    4. You can use special characters, such as degree symbols (°), fractions (½, ¼, etc.), and non-English letters with accents.
    
    Ensure all nutrition values are realistic for the recipe type, and provide detailed step-by-step instructions.
    ''';
    
    // Make API request and process as before
    return await _makeRecipeRequest(requestPrompt);
  }

  // Extracted common API request handling
  static Future<RecipeGenerationResult> _makeRecipeRequest(String requestPrompt) async {
    // Make the API request
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiKeys.openAI}',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional chef who creates detailed, accurate recipes. You always respond with valid JSON only, no markdown formatting. You can use special characters like degrees (°), fractions (½), and accented characters (é,è,ñ,etc.) in your recipes.'
          },
          {
            'role': 'user',
            'content': requestPrompt
          }
        ],
        'temperature': 0.7,
        'max_tokens': 1500
      }),
    );
    
    if (response.statusCode == 200) {
      // Ensure proper UTF-8 decoding
      final String responseBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> responseData = jsonDecode(responseBody);
      final String content = responseData['choices'][0]['message']['content'];
      
      // Clean up the content to handle potential markdown formatting
      String cleanContent = content.trim();
      
      // If content starts with markdown code block, remove it
      if (cleanContent.startsWith('```json')) {
        cleanContent = cleanContent.substring(7);
      } else if (cleanContent.startsWith('```')) {
        cleanContent = cleanContent.substring(3);
      }
      
      // If content ends with markdown code block, remove it
      if (cleanContent.endsWith('```')) {
        cleanContent = cleanContent.substring(0, cleanContent.length - 3);
      }
      
      // Trim any extra whitespace
      cleanContent = cleanContent.trim();
      
      // Decode the JSON properly with UTF-8 support
      final Map<String, dynamic> recipeData = jsonDecode(cleanContent);
      final nutritionData = recipeData['nutrition'];
      
      // Clean instructions to remove any step numbers
      List<String> cleanedInstructions = List<String>.from(recipeData['instructions']).map((instruction) {
        // Remove numbering patterns like "1. ", "2) ", "Step 1:", etc.
        String cleaned = instruction.replaceAll(RegExp(r'^\s*(?:\d+[\.\)]\s*|\bStep\s+\d+[:\.\)]\s*)', caseSensitive: false), '');
        // Capitalize the first letter if it got lowercased
        if (cleaned.isNotEmpty) {
          cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
        }
        return cleaned;
      }).toList();
      
      return RecipeGenerationResult(
        title: recipeData['title'],
        ingredients: List<String>.from(recipeData['ingredients']),
        instructions: cleanedInstructions,
        categoryTags: List<String>.from(recipeData['categoryTags']),
        respectsDietaryRestrictions: recipeData['respectsDietaryRestrictions'] ?? true,
        nutrition: Nutrition(
          numberOfServings: nutritionData['numberOfServings'],
          caloriesPerServing: nutritionData['caloriesPerServing'],
          carbs: nutritionData['carbs'].toDouble(),
          protein: nutritionData['protein'].toDouble(),
          fat: nutritionData['fat'].toDouble(),
          saturatedFat: nutritionData['saturatedFat'].toDouble(),
          polyunsaturatedFat: nutritionData['polyunsaturatedFat'].toDouble(),
          monounsaturatedFat: nutritionData['monounsaturatedFat'].toDouble(),
          transFat: nutritionData['transFat'].toDouble(),
          cholesterol: nutritionData['cholesterol'].toDouble(),
          sodium: nutritionData['sodium'].toDouble(),
          potassium: nutritionData['potassium'].toDouble(),
          fiber: nutritionData['fiber'].toDouble(),
          sugar: nutritionData['sugar'].toDouble(),
          vitaminA: nutritionData['vitaminA'].toDouble(),
          vitaminC: nutritionData['vitaminC'].toDouble(),
          calcium: nutritionData['calcium'].toDouble(),
          iron: nutritionData['iron'].toDouble(),
          unit: nutritionData['unit'],
          servingSize: nutritionData['servingSize'],
        ),
      );
    } else {
      throw Exception('Failed to generate recipe: ${response.body}');
    }
  }
}