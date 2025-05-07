// lib/models/nutrition.dart
class Nutrition {
  int numberOfServings;
  int caloriesPerServing;
  double carbs;
  double protein;
  double fat;
  double saturatedFat;
  double polyunsaturatedFat;
  double monounsaturatedFat;
  double transFat;
  double cholesterol;
  double sodium;
  double potassium;
  double fiber;
  double sugar;
  double vitaminA;
  double vitaminC;
  double calcium;
  double iron;
  String unit;
  String servingSize; // Added serving size attribute

  Nutrition({
    required this.numberOfServings,
    required this.caloriesPerServing,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.saturatedFat,
    required this.polyunsaturatedFat,
    required this.monounsaturatedFat,
    required this.transFat,
    required this.cholesterol,
    required this.sodium,
    required this.potassium,
    required this.fiber,
    required this.sugar,
    required this.vitaminA,
    required this.vitaminC,
    required this.calcium,
    required this.iron,
    required this.unit,
    this.servingSize = '', // Default value is empty string
  });

  // Convert Nutrition to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'numberOfServings': numberOfServings,
      'caloriesPerServing': caloriesPerServing,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'saturatedFat': saturatedFat,
      'polyunsaturatedFat': polyunsaturatedFat,
      'monounsaturatedFat': monounsaturatedFat,
      'transFat': transFat,
      'cholesterol': cholesterol,
      'sodium': sodium,
      'potassium': potassium,
      'fiber': fiber,
      'sugar': sugar,
      'vitaminA': vitaminA,
      'vitaminC': vitaminC,
      'calcium': calcium,
      'iron': iron,
      'unit': unit,
      'servingSize': servingSize, // Added to map
    };
  }

  // Create Nutrition from a Firebase document
  factory Nutrition.fromMap(Map<String, dynamic> data) {
    return Nutrition(
      numberOfServings: data['numberOfServings'],
      caloriesPerServing: data['caloriesPerServing'],
      carbs: data['carbs'],
      protein: data['protein'],
      fat: data['fat'],
      saturatedFat: data['saturatedFat'],
      polyunsaturatedFat: data['polyunsaturatedFat'],
      monounsaturatedFat: data['monounsaturatedFat'],
      transFat: data['transFat'],
      cholesterol: data['cholesterol'],
      sodium: data['sodium'],
      potassium: data['potassium'],
      fiber: data['fiber'],
      sugar: data['sugar'],
      vitaminA: data['vitaminA'],
      vitaminC: data['vitaminC'],
      calcium: data['calcium'],
      iron: data['iron'],
      unit: data['unit'],
      servingSize: data['servingSize'] ?? '', // Handle case when field doesn't exist in database
    );
  }
}