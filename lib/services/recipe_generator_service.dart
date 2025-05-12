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

class RecipeGeneratorService {
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
    
    IMPORTANT: Return ONLY the JSON object without any markdown formatting, explanation, or code blocks.
    
    Ensure all nutrition values are realistic for the recipe type, and provide detailed step-by-step instructions.
    ''';
    
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
            'content': 'You are a professional chef who creates detailed, accurate recipes. You always respond with valid JSON only, no markdown formatting.'
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
      final Map<String, dynamic> responseData = jsonDecode(response.body);
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
      
      print('Parsed content: $cleanContent'); // Debug log
      
      // Parse the JSON from the cleaned content
      final Map<String, dynamic> recipeData = jsonDecode(cleanContent);
      final nutritionData = recipeData['nutrition'];
      
      return RecipeGenerationResult(
        title: recipeData['title'],
        ingredients: List<String>.from(recipeData['ingredients']),
        instructions: List<String>.from(recipeData['instructions']),
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