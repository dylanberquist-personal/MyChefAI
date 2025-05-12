import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/recipe.dart';
import '../models/profile.dart';
import '../models/nutrition.dart';
import '../services/recipe_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/recipe_generator_service.dart';
import '../navigation/no_animation_page_route.dart';
import '../screens/recipe_screen.dart';
import '../components/recipe_form.dart';
import '../components/recipe_loading_indicator.dart';
import '../components/generated_recipe_view.dart';
import '../components/persistent_bottom_nav_scaffold.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({Key? key}) : super(key: key);

  @override
  _CreateRecipeScreenState createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final RecipeService _recipeService = RecipeService();
  final Random _random = Random();
  
  String? _currentUserId;
  Profile? _currentUserProfile;
  bool _isLoading = false;
  bool _isRecipeGenerated = false;
  String? _errorMessage;
  String _dietaryRestrictions = '';
  bool _respectsDietaryRestrictions = false;
  
  // Loading state
  String _loadingMessage = 'Creating your recipe...';
  Timer? _loadingMessageTimer;
  List<String> _loadingMessages = [
    'Searching for the perfect ingredients...',
    'Adding a pinch of creativity...',
    'Calculating nutrition facts...',
    'Testing flavors in our virtual kitchen...',
    'Making sure measurements are perfect...',
    'Adjusting for your dietary preferences...',
    'Almost there! Final touches...',
    'Consulting with our virtual chef...',
    'Balancing flavors...',
    'Checking cooking times...',
    'Making it delicious...',
    'Finding complementary ingredients...',
    'Adjusting spices to perfection...',
    'Making sure it\'s easy to prepare...',
    'Ensuring it fits your preferences...',
    'Creating a culinary masterpiece...',
    'Infusing some culinary magic...',
    'Mixing textures and flavors...',
    'Ensuring the recipe is balanced...',
    'Making it both healthy and tasty...',
  ];
  
  // Generated recipe data
  String _generatedTitle = '';
  List<String> _generatedIngredients = [];
  List<String> _generatedInstructions = [];
  List<String> _generatedCategoryTags = [];
  Nutrition? _generatedNutrition;
  
  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }
  
  @override
  void dispose() {
    _loadingMessageTimer?.cancel();
    _promptController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      
      final profile = await _profileService.getProfileById(user.uid);
      if (profile != null) {
        setState(() {
          _currentUserProfile = profile;
          _dietaryRestrictions = profile.dietaryRestrictions;
        });
      }
    }
  }
  
  void _startLoadingMessageCycle() {
    _loadingMessageTimer = Timer.periodic(Duration(milliseconds: 2000 + _random.nextInt(1000)), (timer) {
      if (_isLoading && mounted) {
        setState(() {
          _loadingMessage = _loadingMessages[_random.nextInt(_loadingMessages.length)];
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  Future<void> _generateRecipe() async {
    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a prompt for your recipe';
      });
      return;
    }
    
    if (_currentUserProfile == null) {
      setState(() {
        _errorMessage = 'Please sign in to create recipes';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadingMessage = _loadingMessages[_random.nextInt(_loadingMessages.length)];
    });
    
    _startLoadingMessageCycle();
    
    try {
      // Use the recipe generator service
      final result = await RecipeGeneratorService.generateRecipe(
        _promptController.text.trim(),
        _dietaryRestrictions.isNotEmpty ? _dietaryRestrictions : null
      );
      
      if (mounted) {
        setState(() {
          _generatedTitle = result.title;
          _generatedIngredients = result.ingredients;
          _generatedInstructions = result.instructions;
          _generatedCategoryTags = result.categoryTags;
          _respectsDietaryRestrictions = result.respectsDietaryRestrictions;
          _generatedNutrition = result.nutrition;
          _isRecipeGenerated = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error generating recipe: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error generating recipe: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      _loadingMessageTimer?.cancel();
    }
  }
  
  Future<void> _saveRecipe() async {
    if (_currentUserProfile == null || !_isRecipeGenerated) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final newRecipe = Recipe(
        id: null,
        title: _generatedTitle,
        image: null,
        ingredients: _generatedIngredients,
        instructions: _generatedInstructions,
        categoryTags: _generatedCategoryTags,
        creator: _currentUserProfile!,
        averageRating: 0.0,
        numberOfRatings: 0,
        numberOfFavorites: 0,
        nutritionInfo: _generatedNutrition!,
        isPublic: true,
        isFavorited: false,
        createdAt: DateTime.now(),
      );
      
      final recipeId = await _recipeService.createRecipe(newRecipe);
      
      final savedRecipe = Recipe(
        id: recipeId,
        title: _generatedTitle,
        image: null,
        ingredients: _generatedIngredients,
        instructions: _generatedInstructions,
        categoryTags: _generatedCategoryTags,
        creator: _currentUserProfile!,
        averageRating: 0.0,
        numberOfRatings: 0,
        numberOfFavorites: 0,
        nutritionInfo: _generatedNutrition!,
        isPublic: true,
        isFavorited: false,
        createdAt: DateTime.now(),
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        Navigator.pushReplacement(
          context,
          NoAnimationPageRoute(
            builder: (context) => RecipeScreen(recipe: savedRecipe),
          ),
        );
      }
    } catch (e) {
      print('Error saving recipe: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving recipe: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  void _resetRecipeGeneration() {
    setState(() {
      _isRecipeGenerated = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return PersistentBottomNavScaffold(
      currentUserId: _currentUserId,
      backgroundColor: Colors.white,
      onNavItemTap: (index) {
        // Navigation handled by the scaffold
      },
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Create Recipe',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Transform.translate(
          offset: Offset(8, 0),
          child: Transform.scale(
            scale: 1.2,
            child: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Form
            RecipeForm(
              promptController: _promptController,
              dietaryRestrictions: _dietaryRestrictions.isNotEmpty ? _dietaryRestrictions : null,
              errorMessage: _errorMessage,
              isLoading: _isLoading,
              isRecipeGenerated: _isRecipeGenerated,
              onGenerate: _generateRecipe,
            ),
            
            // Loading Indicator
            if (_isLoading) ...[
              SizedBox(height: 32),
              RecipeLoadingIndicator(loadingMessage: _loadingMessage),
            ],
            
            // Generated Recipe View
            if (_isRecipeGenerated && !_isLoading) ...[
              SizedBox(height: 32),
              GeneratedRecipeView(
                title: _generatedTitle,
                ingredients: _generatedIngredients,
                instructions: _generatedInstructions,
                categoryTags: _generatedCategoryTags,
                nutrition: _generatedNutrition,
                respectsDietaryRestrictions: _respectsDietaryRestrictions,
                dietaryRestrictions: _dietaryRestrictions.isNotEmpty ? _dietaryRestrictions : null,
                isLoading: _isLoading,
                onSave: _saveRecipe,
                onTryAgain: !_respectsDietaryRestrictions ? _resetRecipeGeneration : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}