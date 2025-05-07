import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'navigation/no_animation_page_route.dart';
import 'models/nutrition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Run the migration to add serving size to existing recipes
  await updateRecipesWithServingSize();
  
  runApp(MyApp());
}

Future<void> updateRecipesWithServingSize() async {
  try {
    // Get all recipes
    final recipesSnapshot = await FirebaseFirestore.instance.collection('recipes').get();
    
    if (recipesSnapshot.docs.isEmpty) {
      print('No recipes found to update.');
      return;
    }
    
    print('Found ${recipesSnapshot.docs.length} recipes to update with serving size.');
    
    // Default serving sizes for different recipe types
    final Map<String, String> defaultServingSizes = {
      'breakfast': '1 cup (240g)',
      'lunch': '1 plate (350g)',
      'dinner': '1 plate (350g)',
      'dessert': '1 slice (120g)',
      'snack': '1 portion (100g)',
      'drink': '1 cup (240ml)',
      'soup': '1 bowl (250ml)',
      'salad': '1 bowl (200g)',
      'appetizer': '1 serving (150g)',
      'side dish': '1/2 cup (120g)',
    };
    
    // Default serving size if no category matches
    const String defaultServingSize = '1 serving (200g)';
    
    // Batch updates for better performance
    final batch = FirebaseFirestore.instance.batch();
    int updateCount = 0;
    
    for (final doc in recipesSnapshot.docs) {
      try {
        final data = doc.data();
        
        // Skip if doesn't have nutritionInfo
        if (!data.containsKey('nutritionInfo')) {
          print('Recipe ${doc.id} has no nutritionInfo, skipping.');
          continue;
        }
        
        final nutritionInfo = data['nutritionInfo'];
        
        // Skip if already has servingSize
        if (nutritionInfo != null && 
            nutritionInfo is Map && 
            nutritionInfo.containsKey('servingSize') && 
            nutritionInfo['servingSize'] != null &&
            nutritionInfo['servingSize'] != '') {
          print('Recipe ${doc.id} already has a serving size, skipping.');
          continue;
        }
        
        // Determine appropriate serving size based on recipe categories
        String servingSize = defaultServingSize;
        if (data.containsKey('categoryTags') && data['categoryTags'] is List) {
          List<dynamic> categories = data['categoryTags'];
          
          // Find first matching category
          for (String category in categories.cast<String>()) {
            category = category.toLowerCase();
            if (defaultServingSizes.containsKey(category)) {
              servingSize = defaultServingSizes[category]!;
              break;
            }
          }
        }
        
        // Update the nutritionInfo map with the serving size
        if (nutritionInfo != null && nutritionInfo is Map) {
          final updatedNutritionInfo = Map<String, dynamic>.from(nutritionInfo);
          updatedNutritionInfo['servingSize'] = servingSize;
          
          // Update the document in the batch
          batch.update(
            doc.reference, 
            {'nutritionInfo.servingSize': servingSize}
          );
          
          updateCount++;
          print('Added serving size "${servingSize}" to recipe ${doc.id}');
        }
      } catch (e) {
        print('Error updating recipe ${doc.id}: $e');
      }
    }
    
    // Commit the batch updates if any were made
    if (updateCount > 0) {
      await batch.commit();
      print('Successfully updated $updateCount recipes with serving size.');
    } else {
      print('No recipes needed serving size updates.');
    }
  } catch (e) {
    print('Error during recipe serving size migration: $e');
  }
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