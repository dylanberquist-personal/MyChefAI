import 'package:flutter/material.dart';
import '../components/footer_nav_bar.dart';
import '../components/recipe_block.dart';
import '../components/profile_block.dart';
import '../components/title_bar.dart';
import '../components/cook_now_block.dart';
import '../components/header_text.dart';
import '../components/persistent_bottom_nav_scaffold.dart';
import '../services/recipe_service.dart';
import '../services/profile_service.dart';
import '../models/recipe.dart';
import '../models/profile.dart';
import '../screens/profile_screen.dart';
import '../screens/create_recipe_screen.dart'; // Add this import
import '../services/auth_service.dart';
import '../navigation/no_animation_page_route.dart';
import '../screens/recipe_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecipeService _recipeService = RecipeService();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  Profile? _currentUserProfile;

  // Cached data for faster rebuilds
  Recipe? _featuredRecipe;
  List<Recipe> _recentRecipes = [];
  List<Profile> _topChefs = [];
  bool _isLoadingFeatured = true;
  bool _isLoadingRecent = true;
  bool _isLoadingChefs = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchCurrentUser();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // No logic needed here for now
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });

      final profile = await _profileService.getProfileById(user.uid);
      if (profile != null) {
        setState(() {
          _currentUserProfile = profile;
        });
      }
    }
  }
  
  // Load all data at once to avoid multiple rebuilds
  Future<void> _loadData() async {
    _loadFeaturedRecipe();
    _loadRecentRecipes();
    _loadTopChefs();
  }
  
  Future<void> _loadFeaturedRecipe() async {
    try {
      final recipe = await _recipeService.getRandomRecipe();
      if (mounted) {
        setState(() {
          _featuredRecipe = recipe;
          _isLoadingFeatured = false;
        });
      }
    } catch (e) {
      print('Error loading featured recipe: $e');
      if (mounted) {
        setState(() {
          _isLoadingFeatured = false;
        });
      }
    }
  }
  
  Future<void> _loadRecentRecipes() async {
    try {
      final recipes = await _recipeService.getRecentRecipes(3);
      if (mounted) {
        setState(() {
          _recentRecipes = recipes;
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      print('Error loading recent recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecent = false;
        });
      }
    }
  }
  
  Future<void> _loadTopChefs() async {
    try {
      final profiles = await _profileService.getAllProfiles();
      if (mounted) {
        // Sort profiles by chef score * number of reviews
        profiles.sort((a, b) {
          double aScore = a.chefScore * (a.numberOfReviews ?? 1);
          double bScore = b.chefScore * (b.numberOfReviews ?? 1);
          return bScore.compareTo(aScore); // Descending order
        });
        
        setState(() {
          _topChefs = profiles.take(5).toList();
          _isLoadingChefs = false;
        });
      }
    } catch (e) {
      print('Error loading top chefs: $e');
      if (mounted) {
        setState(() {
          _isLoadingChefs = false;
        });
      }
    }
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
  
  // Add this method to navigate to the CreateRecipeScreen
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
    // Define spacing constants here directly in the build method
    const double sectionSpacing = 32.0; // Space between sections
    const double headerToContentSpacing = 20.0; // Consistent 20px spacing between all headers and content
    const double feedItemSpacing = 8.0; // Spacing between recipe blocks in feed
    const double chefProfileSpacing = 8.0; // Spacing between profile blocks
    const double contentSpacing = 16.0; // Regular content spacing (for loading indicators, etc.)
    
    return PersistentBottomNavScaffold(
      currentUserId: _currentUserId,
      backgroundColor: Colors.white,
      onNavItemTap: (index) {
        if (index == 0) {
          // Already on home screen, do nothing
        } else if (index == 2) {
          // Create Recipe button pressed
          _navigateToCreateRecipe();
        } else if (index == 4 && _currentUserId != null) {
          _navigateToProfile();
        }
      },
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          TitleBar(
            onProfileTap: _navigateToProfile,
          ),
          // Divider
          SliverToBoxAdapter(
            child: const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFD3D3D3),
              indent: 24,
              endIndent: 24,
            ),
          ),
          
          // Cook Now Block
          SliverToBoxAdapter(
            child: CookNowBlock(
              onCookNowPressed: _navigateToCreateRecipe, // Use the navigation method
            ),
          ),
          
          // Featured Recipe Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: sectionSpacing, left: 24, right: 24),
              child: HeaderText(text: 'Featured recipe'),
            ),
          ),
          
          // Featured Recipe Block - Exact 20px from header
          SliverToBoxAdapter(
            child: _isLoadingFeatured
              ? Padding(
                  padding: EdgeInsets.only(top: headerToContentSpacing, left: 24, right: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _featuredRecipe == null
                ? Padding(
                    padding: EdgeInsets.only(top: headerToContentSpacing, left: 24, right: 24),
                    child: Center(child: Text('No featured recipe found.')),
                  )
                : Padding(
                    padding: EdgeInsets.only(top: headerToContentSpacing, left: 24, right: 24),
                    child: RecipeBlock(
                      key: ValueKey('featured_${_featuredRecipe!.id}'),
                      recipe: _featuredRecipe!
                    ),
                  ),
          ),
          
          // Recipe Feed Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: sectionSpacing, left: 24, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HeaderText(text: 'Recipe feed'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        NoAnimationPageRoute(
                          builder: (context) => RecipeFeedScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF030303),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(85, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'See more',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        height: 1.29,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Recipe Feed Preview - Exact 20px from header and 8px between items
          _isLoadingRecent
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: headerToContentSpacing, left: 24, right: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : _recentRecipes.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: headerToContentSpacing, left: 24, right: 24),
                    child: Center(child: Text('No recipes found.')),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? headerToContentSpacing : feedItemSpacing, 
                          left: 24, 
                          right: 24
                        ),
                        child: RecipeBlock(
                          key: ValueKey('recipe_${_recentRecipes[index].id}'),
                          recipe: _recentRecipes[index],
                        ),
                      );
                    },
                    childCount: _recentRecipes.length,
                  ),
                ),
          
          // Top Chefs Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: sectionSpacing, left: 24, right: 24),
              child: HeaderText(text: 'Top chefs leaderboard'),
            ),
          ),
          
          // Top Chefs Leaderboard - Exact 20px from header and reduced spacing between items
          _isLoadingChefs
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: headerToContentSpacing, left: 24, right: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : _topChefs.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: headerToContentSpacing, left: 24, right: 24),
                    child: Center(child: Text('No top chefs found.')),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? headerToContentSpacing : chefProfileSpacing, 
                          left: 24, 
                          right: 24
                        ),
                        child: Stack(
                          children: [
                            ProfileBlock(
                              key: ValueKey('chef_${_topChefs[index].id}'),
                              profile: _topChefs[index],
                            ),
                            // Rank Banner
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _topChefs.length,
                  ),
                ),
          
          // Bottom Padding
          SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}