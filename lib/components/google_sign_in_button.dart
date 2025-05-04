import 'package:flutter/material.dart';
import 'package:mychefai/services/auth_service.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onSignInSuccess; // Callback for successful sign-in
  final AuthService authService = AuthService();

  GoogleSignInButton({required this.onSignInSuccess});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        print('Google Sign-In button pressed.');
        final userCredential = await authService.signInWithGoogle();
        if (userCredential != null) {
          print('Google Sign-In successful. Navigating to HomeScreen...');
          onSignInSuccess(); // Trigger callback
        } else {
          print('Google Sign-In failed or was canceled.');
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/google_logo.png',
            height: 24,
            width: 24,
          ),
          SizedBox(width: 12),
          Text(
            'Sign in with Google',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}