// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Import for ScrollDirection
import '../models/recipe.dart';
import '../models/profile.dart';
import '../components/recipe_block.dart';
import '../components/profile_block.dart';
import '../components/persistent_bottom_nav_scaffold.dart';
import '../services/recipe_service.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../navigation/no_animation_page_route.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/create_recipe_screen.dart';
import '../services/data_cache_service.dart'; // Add this import

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with AutomaticKeepAliveClientMixin {
  final RecipeService _recipeService = RecipeService();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final DataCacheService _dataCache = DataCacheService(); // Add this line
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  List<Recipe> _recipeResults = [];
  List<Profile> _profileResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _currentUserId;
  
  // For recipe category filter
  final List<String> _popularCategories = [
    'Breakfast', 'Lunch', 'Dinner', 'Dessert', 
    'Vegetarian', 'Vegan', 'Gluten-Free', 'Keto',
    'Quick', 'Easy', 'Italian', 'Mexican', 'Asian'
  ];
  
  String? _selectedCategory;
  String _lastQuery = '';

  // Cache keys
  static const String _recentSearchQueryKey = 'recent_search_query';
  static const String _recentRecipeResultsKey = 'recent_recipe_results';
  static const String _recentProfileResultsKey = 'recent_profile_results';
  static const String _recentCategoryKey = 'recent_search_category';

  @override
  bool get wantKeepAlive => true; // Keep this screen alive when navigating away

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    
    // Add listener to scroll controller to dismiss keyboard when scrolling down
    _scrollController.addListener(_onScroll);
    
    // Try to restore previous search state from cache
    _restoreFromCache();
    
    // Auto-focus the search field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasSearched) { // Only focus if there's no active search
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  void _restoreFromCache() {
    // Restore recent search query
    final cachedQuery = _dataCache.get<String>(_recentSearchQueryKey);
    if (cachedQuery != null && cachedQuery.isNotEmpty) {
      _searchController.text = cachedQuery;
      _lastQuery = cachedQuery;
    }
    
    // Restore selected category
    final cachedCategory = _dataCache.get<String?>(_recentCategoryKey);
    if (cachedCategory != null) {
      setState(() {
        _selectedCategory = cachedCategory;
      });
    }
    
    // Restore results if they exist
    final cachedRecipes = _dataCache.get<List<Recipe>>(_recentRecipeResultsKey);
    final cachedProfiles = _dataCache.get<List<Profile>>(_recentProfileResultsKey);
    
    if ((cachedRecipes != null && cachedRecipes.isNotEmpty) || 
        (cachedProfiles != null && cachedProfiles.isNotEmpty)) {
      setState(() {
        _hasSearched = true;
        _recipeResults = cachedRecipes ?? [];
        _profileResults = cachedProfiles ?? [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.removeListener(_onScroll); // Remove listener
    _scrollController.dispose(); // Dispose scroll controller
    super.dispose();
  }
  
  // Dismiss keyboard when scrolling down
  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward && _focusNode.hasFocus) {
      // User is scrolling down (swiping up), hide keyboard
      _focusNode.unfocus();
    }
  }
  
  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }
  
  // Enhanced search functionality with broader matching
  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedCategory == null) return;
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _lastQuery = query; // Store the query for caching
    });
    
    try {
      // Search for recipes with enhanced functionality
      List<Recipe> recipeResults = [];
      
      if (_selectedCategory != null) {
        // First get all recipes in the selected category
        var categoryRecipes = await _recipeService.searchRecipesByCategoryTags(
          [_selectedCategory!],
          currentUserId: _currentUserId,
        );
        
        // If there's a search query, filter further
        if (query.isNotEmpty) {
          // Convert query to lowercase for case-insensitive search
          final lowercaseQuery = query.toLowerCase();
          
          // Keep recipes that contain the search term anywhere in the title or ingredients
          recipeResults = categoryRecipes.where((recipe) {
            final lowercaseTitle = recipe.title.toLowerCase();
            final containsInTitle = lowercaseTitle.contains(lowercaseQuery);
            
            // Also check ingredients
            final containsInIngredients = recipe.ingredients.any((ingredient) => 
              ingredient.toLowerCase().contains(lowercaseQuery));
            
            return containsInTitle || containsInIngredients;
          }).toList();
        } else {
          // If no search query, use all category results
          recipeResults = categoryRecipes;
        }
      } else if (query.isNotEmpty) {
        // If just searching without category, we need a broader approach
        
        // First get recipes that might start with the query (what Firestore typically returns)
        var initialRecipes = await _recipeService.searchRecipesByTitle(
          query,
          currentUserId: _currentUserId,
        );
        
        // To broaden search, get recent recipes and filter them
        var recentRecipes = await _recipeService.getRecentRecipes(50, currentUserId: _currentUserId);
        
        // Convert query to lowercase for case-insensitive search
        final lowercaseQuery = query.toLowerCase();
        
        // Filter recent recipes that contain the query anywhere
        var filteredRecipes = recentRecipes.where((recipe) {
          final lowercaseTitle = recipe.title.toLowerCase();
          final containsInTitle = lowercaseTitle.contains(lowercaseQuery);
          
          // Also check ingredients for broader matching
          final containsInIngredients = recipe.ingredients.any((ingredient) => 
            ingredient.toLowerCase().contains(lowercaseQuery));
          
          return containsInTitle || containsInIngredients;
        }).toList();
        
        // Combine results and remove duplicates
        recipeResults = [...initialRecipes];
        
        // Add filtered recipes that aren't already in the results
        for (var recipe in filteredRecipes) {
          if (!recipeResults.any((r) => r.id == recipe.id)) {
            recipeResults.add(recipe);
          }
        }
      }
      
      // Enhanced profile search (case-insensitive)
      List<Profile> profileResults = [];
      if (query.isNotEmpty) {
        // First get profiles that might start with the query
        var initialProfiles = await _profileService.searchProfilesByUsername(query);
        
        // Get all profiles for broader matching (if feasible)
        // Note: This can be resource intensive in a large application
        var allProfiles = await _profileService.getAllProfiles();
        
        // Filter profiles that contain the query anywhere in username
        final lowercaseQuery = query.toLowerCase();
        var filteredProfiles = allProfiles.where((profile) =>
          profile.username.toLowerCase().contains(lowercaseQuery)
        ).toList();
        
        // Combine results and remove duplicates
        profileResults = [...initialProfiles];
        
        // Add filtered profiles that aren't already in the results
        for (var profile in filteredProfiles) {
          if (!profileResults.any((p) => p.id == profile.id)) {
            profileResults.add(profile);
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _recipeResults = recipeResults;
          _profileResults = profileResults;
          _isLoading = false;
        });
        
        // Cache search results and query
        _dataCache.set(_recentSearchQueryKey, query);
        _dataCache.set(_recentRecipeResultsKey, recipeResults);
        _dataCache.set(_recentProfileResultsKey, profileResults);
        _dataCache.set(_recentCategoryKey, _selectedCategory);
      }
    } catch (e) {
      print('Search error: $e');
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error performing search: ${e.toString()}')),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _selectCategory(String? category) {
    setState(() {
      // If the same category is tapped again, deselect it
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
      
      // Cache the selected category
      _dataCache.set(_recentCategoryKey, _selectedCategory);
    });
    
    // Perform search with the updated category
    _performSearch();
  }
  
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _hasSearched = false;
      _recipeResults = [];
      _profileResults = [];
    });
    
    // Clear cache for search results
    _dataCache.remove(_recentSearchQueryKey);
    _dataCache.remove(_recentRecipeResultsKey);
    _dataCache.remove(_recentProfileResultsKey);
    _dataCache.remove(_recentCategoryKey);
    
    // Focus the search field
    FocusScope.of(context).requestFocus(_focusNode);
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
  
  void _navigateToCreateRecipe() {
    Navigator.push(
      context,
      NoAnimationPageRoute(
        builder: (context) => CreateRecipeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    
    return PersistentBottomNavScaffold(
      currentUserId: _currentUserId,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.white, // Prevent color change on scroll
        scrolledUnderElevation: 0, // Prevent elevation on scroll
        iconTheme: IconThemeData(color: Colors.black),
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
        leadingWidth: 56, // Default leadingWidth
        titleSpacing: 0, // Remove spacing between leading and title
        title: Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search recipes and profiles...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: _clearSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Color(0xFFD3D3D3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Color(0xFFFFFFC1), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
              onSubmitted: (_) => _performSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
        actions: [
          // Add a search button
          if (_searchController.text.isNotEmpty || _selectedCategory != null)
            IconButton(
              icon: Icon(Icons.search),
              onPressed: _performSearch,
            ),
        ],
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
      body: Column(
        children: [
          // Category Tags using existing component, but made toggleable
          Container(
            height: 50,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Use a Wrap widget to make the layout more flexible
                Wrap(
                  spacing: 8, // Gap between tags
                  children: _popularCategories.map((category) {
                    final isSelected = _selectedCategory == category;
                    
                    // Wrap the CategoryTags widget with a GestureDetector to make it toggleable
                    return GestureDetector(
                      onTap: () => _selectCategory(category),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Color(0xFFFFFFC1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Color(0xFFFFFFC1) : Color(0xFFD3D3D3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Open Sans',
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for recipes and profiles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'Open Sans',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Search by name or select a category',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'Open Sans',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (_recipeResults.isEmpty && _profileResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'Open Sans',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search term or category',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'Open Sans',
              ),
            ),
          ],
        ),
      );
    }
    
    // Combined results - first profiles, then recipes with scroll controller
    return ListView(
      controller: _scrollController, // Add the scroll controller here
      padding: EdgeInsets.all(16),
      children: [
        // Profiles section (if any)
        if (_profileResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 8),
            child: Text(
              'Profiles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Open Sans',
              ),
            ),
          ),
          ..._profileResults.map((profile) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ProfileBlock(profile: profile),
          )).toList(),
          SizedBox(height: 16),
        ],
        
        // Recipes section (if any)
        if (_recipeResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 8),
            child: Text(
              'Recipes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Open Sans',
              ),
            ),
          ),
          ..._recipeResults.map((recipe) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: RecipeBlock(recipe: recipe),
          )).toList(),
        ],
      ],
    );
  }
}