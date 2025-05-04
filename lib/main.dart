import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart'; // Import OnboardingScreen
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyChefAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: _authService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Show loading indicator
          } else if (snapshot.hasData) {
            // User is signed in, check if profile exists
            return FutureBuilder(
              future: _profileService.getProfileById(snapshot.data!.uid), // Use getProfileById
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Show loading indicator
                } else if (!profileSnapshot.hasData || profileSnapshot.data == null) {
                  // No profile exists, navigate to OnboardingScreen
                  return OnboardingScreen(uid: snapshot.data!.uid);
                } else {
                  // Profile exists, navigate to HomeScreen
                  return HomeScreen();
                }
              },
            );
          } else {
            // No user signed in, navigate to LoginScreen
            return LoginScreen();
          }
        },
      ),
      routes: {
        '/home': (context) => HomeScreen(),
        '/onboarding': (context) {
          final uid = ModalRoute.of(context)!.settings.arguments as String;
          return OnboardingScreen(uid: uid);
        },
      },
    );
  }
}