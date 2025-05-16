// lib/screens/root_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../components/footer_nav_bar.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/create_recipe_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({Key? key}) : super(key: key);

  @override
  _RootScreenState createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  String? _currentUserId;
  final PageController _pageController = PageController();
  
  // Keep instances of screens to preserve their state
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    
    // Initialize screens - we'll update the profile screen once we have userId
    _screens = [
      HomeScreen(isPersistentNavigation: true),
      SearchScreen(isPersistentNavigation: true),
      CreateRecipeScreen(isPersistentNavigation: true),
      NotificationsScreen(isPersistentNavigation: true),
      Container(), // Placeholder for profile screen
    ];
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.uid;
        // Now that we have the user ID, update the profile screen
        if (_currentUserId != null) {
          _screens[4] = ProfileScreen(
            userId: _currentUserId!, 
            isPersistentNavigation: true
          );
        }
      });
    }
  }

  void _onNavItemTapped(int index) {
    // Special handling for Create Recipe (index 2)
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateRecipeScreen()),
      );
      return;
    }
    
    setState(() {
      _currentIndex = index;
      // Animate to the selected page
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Disable swiping
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: FooterNavBar(
        onTap: _onNavItemTapped,
        currentUserId: _currentUserId,
        // Only needed if you're viewing a profile of another user
        currentProfileUserId: _currentIndex == 4 ? _currentUserId : null,
      ),
    );
  }
}