// cook_now_block.dart
import 'package:flutter/material.dart';

class CookNowBlock extends StatelessWidget {
  final VoidCallback onCookNowPressed;

  const CookNowBlock({Key? key, required this.onCookNowPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16, left: 24, right: 24),
      width: MediaQuery.of(context).size.width - 48,
      height: 162,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
      child: Stack(
        children: [
          // Icon in the top-left corner
          Positioned(
            top: 16,
            left: 16,
            child: Icon(
              Icons.restaurant,
              color: Color(0xFF030303),
              size: 24,
            ),
          ),
          // Centered Text and Button
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Text 1
                Text(
                  'Try a new recipe today',
                  style: TextStyle(
                    color: Color(0xFF030303),
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    height: 1.33,
                  ),
                ),
                SizedBox(height: 4),
                // Text 2
                Text(
                  'Challenge your taste buds!',
                  style: TextStyle(
                    color: Color(0xFF030303),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    height: 1.29,
                  ),
                ),
                SizedBox(height: 16),
                // Cook Button
                ElevatedButton(
                  onPressed: onCookNowPressed, // Use the provided callback
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFFFC1),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size(223, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Cook now',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      height: 1.375,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}