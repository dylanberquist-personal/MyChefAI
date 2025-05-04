import 'package:flutter/material.dart';

class RecipeTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isFavorited;
  final VoidCallback onBackPressed;
  final VoidCallback onFavoritePressed;
  final VoidCallback onOptionsPressed;

  const RecipeTitleBar({
    Key? key,
    required this.title,
    required this.isFavorited,
    required this.onBackPressed,
    required this.onFavoritePressed,
    required this.onOptionsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8), // Add 8px spacing to the top of the title bar
      child: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24), // 24px padding on sides and top/bottom
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF030303), // Hex color #030303
                    fontSize: 28, // Reduced font size
                    fontFamily: 'Open Sans', // Ensure 'Open Sans' is added to pubspec.yaml
                    fontWeight: FontWeight.w700, // Bold
                    height: 32 / 28, // Line height 32px for font size 28px
                  ),
                  textAlign: TextAlign.left, // Left-align the title text
                  maxLines: 2, // Limit to 2 lines
                  overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                ),
              ),
            ),
            SizedBox(width: 4), // Reduced distance between title and heart icon (from 6 to 4)
            Transform.scale(
              scale: 1.2, // Scale up the heart icon by 20%
              child: IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red, // Red color for the heart
                ),
                onPressed: onFavoritePressed,
              ),
            ),
            SizedBox(width: 4), // Reduced distance between heart icon and options icon (from 6 to 4)
            Transform.translate(
              offset: Offset(-3, 0), // Move the 3-dot icon 3px to the left
              child: Transform.scale(
                scale: 1.2, // Scale up the 3-dot icon by 20%
                child: IconButton(
                  icon: Icon(Icons.more_vert), // 3-dot options icon
                  onPressed: onOptionsPressed,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white, // Set app bar background to white
        surfaceTintColor: Colors.white, // Ensure no tint is applied
        elevation: 0, // Remove app bar shadow
        shadowColor: Colors.transparent, // Remove shadow color
        iconTheme: IconThemeData(color: Colors.black), // Set back button color to black
        leading: Transform.translate(
          offset: Offset(8, 0), // Move the back arrow 8px to the right
          child: Transform.scale(
            scale: 1.2, // Scale up the back arrow icon by 20%
            child: IconButton(
              icon: Icon(Icons.arrow_back), // Back arrow icon
              onPressed: onBackPressed,
            ),
          ),
        ),
        leadingWidth: 56, // Set leading width to 56 (default) to ensure proper spacing
        titleSpacing: 0, // Remove default spacing between leading and title
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 8); // Adjust height to account for top padding
}