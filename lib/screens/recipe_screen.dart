// lib/screens/recipe_screen.dart

import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/profile.dart';
import '../components/profile_block.dart';
import '../components/recipe_title_bar.dart';
import '../components/category_tags.dart';
import '../components/rating_block.dart';
import '../components/header_text.dart';
import '../components/persistent_bottom_nav_scaffold.dart';
import '../components/recipe_image_section.dart';
import '../components/recipe_content_section.dart';
import '../components/recipe_favorite_counter.dart';
import '../navigation/no_animation_page_route.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/recipe_service.dart';
import '../components/recipe_options_helper.dart';
import '../screens/profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/create_recipe_screen.dart';

class RecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  bool isFavorited = false;
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final RecipeService _recipeService = RecipeService();
  String? _currentUserId;
  Profile? _creatorProfile;
  bool _isLoading = true;
  late Recipe _currentRecipe;
  late RecipeOptionsHelper _optionsHelper;
  
  @override
  void initState() {
    super.initState();
    // Create a copy of the recipe to work with
    _currentRecipe = widget.recipe;
    _fetchCurrentUser();
    _fetchCreatorProfile();
    _refreshRecipeData();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _optionsHelper = RecipeOptionsHelper(
      context: context,
      recipe: _currentRecipe,
      currentUserId: _currentUserId,
      onImagePickRequested: () {},  // Will be updated later
      onRefreshRecipe: _refreshRecipeData,
      recipeService: _recipeService,
    );
  }
  
  // Fetch the latest recipe data
  Future<void> _refreshRecipeData() async {
  if (_currentRecipe.id == null) return;
  
  try {
    final updatedRecipe = await _recipeService.getUpdatedRecipe(_currentRecipe.id!, currentUserId: _currentUserId);
    if (updatedRecipe != null && mounted) {
      setState(() {
        _currentRecipe = updatedRecipe;
        // Update the options helper with the new recipe
        _optionsHelper = RecipeOptionsHelper(
          context: context,
          recipe: _currentRecipe,
          currentUserId: _currentUserId,
          onImagePickRequested: () {},  // Will be properly set in didChangeDependencies
          onRefreshRecipe: _refreshRecipeData,
          recipeService: _recipeService,
        );
      });
      
      // Also update favorite status
      if (_currentUserId != null) {
        final favorited = await _recipeService.isRecipeFavorited(
          _currentRecipe.id!,
          _currentUserId!,
        );
        
        if (mounted) {
          setState(() {
            isFavorited = favorited;
          });
        }
      }
    }
  } catch (e) {
    print('Error refreshing recipe data: $e');
  }
}

  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      final userId = user.uid;
      setState(() {
        _currentUserId = userId;
      });
      
      // Check if this recipe is favorited by the current user
      if (_currentRecipe.id != null) {
        final favorited = await _recipeService.isRecipeFavorited(
          _currentRecipe.id!,
          userId,
        );
        
        if (mounted) {
          setState(() {
            isFavorited = favorited;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCreatorProfile() async {
    if (_currentRecipe.creator.uid.isEmpty) {
      print('Creator UID is null or empty');
      return;
    }

    try {
      final profile = await _profileService.getProfileById(_currentRecipe.creator.uid);
      if (profile != null) {
        print('Fetched profile: ${profile.username}');
        setState(() {
          _creatorProfile = profile;
        });
      } else {
        // If we can't fetch the profile from Firestore, use the embedded creator data
        setState(() {
          _creatorProfile = _currentRecipe.creator;
        });
        print('Using embedded creator profile: ${_currentRecipe.creator.username}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      // If there's an error, fall back to using the embedded creator data
      setState(() {
        _creatorProfile = _currentRecipe.creator;
      });
    }
  }

  // Handle image update
  void _handleImageUpdated(String newImageUrl) {
    if (_currentRecipe.id != null) {
      setState(() {
        _currentRecipe = Recipe(
          id: _currentRecipe.id,
          title: _currentRecipe.title,
          image: newImageUrl,
          ingredients: _currentRecipe.ingredients,
          instructions: _currentRecipe.instructions,
          categoryTags: _currentRecipe.categoryTags,
          creator: _currentRecipe.creator,
          averageRating: _currentRecipe.averageRating,
          numberOfRatings: _currentRecipe.numberOfRatings,
          numberOfFavorites: _currentRecipe.numberOfFavorites,
          nutritionInfo: _currentRecipe.nutritionInfo,
          isPublic: _currentRecipe.isPublic,
          isFavorited: _currentRecipe.isFavorited,
          createdAt: _currentRecipe.createdAt,
        );
      });
      
      // Refresh to ensure we have the latest data
      _refreshRecipeData();
    }
  }

  // Method to toggle favorite status
  Future<void> _toggleFavorite() async {
    if (_currentUserId == null || _currentRecipe.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to favorite recipes')),
      );
      return;
    }

    // Optimistically update UI
    setState(() {
      isFavorited = !isFavorited;
      _currentRecipe.numberOfFavorites += isFavorited ? 1 : -1;
    });

    try {
      await _recipeService.toggleFavorite(_currentRecipe.id!, _currentUserId!);
      // After toggling, refresh the recipe data from the server
      await _refreshRecipeData();
    } catch (e) {
      // Revert if operation fails
      setState(() {
        isFavorited = !isFavorited;
        _currentRecipe.numberOfFavorites += isFavorited ? 1 : -1;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Handle rating changes
  void _handleRatingChanged(double newRating) {
    // Refresh the recipe data to get updated ratings
    _refreshRecipeData();
  }

  void _navigateToProfile() {
    if (_currentUserId != null) {
      Navigator.push(
        context,
        NoAnimationPageRoute(
          builder: (context) => ProfileScreen(userId: _currentUserId!),
        ),
      ).then((_) {
        // Refresh data when returning from profile screen
        _refreshRecipeData();
      });
    }
  }
  
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      NoAnimationPageRoute(
        builder: (context) => HomeScreen(),
      ),
    );
  }
  
  void _navigateToCreateRecipe() {
    Navigator.push(
      context,
      NoAnimationPageRoute(
        builder: (context) => CreateRecipeScreen(),
      ),
    ).then((_) {
      // Refresh data when returning from create recipe screen
      _refreshRecipeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Update the options helper's onImagePickRequested callback
    _optionsHelper = RecipeOptionsHelper(
      context: context,
      recipe: _currentRecipe,
      currentUserId: _currentUserId,
      onImagePickRequested: () {}, // We don't need this anymore since we're using RecipeImageSection
      onRefreshRecipe: _refreshRecipeData,
      recipeService: _recipeService,
    );

    return PersistentBottomNavScaffold(
      currentUserId: _currentUserId,
      backgroundColor: Colors.white,
      appBar: RecipeTitleBar(
        title: _currentRecipe.title,
        isFavorited: isFavorited,
        onBackPressed: () => Navigator.pop(context),
        onFavoritePressed: _toggleFavorite,
        onOptionsPressed: _optionsHelper.showOptionsMenu,
      ),
      onNavItemTap: (index) {
        if (index == 0) {
          _navigateToHome();
        } else if (index == 2) {
          _navigateToCreateRecipe();
        } else if (index == 4 && _currentUserId != null) {
          _navigateToProfile();
        }
      },
      body: RefreshIndicator(
        onRefresh: _refreshRecipeData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: RecipeImageSection(
                  recipe: _currentRecipe,
                  currentUserId: _currentUserId,
                  onImageUpdated: _handleImageUpdated,
                ),
              ),
              const SizedBox(height: 16),
              
              // Favorite counter
              RecipeFavoriteCounter(favoriteCount: _currentRecipe.numberOfFavorites),
              const SizedBox(height: 24),

              // Recipe content (ingredients and instructions)
              RecipeContentSection(
                recipe: _currentRecipe,
                currentUserId: _currentUserId,
                onRecipeUpdated: _refreshRecipeData,
              ),
              const SizedBox(height: 24),

              // Category Tags Section
              if (_currentRecipe.categoryTags.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeaderText(text: 'Categories'),
                    const SizedBox(height: 8),
                    CategoryTags(tags: _currentRecipe.categoryTags),
                  ],
                ),
              const SizedBox(height: 24),

              // Creator Profile Block
              HeaderText(text: 'Created By'),
              const SizedBox(height: 8),
              if (_currentRecipe.creator.uid.isEmpty)
                const Center(child: Text('Creator information is missing')),
              if (_currentRecipe.creator.uid.isNotEmpty)
                if (_creatorProfile != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.zero,
                    child: ProfileBlock(profile: _creatorProfile!),
                  ),
              if (_creatorProfile == null && _currentRecipe.creator.uid.isNotEmpty)
                const Center(child: Text('Creator profile not found')),
              const SizedBox(height: 24),

              // Rating Block
              _currentRecipe.id != null && _currentRecipe.id!.isNotEmpty
                ? RatingBlock(
                    recipeId: _currentRecipe.id!,
                    onRatingChanged: _handleRatingChanged,
                  )
                : const Center(child: Text('Cannot rate this recipe')),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}