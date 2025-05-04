import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mychefai/models/profile.dart';
import 'package:mychefai/services/profile_service.dart';
import 'package:mychefai/services/auth_service.dart';
import 'package:mychefai/services/storage_service.dart';
import 'package:mychefai/screens/home_screen.dart';
import 'package:mychefai/screens/login_screen.dart';
import 'package:mychefai/components/header_text.dart';

class OnboardingScreen extends StatefulWidget {
  final String uid; // Firebase UID of the user

  const OnboardingScreen({Key? key, required this.uid}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _regionController = TextEditingController();
  final _dietaryRestrictionsController = TextEditingController();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  Future<bool> _showCancelDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cancel Profile Setup?',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF030303),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to cancel? You\'ll need to complete your profile to use the app.',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF030303),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: Color(0xFFD3D3D3)),
                          ),
                        ),
                        child: Text(
                          'Stay',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF030303),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFFFC1),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Cancel Setup',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }

  Future<void> _handleCancelSetup() async {
    bool shouldCancel = await _showCancelDialog();
    
    if (shouldCancel) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        // Get current user
        final user = await _authService.getCurrentUser();
        
        // Delete the user account
        if (user != null) {
          await user.delete();
        }
        
        // Navigate back to login screen
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        // If deletion fails, just sign out
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleCancelSetup();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button row
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 1.2,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: _handleCancelSetup,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Welcome text
                      Text(
                        'Welcome to MyChefAI!',
                        style: TextStyle(
                          color: Color(0xFF030303),
                          fontSize: 32,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Subtitle
                      Text(
                        'Let\'s get your profile set up so you can start cooking',
                        style: TextStyle(
                          color: Color(0xFF030303),
                          fontSize: 16,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      
                      // Profile Picture Section
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _selectedImage != null 
                                ? FileImage(_selectedImage!)
                                : AssetImage('assets/images/profile_image_placeholder.png') as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFFFC1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
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
                      SizedBox(height: 12),
                      Text(
                        'Add a profile picture',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                      SizedBox(height: 32),
                      
                      // Form Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Color(0xFFD3D3D3),
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
                        padding: EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create Your Profile',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'Open Sans',
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF030303),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24),
                              
                              // Username Field
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'Choose a unique username',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.grey[600],
                                  ),
                                  hintStyle: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.grey[400],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Color(0xFFD3D3D3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Color(0xFFFFFFC1), width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  if (value.length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              
                              // Bio/Description Field
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'About You',
                                  hintText: 'Tell us a bit about yourself',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.grey[600],
                                  ),
                                  hintStyle: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.grey[400],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Color(0xFFD3D3D3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Color(0xFFFFFFC1), width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.info_outline, color: Colors.grey[600]),
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // Location Field
                              TextFormField(
                                controller: _regionController,
                                decoration: InputDecoration(
                                  labelText: 'Location',
                                  hintText: 'Where are you from?',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.grey[600],
                                  ),
                                  hintStyle: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.grey[400],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Color(0xFFD3D3D3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Color(0xFFFFFFC1), width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.location_on, color: Colors.grey[600]),
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // Dietary Restrictions Field
                              TextFormField(
                                controller: _dietaryRestrictionsController,
                                decoration: InputDecoration(
                                  labelText: 'Dietary Restrictions',
                                  hintText: 'Any dietary restrictions or preferences?',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.grey[600],
                                  ),
                                  hintStyle: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.grey[400],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Color(0xFFD3D3D3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Color(0xFFFFFFC1), width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.restaurant_menu, color: Colors.grey[600]),
                                ),
                              ),
                              SizedBox(height: 32),
                              
                              // Save Profile Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _submitProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFFFFC1),
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      )
                                    : Text(
                                        'Start Cooking!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Open Sans',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the current user's email
        final user = await _authService.getCurrentUser();
        String userEmail = user?.email ?? '';
        String? profileImageUrl;

        // Upload profile image if selected
        if (_selectedImage != null) {
          profileImageUrl = await _storageService.uploadProfileImage(
            widget.uid,
            _selectedImage!,
          );
        }

        // Create a new profile
        final newProfile = Profile(
          id: widget.uid,
          uid: widget.uid,
          username: _usernameController.text.trim(),
          email: userEmail,
          profilePicture: profileImageUrl,
          description: _descriptionController.text.trim(),
          region: _regionController.text.trim(),
          chefScore: 0.0,
          numberOfReviews: 0,
          dietaryRestrictions: _dietaryRestrictionsController.text.trim(),
          myRecipes: [],
          myFavorites: [],
          isFollowing: false,
          followers: 0,
        );

        // Save the new profile to Firestore
        final profileService = ProfileService();
        await profileService.saveProfile(newProfile);

        // Navigate to the HomeScreen
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating profile: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _descriptionController.dispose();
    _regionController.dispose();
    _dietaryRestrictionsController.dispose();
    super.dispose();
  }
}