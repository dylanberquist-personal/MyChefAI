import 'package:flutter/material.dart';
import 'package:mychefai/models/profile.dart'; // Import the Profile model
import 'package:mychefai/services/profile_service.dart'; // Import the ProfileService
import 'package:mychefai/screens/home_screen.dart'; // Import the HomeScreen

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _regionController,
                decoration: InputDecoration(labelText: 'Region'),
              ),
              TextFormField(
                controller: _dietaryRestrictionsController,
                decoration: InputDecoration(labelText: 'Dietary Restrictions'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitProfile,
                child: Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      // Create a new profile
      final newProfile = Profile(
        id: widget.uid,
        uid: widget.uid,
        username: _usernameController.text,
        email: '', // Email will be set later
        profilePicture: '', // Profile picture will be set later
        description: _descriptionController.text,
        region: _regionController.text,
        chefScore: 0.0,
        numberOfReviews: 0,
        dietaryRestrictions: _dietaryRestrictionsController.text,
        myRecipes: [],
        myFavorites: [],
        isFollowing: false,
        followers: 0,
      );

      // Save the new profile to Firestore
      final profileService = ProfileService();
      await profileService.saveProfile(newProfile);

      // Navigate to the HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
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