import 'package:flutter/material.dart';

class CategoryTags extends StatelessWidget {
  final List<String> tags;

  const CategoryTags({
    Key? key,
    required this.tags,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: tags
          .map((tag) => Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Set background color to white
                  borderRadius: BorderRadius.circular(16), // Match the border radius of the profile block
                  border: Border.all(
                    color: Color(0xFFD3D3D3), // Light grey border
                    width: 1, // Border width
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Same shadow color as profile block
                      offset: Offset(2, 2), // Same shadow offset
                      blurRadius: 4, // Same shadow blur radius
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Add padding for better spacing
                child: Text(
                  tag,
                  style: TextStyle(
                    color: Colors.black, // Set text color to black
                    fontSize: 16, // Increased font size
                    fontFamily: 'Open Sans', // Ensure 'Open Sans' is added to pubspec.yaml
                    fontWeight: FontWeight.w500, // Equivalent to 500
                    height: 20 / 16, // Line height 20px for font size 16px
                  ),
                ),
              ))
          .toList(),
    );
  }
}