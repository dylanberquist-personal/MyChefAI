// lib/components/rating_block.dart
import 'package:flutter/material.dart';
import '../services/rating_service.dart';
import '../services/auth_service.dart';

class RatingBlock extends StatefulWidget {
  final String recipeId;
  final Function(double) onRatingChanged; // Callback to update parent

  const RatingBlock({
    Key? key, 
    required this.recipeId,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  _RatingBlockState createState() => _RatingBlockState();
}

class _RatingBlockState extends State<RatingBlock> with SingleTickerProviderStateMixin {
  int _selectedRating = 0; // Tracks the selected rating (0 means no rating)
  final RatingService _ratingService = RatingService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isSubmitting = false; // Track submission state separately
  String? _userId;
  
  // Animation controller for the star pulsing effect
  late AnimationController _animationController;
  int _animatingStarIndex = -1; // Which star is currently animating (-1 means none)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Add a listener to reset the animating star index when animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
        setState(() {
          _animatingStarIndex = -1;
        });
      }
    });
    
    _getCurrentUserAndRating();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserAndRating() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      final userId = user.uid;
      setState(() {
        _userId = userId;
      });

      // Get user's current rating for this recipe
      final rating = await _ratingService.getUserRating(widget.recipeId, userId);
      if (mounted) {
        setState(() {
          _selectedRating = rating ?? 0;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rateRecipe(int rating) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to rate recipes')),
      );
      return;
    }

    if (_isSubmitting) return; // Prevent multiple submissions

    // Start the animation on the tapped star
    setState(() {
      _animatingStarIndex = rating - 1;
    });
    _animationController.forward();

    // Optimistically update UI immediately
    int previousRating = _selectedRating;
    setState(() {
      // If clicking the same star, treat as removing the rating
      if (previousRating == rating) {
        _selectedRating = 0;
      } else {
        _selectedRating = rating;
      }
      _isSubmitting = true; // Set submitting state
    });

    try {
      // Notify parent of rating change
      widget.onRatingChanged(_selectedRating.toDouble());
      
      // Update in Firestore (in background)
      await _ratingService.rateRecipe(widget.recipeId, _userId!, rating);
    } catch (e) {
      // Revert to previous rating if there's an error
      setState(() {
        _selectedRating = previousRating;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rating recipe: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

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
          _isLoading 
              ? CircularProgressIndicator()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the stars horizontally
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: _isSubmitting ? null : () => _rateRecipe(index + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            // Calculate scale - if this is the star being animated
                            double scale = 1.0;
                            if (index == _animatingStarIndex) {
                              // Pulse effect: grow to 1.2x then back to 1.0x
                              final Animation<double> curve = CurvedAnimation(
                                parent: _animationController,
                                curve: Curves.elasticOut,
                              );
                              scale = 1.0 + (0.2 * curve.value);
                            }
                            
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Icon(
                            index < _selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber, // Amber color for the stars
                            size: 48, // Double the size of the stars (from 24 to 48)
                          ),
                        ),
                      ),
                    );
                  }),
                ),
          // No "Your rating: X/5" text as requested
        ],
      ),
    );
  }
}