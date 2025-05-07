// lib/components/recipe_options_menu.dart
import 'package:flutter/material.dart';

class RecipeOptionsMenu extends StatelessWidget {
  final bool isOwner;
  final bool isPublic;
  final Function() onNutritionInfoPressed;
  final Function()? onTogglePublicStatus;

  const RecipeOptionsMenu({
    Key? key,
    required this.isOwner,
    required this.isPublic,
    required this.onNutritionInfoPressed,
    this.onTogglePublicStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Nutrition Info Option - available to all users
              _buildMenuItem(
                context,
                icon: Icons.restaurant_menu,
                iconColor: Colors.green,
                text: 'Nutrition Info',
                onTap: onNutritionInfoPressed,
              ),
              
              // Divider between options
              if (isOwner)
                Divider(height: 1, thickness: 1, color: Color(0xFFD3D3D3)),
                
              // Public/Private Toggle - only for recipe owners
              if (isOwner)
                _buildMenuItem(
                  context,
                  icon: isPublic ? Icons.public : Icons.lock,
                  iconColor: isPublic ? Colors.blue : Colors.orange,
                  text: isPublic ? 'Make Private' : 'Make Public',
                  onTap: onTogglePublicStatus!,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String text,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20), // Increased padding
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 24), // Increased icon size
            SizedBox(width: 16), // Increased spacing
            Text(
              text,
              style: TextStyle(
                fontSize: 18, // Increased font size
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w500,
                color: Color(0xFF030303),
              ),
            ),
          ],
        ),
      ),
    );
  }
}