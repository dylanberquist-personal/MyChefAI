import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../screens/recipe_screen.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';

class RecipeBlock extends StatefulWidget {
  final Recipe recipe;

  const RecipeBlock({required this.recipe, Key? key}) : super(key: key);

  @override
  _RecipeBlockState createState() => _RecipeBlockState();
}

class _RecipeBlockState extends State<RecipeBlock> {
  final AuthService _authService = AuthService();
  final RecipeService _recipeService = RecipeService();
  bool _isFavorited = false;
  bool _isLoading = true;
  String? _currentUserId;
  late Recipe _currentRecipe;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
    _loadUserAndFavoriteStatus();
  }

  Future<void> _loadUserAndFavoriteStatus() async {
    final user = await _authService.getCurrentUser();
    if (user != null && _currentRecipe.id != null) {
      final userId = user.uid;
      
      // Fetch the latest recipe data from Firestore
      try {
        final updatedRecipe = await _recipeService.getUpdatedRecipe(_currentRecipe.id!);
        if (updatedRecipe != null && mounted) {
          setState(() {
            _currentRecipe = updatedRecipe;
          });
        }
      } catch (e) {
        print('Error refreshing recipe data: $e');
      }
      
      // Check if this recipe is favorited by the current user
      final favorited = await _recipeService.isRecipeFavorited(
        _currentRecipe.id!,
        userId,
      );
      
      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _isFavorited = favorited;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 48,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        margin: EdgeInsets.only(top: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeScreen(recipe: _currentRecipe),
              ),
            ).then((_) {
              // Refresh favorite status and recipe data when returning from recipe screen
              _loadUserAndFavoriteStatus();
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  _currentRecipe.image ?? 'assets/images/recipe_image_placeholder.png',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/recipe_image_placeholder.png',
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
                      _currentRecipe.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Creator Info
                    Row(
                      children: [
                        // Profile Picture
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            _currentRecipe.creator.profilePicture ?? 'assets/images/profile_image_placeholder.png',
                          ),
                          radius: 16,
                          child: _currentRecipe.creator.profilePicture == null
                              ? Image.asset(
                                  'assets/images/profile_image_placeholder.png',
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        SizedBox(width: 8),
                        // Creator Name
                        Text(
                          _currentRecipe.creator.username,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Star Rating and Favorites
                    Row(
                      children: [
                        // Star Rating
                        Row(
                          children: [
                            // Full Stars
                            for (int i = 0; i < _currentRecipe.averageRating.floor(); i++)
                              Icon(Icons.star, color: Colors.amber, size: 20),
                            // Half Star (if applicable)
                            if (_currentRecipe.averageRating - _currentRecipe.averageRating.floor() >= 0.5)
                              Icon(Icons.star_half, color: Colors.amber, size: 20),
                            // Empty Stars
                            for (int i = 0; i < 5 - _currentRecipe.averageRating.ceil(); i++)
                              Icon(Icons.star_border, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            // Rating Text
                            Text(
                              '${_currentRecipe.averageRating.toStringAsFixed(1)} (${_currentRecipe.numberOfRatings})',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        Spacer(),
                        // Favorites
                        Row(
                          children: [
                            Icon(
                              _isLoading ? Icons.favorite_border : (_isFavorited ? Icons.favorite : Icons.favorite_border),
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _currentRecipe.numberOfFavorites.toString(),
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