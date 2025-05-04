import 'package:flutter/material.dart';

class RatingBlock extends StatefulWidget {
  const RatingBlock({Key? key}) : super(key: key);

  @override
  _RatingBlockState createState() => _RatingBlockState();
}

class _RatingBlockState extends State<RatingBlock> {
  int _selectedRating = 0; // Tracks the selected rating (0 means no rating)

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Rate this recipe',
            style: TextStyle(
              color: Color(0xFF030303), // Hex color #030303
              fontSize: 28, // Match font size of other headers
              fontFamily: 'Open Sans', // Ensure 'Open Sans' is added to pubspec.yaml
              fontWeight: FontWeight.w700, // Match boldness of other headers
            ),
          ),
          SizedBox(height: 8), // Spacing between text and stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the stars horizontally
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = index + 1; // Update the selected rating
                  });
                },
                child: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber, // Amber color for the stars
                  size: 48, // Double the size of the stars (from 24 to 48)
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}