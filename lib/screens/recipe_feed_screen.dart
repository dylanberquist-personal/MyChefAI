// lib/screens/recipe_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../components/recipe_block.dart';
import '../services/recipe_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../components/persistent_bottom_nav_scaffold.dart';
import '../navigation/no_animation_page_route.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

class RecipeFeedScreen extends StatefulWidget {
  const RecipeFeedScreen({Key? key}) : super(key: key);

  @override
  _RecipeFeedScreenState createState() => _RecipeFeedScreenState();
}

class _RecipeFeedScreenState extends State<RecipeFeedScreen> {
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String? _currentUserId;
  
  // For pagination
  bool _hasMoreRecipes = true;
  bool _isLoadingMore = false;
  int _limit = 10;
  Recipe? _lastRecipe;
  
  // For filtering
  bool _showOnlyFollowing = false;
  List<String> _followingIds = [];
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    
    // Set up scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoadingMore &&
          _hasMoreRecipes) {
        _loadMoreRecipes();
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.uid;
      });
      
      // Fetch the list of profiles the user is following
      await _fetchFollowing();
    }
  }
  
  Future<void> _fetchFollowing() async {
    if (_currentUserId == null) return;
    
    try {
      print('Fetching following list for user: $_currentUserId');
      
      // Directly query Firestore to get the following list
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(_currentUserId)
          .get();
      
      if (doc.exists) {
        // Try to get the following list directly from the document
        final data = doc.data() as Map<String, dynamic>;
        
        if (data.containsKey('following') && data['following'] != null) {
          List<dynamic> following = data['following'];
          setState(() {
            _followingIds = List<String>.from(following);
          });
          
          print('Fetched ${_followingIds.length} following IDs directly from Firestore: $_followingIds');
        } else {
          print('Following field not found in profile document');
          // Initialize as empty list
          setState(() {
            _followingIds = [];
          });
        }
      } else {
        print('Profile document does not exist in Firestore');
        setState(() {
          _followingIds = [];
        });
      }
      
      // Now load recipes
      _loadInitialRecipes();
    } catch (e) {
      print('Error fetching following IDs: $e');
      setState(() {
        _followingIds = [];
      });
      _loadInitialRecipes();
    }
  }

  Future<void> _loadInitialRecipes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Recipe> recipes = [];
      
      if (_showOnlyFollowing) {
        // If showing only following but not following anyone, show empty list
        if (_followingIds.isEmpty) {
          print('Following list is empty, showing no recipes in Following mode');
          // Just leave recipes as an empty list
        } else {
          // Get recipes only from followed profiles
          print('Loading recipes from following: ${_followingIds.length} profiles');
          recipes = await _recipeService.getRecipesFromFollowing(_followingIds, _limit);
        }
      } else {
        // Get all recent recipes
        print('Loading all recent recipes');
        recipes = await _recipeService.getRecentRecipes(_limit);
      }
      
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
          
          // If we got fewer recipes than the limit, we have no more recipes to load
          _hasMoreRecipes = recipes.length >= _limit;
          
          // Set the last recipe for pagination
          if (recipes.isNotEmpty) {
            _lastRecipe = recipes.last;
          }
        });
      }
    } catch (e) {
      print('Error loading recipes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadMoreRecipes() async {
    if (!_hasMoreRecipes || _isLoadingMore) return;
    
    try {
      setState(() {
        _isLoadingMore = true;
      });
      
      List<Recipe> moreRecipes = [];
      
      if (_showOnlyFollowing) {
        // If showing only following but not following anyone, return empty list
        if (_followingIds.isEmpty) {
          // Just leave moreRecipes as an empty list
        } else {
          // Get more recipes only from followed profiles
          moreRecipes = await _recipeService.getMoreRecipesFromFollowing(
            _followingIds, 
            _limit, 
            _lastRecipe?.createdAt
          );
        }
      } else {
        // Get more recent recipes from all profiles
        moreRecipes = await _recipeService.getMoreRecentRecipes(
          _limit, 
          _lastRecipe?.createdAt
        );
      }
      
      if (mounted) {
        setState(() {
          if (moreRecipes.isNotEmpty) {
            _recipes.addAll(moreRecipes);
            _lastRecipe = moreRecipes.last;
          }
          
          // If we got fewer recipes than the limit, we have no more recipes to load
          _hasMoreRecipes = moreRecipes.length >= _limit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }
  
  Future<void> _refreshRecipes() async {
    // First, re-fetch the following list in case it changed
    await _fetchFollowing();
    
    // Reset pagination parameters
    _hasMoreRecipes = true;
    _lastRecipe = null;
    
    // Then load the recipes - this is already called at the end of _fetchFollowing()
  }
  
  void _toggleShowFollowing() {
    setState(() {
      _showOnlyFollowing = !_showOnlyFollowing;
      // Reset pagination parameters
      _hasMoreRecipes = true;
      _lastRecipe = null;
    });
    
    // Reload recipes with the new filter
    _loadInitialRecipes();
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      NoAnimationPageRoute(
        builder: (context) => HomeScreen(),
      ),
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
          'Recipe Feed',
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
        actions: [
          // Toggle button for showing only following - positioned 20px from the right edge
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: TextButton.icon(
              onPressed: _toggleShowFollowing,
              icon: Icon(
                _showOnlyFollowing ? Icons.people : Icons.public,
                color: _showOnlyFollowing ? Colors.black : Colors.grey,
              ),
              label: Text(
                _showOnlyFollowing ? 'Following' : 'All',
                style: TextStyle(
                  color: _showOnlyFollowing ? Colors.black : Colors.grey,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _showOnlyFollowing ? Color(0xFFFFFFC1).withOpacity(0.3) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.black, width: 1), // Added black outline
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
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
          _navigateToProfile();
        }
      },
      body: RefreshIndicator(
        onRefresh: _refreshRecipes,
        child: _isLoading
            ? ListView(
                // Make sure we have something to pull down on even during loading
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height - 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : _recipes.isEmpty
                ? ListView(
                    // Make sure we have something to pull down on when empty
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height - 100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _showOnlyFollowing 
                                    ? _followingIds.isEmpty
                                        ? 'You are not following anyone yet'
                                        : 'No recipes from profiles you follow'
                                    : 'No recipes found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                              // Show appropriate action button based on state
                              if (_showOnlyFollowing)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: ElevatedButton(
                                    onPressed: _toggleShowFollowing,
                                    style: TextButton.styleFrom(
                                      backgroundColor: Color(0xFFFFFFC1),
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: Text(
                                      'Show all recipes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontFamily: 'Open Sans',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 24,
                      right: 24,
                      bottom: 80,
                    ),
                    itemCount: _recipes.length + (_hasMoreRecipes ? 1 : 0),
                    itemBuilder: (context, index) {
                      // If we're at the end and have more recipes, show a loading indicator
                      if (index == _recipes.length) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: RecipeBlock(recipe: _recipes[index]),
                      );
                    },
                  ),
      ),
    );
  }
}