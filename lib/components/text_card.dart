import 'package:flutter/material.dart';

class TextCard extends StatelessWidget {
  final Widget child;
  final double width;

  const TextCard({
    Key? key,
    required this.child,
    this.width = double.infinity, // Will expand to parent constraints
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: child, // No padding here
    );
  }
}