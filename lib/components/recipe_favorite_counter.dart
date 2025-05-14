// lib/components/recipe_favorite_counter.dart
import 'package:flutter/material.dart';

class RecipeFavoriteCounter extends StatelessWidget {
  final int favoriteCount;
  
  const RecipeFavoriteCounter({
    Key? key,
    required this.favoriteCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.favorite,
          color: Colors.red,
          size: 24,
        ),
        SizedBox(width: 8),
        Text(
          '$favoriteCount ${favoriteCount == 1 ? 'person' : 'people'} favorited this recipe',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Open Sans',
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}