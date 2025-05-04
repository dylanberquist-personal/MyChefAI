import 'package:flutter/material.dart';
import '../components/footer_nav_bar.dart'; // Import the footer nav bar
import '../components/recipe_block.dart'; // Import the RecipeBlock component
import '../components/profile_block.dart'; // Import the ProfileBlock component
import '../components/title_bar.dart'; // Import the TitleBar component
import '../components/cook_now_block.dart'; // Import the new CookNowBlock component
import '../components/header_text.dart'; // Import the HeaderText component
import '../services/recipe_service.dart'; // Import RecipeService
import '../services/profile_service.dart'; // Import ProfileService
import '../models/recipe.dart'; // Import the Recipe model
import '../models/profile.dart'; // Import the Profile model
import '../screens/profile_screen.dart'; // Import the ProfileScreen
import '../services/auth_service.dart'; // Import AuthService

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecipeService _recipeService = RecipeService(); // Initialize RecipeService
  final ProfileService _profileService = ProfileService(); // Initialize ProfileService
  final AuthService _authService = AuthService(); // Initialize AuthService
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId; // Store the current user's ID
  Profile? _currentUserProfile; // Store the current user's profile

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll); // Add scroll listener
    _fetchCurrentUser(); // Fetch the current user's ID and profile
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll); // Remove scroll listener
    _scrollController.dispose(); // Dispose the controller
    super.dispose();
  }

  // Handle scroll events
  void _onScroll() {
    // No logic needed here for now
  }

  // Fetch the current user's ID and profile
  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });

      // Fetch the current user's profile
      final profile = await _profileService.getProfileById(user.uid);
      if (profile != null) {
        setState(() {
          _currentUserProfile = profile;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Use the TitleBar component
          TitleBar(
            onProfileTap: () {
              if (_currentUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      userId: _currentUserId!, // Pass the user ID
                    ),
                  ),
                );
              }
            },
          ),
          // Rest of the content
          SliverList(
            delegate: SliverChildListDelegate([
              // Horizontal Divider
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFD3D3D3),
                indent: 24,
                endIndent: 24,
              ),
              // Use the CookNowBlock component
              CookNowBlock(
                onCookNowPressed: () {}, // Provide a valid function
              ),
              // Featured Recipe Header
              const Padding(
                padding: EdgeInsets.only(top: 32, left: 24, right: 24),
                child: HeaderText(text: 'Featured recipe'), // Use the HeaderText component
              ),
              // Featured Recipe Block
              FutureBuilder<Recipe?>(
                future: _recipeService.getRandomRecipe(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('No featured recipe found.'));
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
                    child: RecipeBlock(recipe: snapshot.data!),
                  );
                },
              ),
              // Recipe Feed Header and See More Button
              Padding(
                padding: const EdgeInsets.only(top: 32, left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const HeaderText(text: 'Recipe feed'), // Use the HeaderText component
                    ElevatedButton(
                      onPressed: () {
                        // Add button functionality
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
              // Top Chefs Leaderboard Header
              const Padding(
                padding: EdgeInsets.only(top: 32, left: 24, right: 24),
                child: HeaderText(text: 'Top chefs leaderboard'), // Use the HeaderText component
              ),
              // Top Chefs List
              FutureBuilder<List<Profile>>(
                future: _profileService.getAllProfiles(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No top chefs found.'));
                  }
                  // Sort profiles by (chefScore * numberOfReviews) in descending order
                  final sortedProfiles = snapshot.data!
                    ..sort((a, b) {
                      double aScore = a.chefScore * (a.numberOfReviews ?? 1);
                      double bScore = b.chefScore * (b.numberOfReviews ?? 1);
                      return bScore.compareTo(aScore); // Descending order
                    });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedProfiles.take(5).length,
                    itemBuilder: (context, index) {
                      final profile = sortedProfiles[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 6),
                        child: Stack(
                          children: [
                            ProfileBlock(profile: profile),
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
                  );
                },
              ),
              const SizedBox(height: 24), // Add 24px padding at the bottom
            ]),
          ),
        ],
      ),
      bottomNavigationBar: FooterNavBar(
        currentUserId: _currentUserId, // Pass the current user's ID
        onTap: (index) {
          if (index == 4 && _currentUserId != null) {
            // Navigate to the ProfileScreen for the current user
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  userId: _currentUserId!, // Pass the user ID
                ),
              ),
            );
          }
        },
      ),
    );
  }
}