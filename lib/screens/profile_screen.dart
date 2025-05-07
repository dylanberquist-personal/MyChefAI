import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/profile.dart';
import '../models/recipe.dart';
import '../components/recipe_block.dart';
import '../services/profile_service.dart';
import '../components/header_text.dart';
import '../components/footer_nav_bar.dart';
import '../services/auth_service.dart';
import '../components/text_card.dart';
import '../services/storage_service.dart';
import '../components/persistent_bottom_nav_scaffold.dart';
import '../navigation/no_animation_page_route.dart';
import 'home_screen.dart';
import 'favorite_recipes_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<Recipe> _recipes = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followerCount = 0;
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  Profile? _profile;
  String? _currentUserId;
  File? _selectedImage;
  
  // Editable fields
  late TextEditingController _aboutController;
  late TextEditingController _locationController;
  late TextEditingController _dietaryController;
  bool _isEditingAbout = false;
  bool _isEditingLocation = false;
  bool _isEditingDietary = false;

  // Consistent spacing measurements
  final double _sectionSpacing = 24.0;
  final double _contentSpacing = 12.0;

  @override
  void initState() {
    super.initState();
    _aboutController = TextEditingController();
    _locationController = TextEditingController();
    _dietaryController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _aboutController.dispose();
    _locationController.dispose();
    _dietaryController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _fetchCurrentUser();
    await _fetchProfile();
    await _fetchRecipes();
    await _checkFollowStatus();
    await _fetchFollowerCount();
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _profileService.getProfileById(widget.userId);
      if (mounted && profile != null) {
        setState(() {
          _profile = profile;
          _aboutController.text = profile.description;
          _locationController.text = profile.region ?? '';
          _dietaryController.text = profile.dietaryRestrictions;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile not found')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _fetchRecipes() async {
    try {
      final recipes = await _profileService.getUserRecipes(widget.userId);
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkFollowStatus() async {
    if (_currentUserId == null || _currentUserId == widget.userId) return;
    
    try {
      _isFollowing = await _profileService.checkIfFollowing(widget.userId);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _fetchFollowerCount() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();
      
      if (mounted && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data.containsKey('followerCount') && data['followerCount'] != null) {
          var count = data['followerCount'];
          setState(() {
            if (count is int) {
              _followerCount = count;
            } else if (count is double) {
              _followerCount = count.toInt();
            } else if (count is String && int.tryParse(count) != null) {
              _followerCount = int.parse(count);
            } else {
              List<dynamic> followers = data['followers'] ?? [];
              _followerCount = followers.length;
            }
          });
        } else {
          setState(() {
            List<dynamic> followers = data['followers'] ?? [];
            _followerCount = followers.length;
          });
        }
        
        print('Fetched follower count: $_followerCount for user ${widget.userId}');
      }
    } catch (e) {
      print('Error fetching follower count: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null) return;
    
    setState(() {
      _isFollowing = !_isFollowing;
      _followerCount += _isFollowing ? 1 : -1;
    });
    
    try {
      if (_isFollowing) {
        await _profileService.followUser(_currentUserId!, widget.userId);
      } else {
        await _profileService.unfollowUser(_currentUserId!, widget.userId);
      }
      await _fetchFollowerCount();
    } catch (e) {
      setState(() {
        _isFollowing = !_isFollowing;
        _followerCount += _isFollowing ? 1 : -1;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to change your profile picture')),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null || _profile == null || _currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Uploading profile picture...'),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );

      final imageUrl = await _storageService.uploadProfileImage(
        _currentUserId!,
        _selectedImage!,
      );

      final updatedProfile = Profile(
        id: _profile!.id,
        uid: _profile!.uid,
        username: _profile!.username,
        profilePicture: imageUrl,
        email: _profile!.email,
        description: _aboutController.text,
        topRecipeId: _profile!.topRecipeId,
        region: _locationController.text.isNotEmpty ? _locationController.text : null,
        chefScore: _profile!.chefScore,
        numberOfReviews: _profile!.numberOfReviews,
        dietaryRestrictions: _dietaryController.text,
        myRecipes: _profile!.myRecipes,
        myFavorites: _profile!.myFavorites,
        isFollowing: _profile!.isFollowing,
        followers: _profile!.followers,
        following: _profile!.following,
        followerCount: _profile!.followerCount,
      );

      await _profileService.updateProfile(updatedProfile);
      
      await _fetchProfile();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } on firebase_storage.FirebaseException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_profile == null || _currentUserId == null) return;

    try {
      final updatedProfile = Profile(
        id: _profile!.id,
        uid: _profile!.uid,
        username: _profile!.username,
        profilePicture: _profile!.profilePicture,
        email: _profile!.email,
        description: _aboutController.text,
        topRecipeId: _profile!.topRecipeId,
        region: _locationController.text.isNotEmpty ? _locationController.text : null,
        chefScore: _profile!.chefScore,
        numberOfReviews: _profile!.numberOfReviews,
        dietaryRestrictions: _dietaryController.text,
        myRecipes: _profile!.myRecipes,
        myFavorites: _profile!.myFavorites,
        isFollowing: _profile!.isFollowing,
        followers: _profile!.followers,
        following: _profile!.following,
        followerCount: _profile!.followerCount,
      );

      await _profileService.updateProfile(updatedProfile);
      await _fetchProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          NoAnimationPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  void _navigateToFavorites() {
    if (_currentUserId != null) {
      Navigator.push(
        context,
        NoAnimationPageRoute(
          builder: (context) => FavoriteRecipesScreen(userId: _currentUserId!),
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

  Widget _buildEditableSection({
    required String title,
    required TextEditingController controller,
    required bool isEditing,
    required Function(bool) onEditToggle,
    bool isMultiline = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HeaderText(text: title),
            if (_currentUserId == widget.userId)
              IconButton(
                icon: Icon(isEditing ? Icons.check : Icons.edit),
                onPressed: () async {
                  if (isEditing) {
                    await _saveProfileChanges();
                  }
                  onEditToggle(!isEditing);
                },
              ),
          ],
        ),
        SizedBox(height: _contentSpacing),
        TextCard(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: isEditing
                ? TextField(
                    controller: controller,
                    maxLines: isMultiline ? null : 1,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter your $title',
                    ),
                  )
                : Text(
                    controller.text.isNotEmpty
                        ? controller.text
                        : 'No $title specified',
                    style: TextStyle(
                      fontSize: 16,
                      color: controller.text.isNotEmpty 
                          ? Colors.black 
                          : Colors.grey[600],
                    ),
                  ),
          ),
        ),
        SizedBox(height: _sectionSpacing),
      ],
    );
  }

  Widget _buildChefScoreStars(double score) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < score ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 24,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isOwnProfile = _currentUserId == widget.userId;

    return PersistentBottomNavScaffold(
      currentUserId: _currentUserId,
      currentProfileUserId: widget.userId,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      onNavItemTap: (index) {
        if (index == 0) {
          _navigateToHome();
        } else if (index == 4 && _currentUserId != null && _currentUserId != widget.userId) {
          Navigator.pushReplacement(
            context,
            NoAnimationPageRoute(
              builder: (context) => ProfileScreen(userId: _currentUserId!),
            ),
          );
        }
      },
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            // Profile Header with editable image
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : _profile!.profilePicture != null 
                          ? NetworkImage(_profile!.profilePicture!)
                          : AssetImage('assets/images/profile_image_placeholder.png') as ImageProvider,
                ),
                if (isOwnProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              _profile!.username,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '$_followerCount Followers',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            if (!isOwnProfile && _currentUserId != null && _currentUserId != widget.userId)
              ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey[300] : Color(0xFFFFFFC1),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFollowing ? Icons.check : Icons.add,
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 32),

            // Profile Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Section
                  _buildEditableSection(
                    title: 'About',
                    controller: _aboutController,
                    isEditing: _isEditingAbout,
                    onEditToggle: (value) {
                      setState(() {
                        _isEditingAbout = value;
                      });
                    },
                  ),

                  // Location Section
                  _buildEditableSection(
                    title: 'Location',
                    controller: _locationController,
                    isEditing: _isEditingLocation,
                    onEditToggle: (value) {
                      setState(() {
                        _isEditingLocation = value;
                      });
                    },
                    isMultiline: false,
                  ),

                  // Dietary Restrictions Section
                  _buildEditableSection(
                    title: 'Dietary Restrictions',
                    controller: _dietaryController,
                    isEditing: _isEditingDietary,
                    onEditToggle: (value) {
                      setState(() {
                        _isEditingDietary = value;
                      });
                    },
                  ),

                  // Chef Rating Section (non-editable)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderText(text: 'Chef Rating'),
                      SizedBox(height: _contentSpacing),
                      TextCard(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              _buildChefScoreStars(_profile!.chefScore),
                              SizedBox(width: 8),
                              Text(
                                '${_profile!.chefScore.toStringAsFixed(1)}/5.0',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: _sectionSpacing),
                    ],
                  ),
                  
                  // Add Favorites Button (only visible on your own profile)
                  if (isOwnProfile) 
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeaderText(text: 'My Favorites'),
                        SizedBox(height: _contentSpacing),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _navigateToFavorites,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(color: Colors.black),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'See my favorites',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Open Sans',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: _sectionSpacing),
                      ],
                    ),
                ],
              ),
            ),

            // Recipes Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        HeaderText(text: 'Recipes'),
                        Positioned(
                          right: 0,
                          child: Text(
                            '${_recipes.length} ${_recipes.length == 1 ? 'recipe' : 'recipes'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: _contentSpacing),
                  if (_recipes.isEmpty)
                    Center(
                      child: Text(
                        'No recipes yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _recipes.map((r) => Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: RecipeBlock(recipe: r),
                      )).toList(),
                    ),
                  SizedBox(height: _sectionSpacing),
                ],
              ),
            ),
            
            // Sign Out Button (only visible on your own profile)
            if (isOwnProfile)
              Column(
                children: [
                  SizedBox(height: _contentSpacing),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: Colors.red),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Open Sans',
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: _sectionSpacing),
                ],
              ),
          ],
        ),
      ),
    );
  }
}