import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../components/recipe_block.dart';
import '../components/header_text.dart';
import '../services/profile_service.dart';
import '../services/recipe_service.dart';
import '../services/auth_service.dart';
import '../components/persistent_bottom_nav_scaffold.dart';
import '../navigation/no_animation_page_route.dart';
import '../screens/home_screen.dart';

class FavoriteRecipesScreen extends StatefulWidget {
  final String userId;

  const FavoriteRecipesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _FavoriteRecipesScreenState createState() => _FavoriteRecipesScreenState();
}

class _FavoriteRecipesScreenState extends State<FavoriteRecipesScreen> {
  final ProfileService _profileService = ProfileService();
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
  
  List<Recipe> _favoriteRecipes = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId; // Store the user ID
    _loadFavoriteRecipes();
  }

  Future<void> _loadFavoriteRecipes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get the user's favorite recipe IDs
      final profile = await _profileService.getProfileById(widget.userId);
      if (profile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch each favorite recipe
      List<Recipe> favorites = [];
      for (String recipeId in profile.myFavorites) {
        final recipe = await _recipeService.getRecipeById(recipeId);
        if (recipe != null) {
          favorites.add(recipe);
        }
      }

      if (mounted) {
        setState(() {
          _favoriteRecipes = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorite recipes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return PersistentBottomNavScaffold(
      currentUserId: _currentUserId,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Your favorites',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Transform.translate(
          offset: Offset(8, 0),
          child: Transform.scale(
            scale: 1.2,
            child: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
      onNavItemTap: (index) {
        if (index == 0) {
          _navigateToHome();
        } else if (index == 4 && _currentUserId != null) {
          Navigator.pop(context);
        }
      },
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _favoriteRecipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No favorite recipes yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavoriteRecipes,
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 24,
                      right: 24,
                      bottom: 80,
                    ),
                    itemCount: _favoriteRecipes.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: RecipeBlock(recipe: _favoriteRecipes[index]),
                      );
                    },
                  ),
                ),
    );
  }
}