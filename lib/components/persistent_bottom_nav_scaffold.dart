// lib/components/persistent_bottom_nav_scaffold.dart
import 'package:flutter/material.dart';
import 'footer_nav_bar.dart';

class PersistentBottomNavScaffold extends StatelessWidget {
  final Widget body;
  final String? currentUserId;
  final String? currentProfileUserId;
  final Function(int) onNavItemTap;
  final Color backgroundColor;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;

  const PersistentBottomNavScaffold({
    Key? key,
    required this.body,
    this.currentUserId,
    this.currentProfileUserId,
    required this.onNavItemTap,
    this.backgroundColor = Colors.white,
    this.extendBodyBehindAppBar = false,
    this.appBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: body,
      bottomNavigationBar: currentUserId != null
          ? FooterNavBar(
              currentUserId: currentUserId!,
              currentProfileUserId: currentProfileUserId,
              onTap: onNavItemTap,
            )
          : null,
    );
  }
}