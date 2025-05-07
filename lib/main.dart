import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'navigation/no_animation_page_route.dart';

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
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MyChefAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            // Use no animation for all platforms
            TargetPlatform.android: _NoAnimationTransitionBuilder(),
            TargetPlatform.iOS: _NoAnimationTransitionBuilder(),
            TargetPlatform.fuchsia: _NoAnimationTransitionBuilder(),
            TargetPlatform.linux: _NoAnimationTransitionBuilder(),
            TargetPlatform.macOS: _NoAnimationTransitionBuilder(),
            TargetPlatform.windows: _NoAnimationTransitionBuilder(),
          },
        ),
      ),
      home: FutureBuilder(
        future: _authService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Show loading indicator
          } else if (snapshot.hasData) {
            // User is signed in, check if profile exists
            return FutureBuilder(
              future: _profileService.getProfileById(snapshot.data!.uid),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator()); // Show loading indicator
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
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return NoAnimationPageRoute(builder: (context) => HomeScreen());
        } else if (settings.name == '/onboarding') {
          final uid = settings.arguments as String;
          return NoAnimationPageRoute(builder: (context) => OnboardingScreen(uid: uid));
        }
        return null;
      },
    );
  }
}

class _NoAnimationTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}