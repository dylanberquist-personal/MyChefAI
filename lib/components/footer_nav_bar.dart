import 'package:flutter/material.dart';

class FooterNavBar extends StatelessWidget {
  final Function(int) onTap;
  final String? currentUserId; // Add currentUserId parameter
  final String? currentProfileUserId; // Add currentProfileUserId parameter

  FooterNavBar({
    required this.onTap,
    this.currentUserId,
    this.currentProfileUserId, // Pass the current profile's user ID
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none, // Allow overflow
        children: [
          // Icons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home Icon
              IconButton(
                onPressed: () => onTap(0),
                icon: Icon(
                  Icons.home,
                  color: Color(0xFF2B2C2B),
                  size: 28,
                ),
              ),
              // Search Icon
              IconButton(
                onPressed: () => onTap(1),
                icon: Icon(
                  Icons.search,
                  color: Color(0xFF030303),
                  size: 28,
                ),
              ),
              // Placeholder for Create Recipe Button (to maintain spacing)
              SizedBox(width: 60),
              // Notifications Icon
              IconButton(
                onPressed: () => onTap(3),
                icon: Icon(
                  Icons.notifications,
                  color: Color(0xFF2B2C2B),
                  size: 28,
                ),
              ),
              // Profile Icon
              IconButton(
                onPressed: () {
                  if (currentUserId != null && currentUserId != currentProfileUserId) {
                    onTap(4); // Only navigate if not already on the current user's profile
                  }
                },
                icon: Icon(
                  Icons.person,
                  color: Color(0xFF2B2C2B),
                  size: 28,
                ),
              ),
            ],
          ),
          // Create Recipe Button (centered and oversized)
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30, // Center horizontally
            bottom: 10, // Adjust vertical position
            child: ClipOval(
              child: Material(
                color: Color(0xFFFFFFC1), // Yellow background
                child: InkWell(
                  onTap: () => onTap(2), // Index 2 corresponds to Create Recipe
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.add,
                      color: Color(0xFF2B2C2B),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}