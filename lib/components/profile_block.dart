import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../screens/profile_screen.dart';
import '../services/profile_service.dart';
import '../navigation/no_animation_page_route.dart';

class ProfileBlock extends StatefulWidget {
  final Profile profile;

  const ProfileBlock({Key? key, required this.profile}) : super(key: key);

  @override
  _ProfileBlockState createState() => _ProfileBlockState();
}

class _ProfileBlockState extends State<ProfileBlock> {
  bool _isFollowing = false;
  final ProfileService _profileService = ProfileService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    _currentUserId = await _profileService.getCurrentUserId();
    if (_currentUserId != null && mounted) {
      await _checkFollowStatus();
    }
  }

  Future<void> _checkFollowStatus() async {
    if (_currentUserId == null || _currentUserId == widget.profile.uid) return;
    
    try {
      bool isFollowing = await _profileService.checkIfFollowing(widget.profile.uid);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  // Toggle follow state and update in Firestore
  Future<void> _toggleFollow() async {
    if (_currentUserId == null) return;
    
    // Don't allow following yourself
    if (_currentUserId == widget.profile.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot follow yourself')),
      );
      return;
    }

    // Optimistically update UI immediately
    setState(() {
      _isFollowing = !_isFollowing;
    });

    try {
      if (_isFollowing) {
        // Follow the user
        await _profileService.followUser(_currentUserId!, widget.profile.uid);
      } else {
        // Unfollow the user
        await _profileService.unfollowUser(_currentUserId!, widget.profile.uid);
      }
    } catch (e) {
      // Revert state if operation fails
      setState(() {
        _isFollowing = !_isFollowing;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the ProfileScreen with the user's UID
        Navigator.push(
          context,
          NoAnimationPageRoute(
            builder: (context) => ProfileScreen(userId: widget.profile.uid),
          ),
        ).then((_) {
          // Refresh follow status when returning from profile screen
          _checkFollowStatus();
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFFD3D3D3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Picture
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: widget.profile.profilePicture != null && widget.profile.profilePicture!.isNotEmpty
                      ? NetworkImage(widget.profile.profilePicture!) // Use NetworkImage for URLs
                      : AssetImage('assets/images/profile_image_placeholder.png') as ImageProvider, // Use AssetImage for local assets
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 16),
            // Profile Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  Text(
                    widget.profile.username,
                    style: TextStyle(
                      color: Color(0xFF030303),
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Chef Score
                  Text(
                    'Chef Score: ${widget.profile.chefScore.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Color(0xFF030303),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Follow Button - Only show if we have current user ID and not own profile
            if (_currentUserId != null && _currentUserId != widget.profile.uid)
              ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey[300] : Color(0xFFFFFFC1),
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
                      _isFollowing ? Icons.check : Icons.add,
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _isFollowing ? 'Followed' : 'Follow',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}