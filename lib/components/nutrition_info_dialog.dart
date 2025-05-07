// lib/components/nutrition_info_dialog.dart
import 'package:flutter/material.dart';
import '../models/nutrition.dart';

class NutritionInfoDialog extends StatelessWidget {
  final Nutrition nutritionInfo;

  const NutritionInfoDialog({
    Key? key,
    required this.nutritionInfo,
  }) : super(key: key);

  // Helper to build a nutrition info row
  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Open Sans',
              color: Color(0xFF030303),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w600,
              color: Color(0xFF030303),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Added padding at the top to make room for the close button
                  SizedBox(height: 8),
                  
                  Text(
                    'Nutrition Information',
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
                    'Per serving (${nutritionInfo.numberOfServings} servings total)',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Macronutrients Section
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Macronutrients',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF030303),
                      ),
                    ),
                  ),
                  _buildNutritionRow('Calories', '${nutritionInfo.caloriesPerServing} kcal'),
                  _buildNutritionRow('Carbs', '${nutritionInfo.carbs} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Protein', '${nutritionInfo.protein} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Total Fat', '${nutritionInfo.fat} ${nutritionInfo.unit}'),
                  
                  // Fat Breakdown Section
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      'Fat Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF030303),
                      ),
                    ),
                  ),
                  _buildNutritionRow('Saturated Fat', '${nutritionInfo.saturatedFat} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Polyunsaturated Fat', '${nutritionInfo.polyunsaturatedFat} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Monounsaturated Fat', '${nutritionInfo.monounsaturatedFat} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Trans Fat', '${nutritionInfo.transFat} ${nutritionInfo.unit}'),
                  
                  // Cholesterol & Sodium Section
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      'Cholesterol & Sodium',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF030303),
                      ),
                    ),
                  ),
                  _buildNutritionRow('Cholesterol', '${nutritionInfo.cholesterol} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Sodium', '${nutritionInfo.sodium} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Potassium', '${nutritionInfo.potassium} ${nutritionInfo.unit}'),
                  
                  // Carbs Breakdown
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      'Carbs Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF030303),
                      ),
                    ),
                  ),
                  _buildNutritionRow('Fiber', '${nutritionInfo.fiber} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Sugar', '${nutritionInfo.sugar} ${nutritionInfo.unit}'),
                  
                  // Vitamins & Minerals
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      'Vitamins & Minerals',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF030303),
                      ),
                    ),
                  ),
                  _buildNutritionRow('Vitamin A', '${nutritionInfo.vitaminA} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Vitamin C', '${nutritionInfo.vitaminC} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Calcium', '${nutritionInfo.calcium} ${nutritionInfo.unit}'),
                  _buildNutritionRow('Iron', '${nutritionInfo.iron} ${nutritionInfo.unit}'),
                  
                  // No more close button here
                ],
              ),
            ),
          ),
          
          // Close button (X) at the top right
          Positioned(
            top: 8,
            left: 8,
            child: Transform.scale(
              scale: 1.2, // Make the icon a bit larger, matching the back arrow scale
              child: IconButton(
                icon: Icon(Icons.close),
                color: Colors.black,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}