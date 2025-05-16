// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/profile.dart';
import '../models/recipe.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../navigation/no_animation_page_route.dart';
import '../components/persistent_bottom_nav_scaffold.dart';
import '../components/editable_section.dart';
import '../components/profile_header.dart';
import '../components/chef_score_section.dart';
import '../components/profile_action_buttons.dart';
import '../components/profile_recipes_section.dart';
import 'home_screen.dart';
import 'favorite_recipes_screen.dart';
import 'login_screen.dart';
import 'create_recipe_screen.dart';
import '../services/data_cache_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  late List<Recipe> _recipes = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followerCount = 0;
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  final DataCacheService _dataCache = DataCacheService();
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
  
  // Cache keys
  String get _profileKey => 'profile_${widget.userId}';
  String get _recipesKey => 'profile_recipes_${widget.userId}';
  String get _followingStatusKey => 'following_status_${widget.userId}';
  String get _followerCountKey => 'follower_count_${widget.userId}';

  @override
  bool get wantKeepAlive => true; // Keep this screen alive when navigating away

  @override
  void initState() {
    super.initState();
    _aboutController = TextEditingController();
    _locationController = TextEditingController();
    _dietaryController = TextEditingController();
    
    // Restore from cache first
    _restoreFromCache();
    
    // Then load fresh data
    _loadData();
  }
  
  void _restoreFromCache() {
    // Restore profile
    final cachedProfile = _dataCache.get<Map<String, dynamic>>(_profileKey);
    if (cachedProfile != null) {
      try {
        final profile = Profile(
          id: cachedProfile['id'] ?? '',
          uid: cachedProfile['uid'] ?? '',
          username: cachedProfile['username'] ?? 'Unknown User',
          profilePicture: cachedProfile['profilePicture'],
          email: cachedProfile['email'] ?? '',
          description: cachedProfile['description'] ?? '',
          topRecipeId: cachedProfile['topRecipeId'],
          region: cachedProfile['region'],
          chefScore: (cachedProfile['chefScore'] is num) ? (cachedProfile['chefScore'] as num).toDouble() : 0.0,
          numberOfReviews: cachedProfile['numberOfReviews'],
          dietaryRestrictions: cachedProfile['dietaryRestrictions'] ?? '',
          myRecipes: List<String>.from(cachedProfile['myRecipes'] ?? []),
          myFavorites: List<String>.from(cachedProfile['myFavorites'] ?? []),
          isFollowing: cachedProfile['isFollowing'] ?? false,
          followers: cachedProfile['followers'] ?? 0,
          following: List<String>.from(cachedProfile['following'] ?? []),
          followerCount: cachedProfile['followerCount'] ?? 0,
        );
        
        setState(() {
          _profile = profile;
          _aboutController.text = profile.description;
          _locationController.text = profile.region ?? '';
          _dietaryController.text = profile.dietaryRestrictions;
          _isLoading = false;
        });
      } catch (e) {
        print('Error restoring profile from cache: $e');
      }
    }
    
    // Restore recipes
    final cachedRecipes = _dataCache.get<List<dynamic>>(_recipesKey);
    if (cachedRecipes != null) {
      try {
        // Recipe restoration code hidden for brevity - same as original file
        // This would be restored in the _restoreFromCache method implementation
      } catch (e) {
        print('Error restoring recipes from cache: $e');
      }
    }
    
    // Restore following status
    final cachedFollowingStatus = _dataCache.get<bool>(_followingStatusKey);
    if (cachedFollowingStatus != null) {
      setState(() {
        _isFollowing = cachedFollowingStatus;
      });
    }
    
    // Restore follower count
    final cachedFollowerCount = _dataCache.get<int>(_followerCountKey);
    if (cachedFollowerCount != null) {
      setState(() {
        _followerCount = cachedFollowerCount;
      });
    }
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
        
        // Cache the profile data
        _cacheProfileData(profile);
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

  void _cacheProfileData(Profile profile) {
    final profileMap = {
      'id': profile.id,
      'uid': profile.uid,
      'username': profile.username,
      'profilePicture': profile.profilePicture,
      'email': profile.email,
      'description': profile.description,
      'topRecipeId': profile.topRecipeId,
      'region': profile.region,
      'chefScore': profile.chefScore,
      'numberOfReviews': profile.numberOfReviews,
      'dietaryRestrictions': profile.dietaryRestrictions,
      'myRecipes': profile.myRecipes,
      'myFavorites': profile.myFavorites,
      'isFollowing': profile.isFollowing,
      'followers': profile.followers,
      'following': profile.following,
      'followerCount': profile.followerCount,
    };
    
    // Cache with 10-minute expiry for profile data
    _dataCache.setWithExpiry(_profileKey, profileMap, Duration(minutes: 10));
  }

  Future<void> _fetchRecipes() async {
    try {
      final recipes = await _profileService.getUserRecipes(widget.userId, currentUserId: _currentUserId);
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
        
        // Cache the recipes - detailed implementation omitted for brevity
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
        
        // Cache the following status with 5-minute expiry
        _dataCache.setWithExpiry(_followingStatusKey, _isFollowing, Duration(minutes: 5));
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _fetchFollowerCount() async {
    try {
      // Implementation omitted for brevity - same as original file
      // This would fetch the follower count from Firestore
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
    
    // Update cache immediately for better UX
    _dataCache.set(_followingStatusKey, _isFollowing);
    _dataCache.set(_followerCountKey, _followerCount);
    
    try {
      if (_isFollowing) {
        await _profileService.followUser(_currentUserId!, widget.userId);
      } else {
        await _profileService.unfollowUser(_currentUserId!, widget.userId);
      }
      await _fetchFollowerCount(); // Refresh actual count from server
    } catch (e) {
      // Handle errors - same as original file
      setState(() {
        _isFollowing = !_isFollowing;
        _followerCount += _isFollowing ? 1 : -1;
      });
      
      // Update cache again if operation failed
      _dataCache.set(_followingStatusKey, _isFollowing);
      _dataCache.set(_followerCountKey, _followerCount);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    // Implementation omitted for brevity - same as original file
    // This would handle image picking with image_picker
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
    // Implementation omitted for brevity - same as original file
    // This would handle image upload to Firebase Storage
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
      
      // Update cache with new profile data
      _cacheProfileData(updatedProfile);
      
      await _fetchProfile();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      
      // Clear all user-specific cache on sign out
      _dataCache.remove(_profileKey);
      _dataCache.remove(_recipesKey);
      _dataCache.remove(_followingStatusKey);
      _dataCache.remove(_followerCountKey);
      
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
      ).then((_) {
        // Refresh profile data when returning
        _fetchProfile();
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
      // Refresh recipes when returning
      _fetchRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    
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
        } else if (index == 2) {
          _navigateToCreateRecipe();
        } else if (index == 4 && _currentUserId != null && _currentUserId != widget.userId) {
          Navigator.pushReplacement(
            context,
            NoAnimationPageRoute(
              builder: (context) => ProfileScreen(userId: _currentUserId!),
            ),
          );
        }
      },
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 16),
              
              // Profile Header (image, username, follow button)
              ProfileHeader(
                profile: _profile!,
                followerCount: _followerCount,
                isOwnProfile: isOwnProfile,
                isFollowing: _isFollowing,
                currentUserId: _currentUserId,
                selectedImage: _selectedImage,
                onPickImage: _pickImage,
                onToggleFollow: _toggleFollow,
              ),

              // Profile Details
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // About Section - using EditableSection component
                    if (isOwnProfile)
                      EditableSection(
                        title: 'About',
                        controller: _aboutController,
                        isEditing: _isEditingAbout,
                        onEditToggle: (value) {
                          setState(() {
                            _isEditingAbout = value;
                          });
                        },
                        onSave: _saveProfileChanges,
                        contentSpacing: _contentSpacing,
                        sectionSpacing: _sectionSpacing,
                      )
                    else
                      EditableSection(
                        title: 'About',
                        controller: _aboutController,
                        isEditing: false,
                        onEditToggle: (_) {},
                        onSave: () async {},
                        contentSpacing: _contentSpacing,
                        sectionSpacing: _sectionSpacing,
                      ),

                    // Location Section - using EditableSection component
                    if (isOwnProfile)
                      EditableSection(
                        title: 'Location',
                        controller: _locationController,
                        isEditing: _isEditingLocation,
                        onEditToggle: (value) {
                          setState(() {
                            _isEditingLocation = value;
                          });
                        },
                        onSave: _saveProfileChanges,
                        isMultiline: false,
                        contentSpacing: _contentSpacing,
                        sectionSpacing: _sectionSpacing,
                      )
                    else
                      EditableSection(
                        title: 'Location',
                        controller: _locationController,
                        isEditing: false,
                        onEditToggle: (_) {},
                        onSave: () async {},
                        isMultiline: false,
                        contentSpacing: _contentSpacing,
                        sectionSpacing: _sectionSpacing,
                      ),

                    // Dietary Restrictions Section - using EditableSection component
                    if (isOwnProfile)
                      EditableSection(
                        title: 'Dietary Restrictions',
                        controller: _dietaryController,
                        isEditing: _isEditingDietary,
                        onEditToggle: (value) {
                          setState(() {
                            _isEditingDietary = value;
                          });
                        },
                        onSave: _saveProfileChanges,
                        contentSpacing: _contentSpacing,
                        sectionSpacing: _sectionSpacing,
                      )
                    else
                      EditableSection(
                        title: 'Dietary Restrictions',
                        controller: _dietaryController,
                        isEditing: false,
                        onEditToggle: (_) {},
                        onSave: () async {},
                        contentSpacing: _contentSpacing,
                        sectionSpacing: _sectionSpacing,
                      ),

                    // Chef Rating Section - using ChefScoreSection component
                    ChefScoreSection(
                      chefScore: _profile!.chefScore,
                      contentSpacing: _contentSpacing,
                      sectionSpacing: _sectionSpacing,
                    ),
                    
                    // Only show "See my favorites" button here (not Sign Out)
                    if (isOwnProfile)
                      ProfileActionButtons(
                        isOwnProfile: isOwnProfile,
                        onViewFavorites: _navigateToFavorites,
                        onSignOut: null, // Don't include sign out button here
                        contentSpacing: _contentSpacing,
                        sectionSpacing: _sectionSpacing,
                      ),
                  ],
                ),
              ),

              // Recipes Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: ProfileRecipesSection(
                  recipes: _recipes,
                  contentSpacing: _contentSpacing,
                  sectionSpacing: _sectionSpacing,
                ),
              ),
              
              // Sign Out Button at the bottom (only for own profile)
              if (isOwnProfile)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: ProfileActionButtons(
                    isOwnProfile: true,
                    onViewFavorites: null, // Don't repeat favorites button
                    onSignOut: _signOut, // Only include sign out button here
                    contentSpacing: _contentSpacing,
                    sectionSpacing: _sectionSpacing,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}