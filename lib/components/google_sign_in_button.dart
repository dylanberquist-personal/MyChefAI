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
        foregroundColor: Colors.black87,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Color(0xFFD3D3D3)),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
              color: Color(0xFF030303),
              fontSize: 16,
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}