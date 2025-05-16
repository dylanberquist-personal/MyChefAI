// lib/components/profile_header.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/profile.dart';

class ProfileHeader extends StatelessWidget {
  final Profile profile;
  final int followerCount;
  final bool isOwnProfile;
  final bool isFollowing;
  final String? currentUserId;
  final File? selectedImage;
  final VoidCallback onPickImage;
  final VoidCallback? onToggleFollow;

  const ProfileHeader({
    Key? key,
    required this.profile,
    required this.followerCount,
    required this.isOwnProfile,
    this.isFollowing = false,
    this.currentUserId,
    this.selectedImage,
    required this.onPickImage,
    this.onToggleFollow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile Image
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: selectedImage != null
                  ? FileImage(selectedImage!)
                  : profile.profilePicture != null 
                      ? NetworkImage(profile.profilePicture!)
                      : AssetImage('assets/images/profile_image_placeholder.png') as ImageProvider,
            ),
            if (isOwnProfile)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        
        // Username
        Text(
          profile.username,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        
        // Follower Count
        Text(
          '$followerCount Followers',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        
        // Follow Button (only for non-owners)
        if (!isOwnProfile && currentUserId != null && currentUserId != profile.uid && onToggleFollow != null)
          ElevatedButton(
            onPressed: onToggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey[300] : Color(0xFFFFFFC1),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFollowing ? Icons.check : Icons.add,
                  size: 18,
                ),
                SizedBox(width: 4),
                Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 32),
      ],
    );
  }
}