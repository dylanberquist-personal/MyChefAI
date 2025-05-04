import 'package:flutter/material.dart';
import 'package:mychefai/components/google_sign_in_button.dart';
import 'package:mychefai/components/header_text.dart';
import 'package:mychefai/screens/home_screen.dart';
import 'package:mychefai/screens/onboarding_screen.dart';
import 'package:mychefai/services/auth_service.dart';
import 'package:mychefai/services/profile_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true; // Toggle between login/signup

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo at the top - reduced size
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 20),
                  child: Image.asset(
                    'assets/images/mychefai_guy.png',
                    height: 80,  // Reduced from 120 to 80
                    fit: BoxFit.contain,
                  ),
                ),
                
                // Welcome text - increased size
                Column(
                  children: [
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        color: Color(0xFF030303),
                        fontSize: 32,  // Increased from default HeaderText size
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'MyChefAI',
                      style: TextStyle(
                        color: Color(0xFF030303),
                        fontSize: 42,  // Increased for emphasis
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Subtitle text styled to match your app
                Text(
                  'Your personal kitchen assistant – create, save, and share recipes with ease.',
                  style: TextStyle(
                    color: Color(0xFF030303),
                    fontSize: 16,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                
                // Email/Password Form
                Container(
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
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLoginMode ? 'Sign In' : 'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF030303),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFFD3D3D3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFFFFFFC1), width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFFD3D3D3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFFFFFFC1), width: 2),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        
                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFFFFC1),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : Text(
                                  _isLoginMode ? 'Sign In' : 'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Open Sans',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        SizedBox(height: 16),
                        
                        // Toggle Login/Signup
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                            });
                          },
                          child: Text(
                            _isLoginMode
                                ? 'Don\'t have an account? Sign up'
                                : 'Already have an account? Sign in',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              color: Color(0xFF030303),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFD3D3D3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFD3D3D3))),
                    ],
                  ),
                ),
                
                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  child: GoogleSignInButton(
                    onSignInSuccess: () async {
                      final user = await _authService.getCurrentUser();
                      if (user != null) {
                        final profile = await _profileService.getProfileById(user.uid);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => profile == null 
                              ? OnboardingScreen(uid: user.uid)
                              : HomeScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        // Sign in
        final userCredential = await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        if (userCredential != null) {
          final profile = await _profileService.getProfileById(userCredential.user!.uid);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => profile == null 
                  ? OnboardingScreen(uid: userCredential.user!.uid)
                  : HomeScreen(),
              ),
            );
          }
        }
      } else {
        // Sign up
        final userCredential = await _authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        if (userCredential != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(uid: userCredential.user!.uid),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}