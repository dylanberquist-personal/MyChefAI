import 'package:flutter/material.dart';
import '../models/profile.dart'; // Import the Profile model
import '../screens/profile_screen.dart'; // Import the ProfileScreen

class ProfileBlock extends StatefulWidget {
  final Profile profile;

  const ProfileBlock({Key? key, required this.profile}) : super(key: key);

  @override
  _ProfileBlockState createState() => _ProfileBlockState();
}

class _ProfileBlockState extends State<ProfileBlock> {
  bool _isFollowing = false; // Track follow state locally

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.profile.isFollowing; // Initialize follow state
  }

  // Toggle follow state (local only)
  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the ProfileScreen with the user's UID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: widget.profile.uid), // Use uid instead of id
          ),
        );
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
            // Follow Button
            ElevatedButton(
              onPressed: _toggleFollow, // Use the local toggle function
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