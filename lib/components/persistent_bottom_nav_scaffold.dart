// lib/components/persistent_bottom_nav_scaffold.dart
import 'package:flutter/material.dart';
import 'footer_nav_bar.dart';
import '../screens/create_recipe_screen.dart'; // Import
import '../navigation/no_animation_page_route.dart'; // Import

class PersistentBottomNavScaffold extends StatelessWidget {
  final Widget body;
  final String? currentUserId;
  final String? currentProfileUserId;
  final Function(int) onNavItemTap;
  final Color backgroundColor;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset; // Add this property

  const PersistentBottomNavScaffold({
    Key? key,
    required this.body,
    this.currentUserId,
    this.currentProfileUserId,
    required this.onNavItemTap,
    this.backgroundColor = Colors.white,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.resizeToAvoidBottomInset = true, // Add default value
  }) : super(key: key);

  void _handleNavTap(BuildContext context, int index) {
    // Special handling for index 2 (Create Recipe)
    if (index == 2) {
      // Navigate directly to CreateRecipeScreen if already on this screen
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
    } else {
      // For other indices, use the provided callback
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
      resizeToAvoidBottomInset: resizeToAvoidBottomInset, // Use the property
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