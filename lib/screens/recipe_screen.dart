import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/profile.dart';
import '../components/profile_block.dart';
import '../components/recipe_title_bar.dart';
import '../components/category_tags.dart';
import '../components/rating_block.dart';
import '../components/footer_nav_bar.dart';
import '../components/header_text.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../screens/profile_screen.dart';

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
  String? _currentUserId;
  Profile? _creatorProfile;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchCreatorProfile();
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  Future<void> _fetchCreatorProfile() async {
    if (widget.recipe.creator.uid == null || widget.recipe.creator.uid!.isEmpty) {
      print('Creator UID is null or empty');
      return;
    }

    try {
      final profile = await _profileService.getProfileById(widget.recipe.creator.uid!);
      if (profile != null) {
        print('Fetched profile: ${profile.username}');
        setState(() {
          _creatorProfile = profile;
        });
      } else {
        print('Profile not found for user UID: ${widget.recipe.creator.uid}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: RecipeTitleBar(
        title: widget.recipe.title,
        isFavorited: isFavorited,
        onBackPressed: () => Navigator.pop(context),
        onFavoritePressed: () => setState(() => isFavorited = !isFavorited),
        onOptionsPressed: () {},
      ),
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
                  widget.recipe.image ?? 'assets/images/recipe_image_placeholder.png',
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
            const SizedBox(height: 24),

            // Ingredients Section
            HeaderText(text: 'Ingredients'),
            const SizedBox(height: 8),
            ...widget.recipe.ingredients.map((ingredient) => Padding(
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
            ...widget.recipe.instructions.asMap().entries.map((entry) {
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
            if (widget.recipe.categoryTags.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderText(text: 'Categories'),
                  const SizedBox(height: 8),
                  CategoryTags(tags: widget.recipe.categoryTags),
                ],
              ),
            const SizedBox(height: 24),

            // Creator Profile Block
            HeaderText(text: 'Created By'),
            const SizedBox(height: 8),
            if (widget.recipe.creator.uid == null || widget.recipe.creator.uid!.isEmpty)
              const Center(child: Text('Creator information is missing')),
            if (widget.recipe.creator.uid != null && widget.recipe.creator.uid!.isNotEmpty)
              if (_creatorProfile != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.zero,
                  child: ProfileBlock(profile: _creatorProfile!),
                ),
            if (_creatorProfile == null && widget.recipe.creator.uid != null && widget.recipe.creator.uid!.isNotEmpty)
              const Center(child: Text('Creator profile not found')),
            const SizedBox(height: 24),

            // Rating Block
            RatingBlock(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: FooterNavBar(
        currentUserId: _currentUserId,
        onTap: (index) {
          if (index == 4 && _currentUserId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: _currentUserId!),
              ),
            );
          } else if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
      ),
    );
  }
}