import 'package:flutter/material.dart';
import 'package:mychefai/components/google_sign_in_button.dart';
import 'package:mychefai/screens/home_screen.dart';
import 'package:mychefai/screens/onboarding_screen.dart';
import 'package:mychefai/services/auth_service.dart';
import 'package:mychefai/services/profile_service.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView( // Allows content to be scrollable if needed
          child: Column(
            children: [
              // Character image at the top with minimal spacing
              Padding(
                padding: const EdgeInsets.only(top: 100), // Just 10px from top
                child: Image.asset(
                  'assets/images/mychefai_guy.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 30), // Reduced space after image
              
              // Welcome text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: Color(0xFF030303),
                    fontSize: 42,
                    fontFamily: 'Quicksand',
                    height: 1.29,
                  ),
                  children: [
                    TextSpan(text: 'Welcome to\n'),
                    TextSpan(
                      text: 'MyChefAI',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24), // Tight space after title
              
              // Subtitle text
              Text(
                'Your personal kitchen assistant – create, save, and share recipes with ease.',
                style: TextStyle(
                  color: Color(0xFF030303),
                  fontSize: 20,
                  fontFamily: 'Poppins',
                  height: 1.31,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 150), // Space before button
              
              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                child: GoogleSignInButton(
                  onSignInSuccess: () async {
                    final user = await _authService.getCurrentUser();
                    if (user != null) {
                      final profile = await _profileService.getProfileById(user.uid);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => profile == null 
                            ? OnboardingScreen(uid: user.uid)
                            : HomeScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 20), // Small buffer at bottom
            ],
          ),
        ),
      ),
    );
  }
}