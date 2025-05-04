import 'package:flutter/material.dart';

class HeaderText extends StatelessWidget {
  final String text;

  const HeaderText({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Color(0xFF030303), // Hex color #030303
        fontSize: 28, // Increased font size
        fontFamily: 'Open Sans', // Ensure 'Open Sans' is added to pubspec.yaml
        fontWeight: FontWeight.w700, // Bold
        height: 32 / 28, // Line height 32px for font size 28px
      ),
    );
  }
}