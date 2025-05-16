// lib/components/profile_action_buttons.dart
import 'package:flutter/material.dart';
import '../components/header_text.dart';

class ProfileActionButtons extends StatelessWidget {
  final VoidCallback? onViewFavorites;
  final VoidCallback? onSignOut;
  final bool isOwnProfile;
  final double contentSpacing;
  final double sectionSpacing;

  const ProfileActionButtons({
    Key? key,
    this.onViewFavorites,
    this.onSignOut,
    required this.isOwnProfile,
    this.contentSpacing = 12.0,
    this.sectionSpacing = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Favorites Button
        if (isOwnProfile && onViewFavorites != null) ...[
          HeaderText(text: 'My Favorites'),
          SizedBox(height: contentSpacing),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.black),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'See my favorites',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),
        ],
        
        // Sign Out Button
        if (isOwnProfile && onSignOut != null) ...[
          SizedBox(height: contentSpacing),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSignOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.red),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),
        ],
      ],
    );
  }
}