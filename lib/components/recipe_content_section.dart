// lib/components/recipe_content_section.dart
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../components/header_text.dart';

class RecipeContentSection extends StatelessWidget {
  final Recipe recipe;
  
  const RecipeContentSection({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ingredients Section
        HeaderText(text: 'Ingredients'),
        const SizedBox(height: 8),
        ...recipe.ingredients.map((ingredient) => Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            ingredient,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Open Sans',
            ),
          ),
        )).toList(),
        const SizedBox(height: 24),

        // Instructions Section
        HeaderText(text: 'Instructions'),
        const SizedBox(height: 8),
        ...recipe.instructions.asMap().entries.map((entry) {
          int index = entry.key + 1;
          String step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              '$index. $step',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Open Sans',
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}