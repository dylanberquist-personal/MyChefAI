// lib/components/persistent_bottom_nav_scaffold.dart
import 'package:flutter/material.dart';
import 'footer_nav_bar.dart';
import '../screens/create_recipe_screen.dart';
import '../screens/home_screen.dart'; // Import HomeScreen
import '../screens/profile_screen.dart'; // Import ProfileScreen
import '../screens/search_screen.dart'; // Add this import for the search screen
import '../navigation/no_animation_page_route.dart';

class PersistentBottomNavScaffold extends StatelessWidget {
  final Widget body;
  final String? currentUserId;
  final String? currentProfileUserId;
  final Function(int) onNavItemTap;
  final Color backgroundColor;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;

  const PersistentBottomNavScaffold({
    Key? key,
    required this.body,
    this.currentUserId,
    this.currentProfileUserId,
    required this.onNavItemTap,
    this.backgroundColor = Colors.white,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
  }) : super(key: key);

  void _handleNavTap(BuildContext context, int index) {
    // Special handling for index 0 (Home)
    if (index == 0) {
      // Check if already on HomeScreen
      if (ModalRoute.of(context)?.settings.name == '/home') {
        return; // Do nothing if already on HomeScreen
      }
      
      // Navigate to HomeScreen
      Navigator.pushReplacement(
        context,
        NoAnimationPageRoute(
          builder: (context) => HomeScreen(),
          settings: RouteSettings(name: '/home'),
        ),
      );
    }
    // Special handling for index 1 (Search)
    else if (index == 1) {
      // Check if already on SearchScreen
      if (ModalRoute.of(context)?.settings.name == '/search') {
        return; // Do nothing if already on SearchScreen
      }
      
      // Navigate to SearchScreen
      Navigator.push(
        context,
        NoAnimationPageRoute(
          builder: (context) => SearchScreen(),
          settings: RouteSettings(name: '/search'),
        ),
      );
    }
    // Special handling for index 2 (Create Recipe)
    else if (index == 2) {
      // Check if already on CreateRecipeScreen
      if (ModalRoute.of(context)?.settings.name == '/create_recipe') {
        return; // Do nothing if already on CreateRecipeScreen
      }
      
      // Navigate to CreateRecipeScreen
      Navigator.push(
        context,
        NoAnimationPageRoute(
          builder: (context) => CreateRecipeScreen(),
          settings: RouteSettings(name: '/create_recipe'),
        ),
      );
    }
    // Special handling for index 4 (Profile)
    else if (index == 4 && currentUserId != null) {
      // Don't navigate if already on current user's profile
      if (ModalRoute.of(context)?.settings.name == '/profile' && 
          currentProfileUserId == currentUserId) {
        return;
      }
      
      // Navigate to ProfileScreen
      Navigator.push(
        context,
        NoAnimationPageRoute(
          builder: (context) => ProfileScreen(userId: currentUserId!),
          settings: RouteSettings(name: '/profile'),
        ),
      );
    }
    // For indices 3, use the provided callback
    else {
      onNavItemTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: body,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: currentUserId != null
          ? FooterNavBar(
              currentUserId: currentUserId!,
              currentProfileUserId: currentProfileUserId,
              onTap: (index) => _handleNavTap(context, index),
            )
          : null,
    );
  }
}