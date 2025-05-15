import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe.dart';
import '../models/profile.dart';
import '../screens/recipe_screen.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';
import '../services/profile_service.dart';
import '../navigation/no_animation_page_route.dart';

class RecipeBlock extends StatefulWidget {
  final Recipe recipe;

  const RecipeBlock({required this.recipe, Key? key}) : super(key: key);

  @override
  _RecipeBlockState createState() => _RecipeBlockState();
}

class _RecipeBlockState extends State<RecipeBlock> with AutomaticKeepAliveClientMixin {
  final AuthService _authService = AuthService();
  final RecipeService _recipeService = RecipeService();
  final ProfileService _profileService = ProfileService(); 
  
  bool _isFavorited = false;
  bool _isLoading = true;
  String? _currentUserId;
  late Recipe _currentRecipe;
  Profile? _creatorProfile; 

  @override
  bool get wantKeepAlive => true;

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
      
      // Only check favorite status - skip fetching updated recipe
      // and creator profile unless necessary
      try {
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
      } catch (e) {
        print('Error checking favorite status: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
    super.build(context); // Important: call super.build for the keep-alive
    
    // Ensure averageRating is a valid number to prevent NaN or Infinity
    final double safeRating = (_currentRecipe.averageRating.isNaN || 
                             _currentRecipe.averageRating.isInfinite) 
                             ? 0.0 
                             : _currentRecipe.averageRating;
    
    // Ensure we have a valid number of ratings
    final int safeNumberOfRatings = _currentRecipe.numberOfRatings < 0 ? 0 : _currentRecipe.numberOfRatings;
    
    // Ensure we have a valid number of favorites
    final int safeNumberOfFavorites = _currentRecipe.numberOfFavorites < 0 ? 0 : _currentRecipe.numberOfFavorites;

    return SizedBox(
      width: MediaQuery.of(context).size.width - 48,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        margin: EdgeInsets.zero, // Removed top margin
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              NoAnimationPageRoute(
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
              // Recipe Image with caching
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: _currentRecipe.image != null && _currentRecipe.image!.isNotEmpty 
                  ? CachedNetworkImage(
                      imageUrl: _currentRecipe.image!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/recipe_image_placeholder.png',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/recipe_image_placeholder.png',
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                        // Profile Picture with caching
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[200],
                          child: (_creatorProfile?.profilePicture != null && _creatorProfile!.profilePicture!.isNotEmpty) ||
                                 (_currentRecipe.creator.profilePicture != null && _currentRecipe.creator.profilePicture!.isNotEmpty) 
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CachedNetworkImage(
                                    imageUrl: _creatorProfile?.profilePicture ?? _currentRecipe.creator.profilePicture!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 32,
                                      height: 32,
                                      color: Colors.grey[200],
                                    ),
                                    errorWidget: (context, url, error) => Image.asset(
                                      'assets/images/profile_image_placeholder.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/profile_image_placeholder.png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        SizedBox(width: 8),
                        // Creator Name - Using the latest username if available
                        Text(
                          _creatorProfile?.username ?? _currentRecipe.creator.username,
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
                            for (int i = 0; i < safeRating.floor(); i++)
                              Icon(Icons.star, color: Colors.amber, size: 20),
                            // Half Star (if applicable)
                            if (safeRating - safeRating.floor() >= 0.5)
                              Icon(Icons.star_half, color: Colors.amber, size: 20),
                            // Empty Stars
                            for (int i = 0; i < 5 - safeRating.ceil(); i++)
                              Icon(Icons.star_border, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            // Rating Text
                            Text(
                              '${safeRating.toStringAsFixed(1)} ($safeNumberOfRatings)',
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
                              safeNumberOfFavorites.toString(),
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