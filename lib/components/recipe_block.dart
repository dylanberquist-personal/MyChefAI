import 'package:flutter/material.dart';
import '../models/recipe.dart'; // Import the Recipe model
import '../screens/recipe_screen.dart'; // Import the RecipeScreen

class RecipeBlock extends StatelessWidget {
  final Recipe recipe; // Pass the recipe data to the block

  const RecipeBlock({required this.recipe, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 48, // Match the width of the home screen elements
      child: Card(
        elevation: 4, // Add shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners
        ),
        color: Colors.white, // Set background color to white
        margin: EdgeInsets.only(top: 16), // Add top margin
        child: InkWell(
          borderRadius: BorderRadius.circular(16), // Match the Card's border radius
          onTap: () {
            // Navigate to RecipeScreen when tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeScreen(recipe: recipe),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  recipe.image ?? 'assets/images/recipe_image_placeholder.png', // Use local placeholder if recipe image is null
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/recipe_image_placeholder.png', // Fallback if network image fails
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Title
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8), // Spacing
                    // Creator Info
                    Row(
                      children: [
                        // Profile Picture
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            recipe.creator.profilePicture ?? 'assets/images/profile_image_placeholder.png', // Use local placeholder if profile image is null
                          ),
                          radius: 16,
                          child: recipe.creator.profilePicture == null
                              ? Image.asset(
                                  'assets/images/profile_image_placeholder.png', // Fallback if profile image is null
                                  fit: BoxFit.cover,
                                )
                              : null, // Show nothing if the image is valid
                        ),
                        SizedBox(width: 8), // Spacing
                        // Creator Name
                        Text(
                          recipe.creator.username,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16), // Spacing
                    // Star Rating and Favorites
                    Row(
                      children: [
                        // Star Rating
                        Row(
                          children: [
                            // Full Stars
                            for (int i = 0; i < recipe.averageRating.floor(); i++)
                              Icon(Icons.star, color: Colors.amber, size: 20),
                            // Half Star (if applicable)
                            if (recipe.averageRating - recipe.averageRating.floor() >= 0.5)
                              Icon(Icons.star_half, color: Colors.amber, size: 20),
                            // Empty Stars
                            for (int i = 0; i < 5 - recipe.averageRating.ceil(); i++)
                              Icon(Icons.star_border, color: Colors.amber, size: 20),
                            SizedBox(width: 8), // Spacing
                            // Rating Text
                            Text(
                              '${recipe.averageRating.toStringAsFixed(1)} (${recipe.numberOfRatings})',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        Spacer(), // Add space between rating and favorites
                        // Favorites
                        Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red, size: 20),
                            SizedBox(width: 4),
                            Text(
                              recipe.numberOfFavorites.toString(),
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}