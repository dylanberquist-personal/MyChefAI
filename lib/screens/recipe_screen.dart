import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/profile.dart';
import '../components/profile_block.dart';
import '../components/recipe_title_bar.dart';
import '../components/category_tags.dart';
import '../components/rating_block.dart';
import '../components/footer_nav_bar.dart';
import '../components/header_text.dart';
import '../components/recipe_options_menu.dart';
import '../components/nutrition_info_dialog.dart';
import '../components/persistent_bottom_nav_scaffold.dart';
import '../navigation/no_animation_page_route.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/recipe_service.dart';
import '../screens/profile_screen.dart';
import '../screens/home_screen.dart';

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
  
  @override
  void initState() {
    super.initState();
    // Create a copy of the recipe to work with
    _currentRecipe = widget.recipe;
    _fetchCurrentUser();
    _fetchCreatorProfile();
    _refreshRecipeData();
  }
  
  // Fetch the latest recipe data
  Future<void> _refreshRecipeData() async {
    if (_currentRecipe.id == null) return;
    
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
  
  // Check if current user is the recipe owner
  bool _isRecipeOwner() {
    return _currentUserId != null && _currentRecipe.creator.uid == _currentUserId;
  }
  
  // Toggle public/private status of recipe
  Future<void> _togglePublicStatus() async {
    if (!_isRecipeOwner() || _currentRecipe.id == null) return;
    
    // Optimistically update UI
    setState(() {
      _currentRecipe.isPublic = !_currentRecipe.isPublic;
    });
    
    try {
      // Update the recipe in Firestore
      final updatedRecipe = Recipe(
        id: _currentRecipe.id,
        title: _currentRecipe.title,
        image: _currentRecipe.image,
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
      
      await _recipeService.updateRecipe(updatedRecipe);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe is now ${_currentRecipe.isPublic ? 'public' : 'private'}')),
      );
    } catch (e) {
      // Revert if operation fails
      setState(() {
        _currentRecipe.isPublic = !_currentRecipe.isPublic;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating recipe: ${e.toString()}')),
      );
    }
  }
  
  // Show nutrition info dialog
  void _showNutritionInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NutritionInfoDialog(
          nutritionInfo: _currentRecipe.nutritionInfo,
        );
      },
    );
  }

  void _navigateToProfile() {
    if (_currentUserId != null) {
      Navigator.push(
        context,
        NoAnimationPageRoute(
          builder: (context) => ProfileScreen(userId: _currentUserId!),
        ),
      );
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

  // Handle options menu selection
  void _showOptionsMenu(GlobalKey optionsButtonKey) {
    final bool isOwner = _isRecipeOwner();
    
    // Get the render box from the button's key
    final RenderBox renderBox = optionsButtonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
      ),
      items: [
        // Nutrition Info Option
        PopupMenuItem(
          height: 48, // Reduced height from 56
          padding: EdgeInsets.zero, // Remove default padding
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: isOwner ? Radius.zero : Radius.circular(16),
              ),
            ),
            child: ListTile(
              dense: true, // Makes the ListTile more compact
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
              leading: Icon(Icons.restaurant_menu, color: Colors.green, size: 22), // Slightly smaller icon
              title: Text(
                'Nutrition Info',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF030303),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showNutritionInfo();
              },
            ),
          ),
        ),
        
        // Public/Private Toggle - only for recipe owners
        if (isOwner)
          PopupMenuItem(
            height: 48, // Reduced height from 56
            padding: EdgeInsets.zero, // Remove default padding
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.zero,
                  bottom: Radius.circular(16),
                ),
              ),
              child: ListTile(
                dense: true, // Makes the ListTile more compact
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
                leading: Icon(
                  _currentRecipe.isPublic ? Icons.public : Icons.lock,
                  color: _currentRecipe.isPublic ? Colors.blue : Colors.orange,
                  size: 22, // Slightly smaller icon
                ),
                title: Text(
                  _currentRecipe.isPublic ? 'Make Private' : 'Make Public',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF030303),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _togglePublicStatus();
                },
              ),
            ),
          ),
      ],
      elevation: 8,
      // Style the popup menu to match app design
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
    );
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

    return PersistentBottomNavScaffold(
      currentUserId: _currentUserId,
      backgroundColor: Colors.white,
      appBar: RecipeTitleBar(
        title: _currentRecipe.title,
        isFavorited: isFavorited,
        onBackPressed: () => Navigator.pop(context),
        onFavoritePressed: _toggleFavorite,
        onOptionsPressed: _showOptionsMenu,
      ),
      onNavItemTap: (index) {
        if (index == 4 && _currentUserId != null) {
          _navigateToProfile();
        } else if (index == 0) {
          _navigateToHome();
        }
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _currentRecipe.image ?? 'assets/images/recipe_image_placeholder.png',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/recipe_image_placeholder.png',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Add favorite count display
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  '${_currentRecipe.numberOfFavorites} ${_currentRecipe.numberOfFavorites == 1 ? 'person' : 'people'} favorited this recipe',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ingredients Section
            HeaderText(text: 'Ingredients'),
            const SizedBox(height: 8),
            ..._currentRecipe.ingredients.map((ingredient) => Padding(
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
            ..._currentRecipe.instructions.asMap().entries.map((entry) {
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
    );
  }
}