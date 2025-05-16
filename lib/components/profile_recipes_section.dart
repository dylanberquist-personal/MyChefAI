// lib/components/profile_recipes_section.dart
import 'package:flutter/material.dart';
import '../components/header_text.dart';
import '../components/recipe_block.dart';
import '../models/recipe.dart';

class ProfileRecipesSection extends StatelessWidget {
  final List<Recipe> recipes;
  final double contentSpacing;
  final double sectionSpacing;

  const ProfileRecipesSection({
    Key? key,
    required this.recipes,
    this.contentSpacing = 12.0,
    this.sectionSpacing = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              HeaderText(text: 'Recipes'),
              Positioned(
                right: 0,
                child: Text(
                  '${recipes.length} ${recipes.length == 1 ? 'recipe' : 'recipes'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: contentSpacing),
        if (recipes.isEmpty)
          Center(
            child: Text(
              'No recipes yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
        else
          Column(
            children: recipes.map((r) => Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: RecipeBlock(recipe: r),
            )).toList(),
          ),
        SizedBox(height: sectionSpacing),
      ],
    );
  }
}