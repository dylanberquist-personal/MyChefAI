// lib/screens/create_recipe_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // For ScrollDirection
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/profile.dart';
import '../models/recipe.dart';
import '../models/chat_message.dart';
import '../services/recipe_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/recipe_generator_service.dart';
import '../navigation/no_animation_page_route.dart';
import '../screens/recipe_screen.dart';
import '../components/persistent_bottom_nav_scaffold.dart';
import '../components/chat_bubble.dart';
import '../components/chat_input.dart';
import '../components/recipe_chat_preview.dart';
import '../components/restart_chat_dialog.dart';
import '../components/loading_message_manager.dart';
import '../components/animated_chat_message.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({Key? key}) : super(key: key);

  @override
  _CreateRecipeScreenState createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> with WidgetsBindingObserver {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _promptFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final RecipeService _recipeService = RecipeService();
  final LoadingMessageManager _loadingManager = LoadingMessageManager();
  
  // State variables
  String? _currentUserId;
  Profile? _currentUserProfile;
  bool _isLoading = false;
  bool _isRecipeGenerated = false;
  bool _isSavingRecipe = false;  // New state variable for saving state
  String _dietaryRestrictions = '';
  
  // Generated recipe data
  String _generatedTitle = '';
  List<String> _generatedIngredients = [];
  List<String> _generatedInstructions = [];
  List<String> _generatedCategoryTags = [];
  bool _respectsDietaryRestrictions = false;
  late RecipeGenerationResult _generatedRecipe;
  
  // Chat messages
  List<ChatMessage> _messages = [];
  bool _isFirstMessage = true;
  int _lastAnimatedMessageIndex = -1; // Track the last animated message
  bool _isKeyboardVisible = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer for keyboard visibility
    _fetchCurrentUser();
    _addInitialMessages();
    
    // Add listener to scroll controller to dismiss keyboard when scrolling down
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = newValue;
      });
      
      if (_isKeyboardVisible) {
        // When keyboard becomes visible, scroll to bottom with a slight delay
        // to account for the keyboard animation
        Future.delayed(Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      }
    }
  }
  
  // Dismiss keyboard when scrolling down
  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward && _promptFocusNode.hasFocus) {
      // User is scrolling down (swiping up), hide keyboard
      _promptFocusNode.unfocus();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _loadingManager.dispose();
    _promptController.dispose();
    _promptFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addInitialMessages() {
    // Add initial consolidated greeting message (with placeholder for dietary restrictions)
    _messages.add(
      ChatMessage(
        content: 'Hi there! Tell me what you\'d like to cook, and I\'ll create a custom recipe for you. Each chat creates a single recipe - after your first message, all follow-up messages will modify that recipe. To start fresh, use the restart button in the top right.',
        type: MessageType.response,
      )
    );
    _lastAnimatedMessageIndex = 0; // Track that we've animated the first message
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
      
      // Update the greeting message with dietary restrictions if they exist
      if (_dietaryRestrictions.isNotEmpty) {
        setState(() {
          _messages[0] = ChatMessage(
            content: 'Hi there! Tell me what you\'d like to cook, and I\'ll create a custom recipe for you. I\'ll account for your dietary preferences: ${_dietaryRestrictions}.\n\nEach chat creates a single recipe - after your first message, all follow-up messages will modify that recipe. To start fresh, use the restart button in the top right.',
            type: MessageType.response,
          );
        });
      }
    }
  }
}
  
  Future<void> _handleSendPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    
    // Add user message to chat
    setState(() {
      _messages.add(
        ChatMessage(
          content: prompt,
          type: MessageType.prompt,
        )
      );
      _lastAnimatedMessageIndex = _messages.length - 1; // Update last animated message
      _promptController.clear();
    });
    _scrollToBottom();

    if (_currentUserProfile == null) {
      setState(() {
        _messages.add(
          ChatMessage(
            content: 'Please sign in to create recipes.',
            type: MessageType.response,
          )
        );
        _lastAnimatedMessageIndex = _messages.length - 1; // Update last animated message
      });
      _scrollToBottom();
      return;
    }
    
    // Add loading message
    setState(() {
      _isLoading = true;
      final loadingMsg = _loadingManager.getRandomMessage();
      _messages.add(
        ChatMessage(
          content: loadingMsg,
          type: MessageType.response,
        )
      );
      _lastAnimatedMessageIndex = _messages.length - 1; // Update last animated message
    });
    _scrollToBottom();
    
    // Start cycling loading messages
    _loadingManager.startCycling(
      messages: _messages,
      setState: setState,
      scrollToBottom: _scrollToBottom,
    );
    
    try {
      // If this is the first message, generate a new recipe
      if (_isFirstMessage) {
        await _generateNewRecipe(prompt);
      } else {
        // If not the first message, modify the existing recipe
        await _modifyExistingRecipe(prompt);
      }
    } catch (e) {
      print('Error handling prompt: $e');
      setState(() {
        _isLoading = false;
        _messages.removeLast(); // Remove loading message
        _messages.add(
          ChatMessage(
            content: 'Sorry, I had trouble creating your recipe. Please try again.',
            type: MessageType.response,
          )
        );
        _lastAnimatedMessageIndex = _messages.length - 1; // Update last animated message
      });
      _scrollToBottom();
    } finally {
      _loadingManager.stopCycling();
    }
  }
  
  void _toggleExpandRecipe(int index) {
    setState(() {
      _messages[index].isExpanded = !_messages[index].isExpanded;
    });
  }
  
  Future<void> _generateNewRecipe(String prompt) async {
    try {
      // Use the recipe generator service
      final result = await RecipeGeneratorService.generateRecipe(
        prompt,
        _dietaryRestrictions.isNotEmpty ? _dietaryRestrictions : null
      );
      
      if (mounted) {
        setState(() {
          _generatedTitle = result.title;
          _generatedIngredients = result.ingredients;
          _generatedInstructions = result.instructions;
          _generatedCategoryTags = result.categoryTags;
          _respectsDietaryRestrictions = result.respectsDietaryRestrictions;
          _generatedRecipe = result;
          _isRecipeGenerated = true;
          _isLoading = false;
          
          // Remove loading message
          _messages.removeLast();
          
          // Add success message
          _messages.add(
            ChatMessage(
              content: 'I\'ve created a recipe based on your request. Here\'s what I came up with:',
              type: MessageType.response,
            )
          );
          _lastAnimatedMessageIndex = _messages.length - 1;
          
          // Find the future index of this message for toggle functionality
          final futureMessageIndex = _messages.length;
          
          // Add recipe as a special message
          _messages.add(
            ChatMessage(
              content: result.title,
              type: MessageType.recipe,
              extraContent: RecipeChatPreview(
                recipe: result,
                isExpanded: false,
                onToggleExpand: () => _toggleExpandRecipe(futureMessageIndex),
                onSave: _saveRecipe,
                isSaving: _isSavingRecipe,
              ),
              expandedContent: RecipeChatPreview(
                recipe: result,
                isExpanded: true,
                onToggleExpand: () => _toggleExpandRecipe(futureMessageIndex),
                onSave: _saveRecipe,
                isSaving: _isSavingRecipe,
              ),
              respectsDietaryRestrictions: result.respectsDietaryRestrictions,
              dietaryRestrictions: _dietaryRestrictions,
            )
          );
          _lastAnimatedMessageIndex = _messages.length - 1;
          
          // Add follow-up message
          _messages.add(
            ChatMessage(
              content: 'What do you think? If you\'d like any changes, just let me know!',
              type: MessageType.response,
            )
          );
          _lastAnimatedMessageIndex = _messages.length - 1;
          
          _isFirstMessage = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      throw e;
    }
  }
  
  Future<void> _modifyExistingRecipe(String prompt) async {
    try {
      // Pass the current recipe details as context for the modification
      final result = await RecipeGeneratorService.modifyRecipe(
        prompt,
        _dietaryRestrictions.isNotEmpty ? _dietaryRestrictions : null,
        RecipeModificationContext(
          title: _generatedTitle,
          ingredients: _generatedIngredients,
          instructions: _generatedInstructions,
          categoryTags: _generatedCategoryTags,
        ),
      );
      
      if (mounted) {
        setState(() {
          _generatedTitle = result.title;
          _generatedIngredients = result.ingredients;
          _generatedInstructions = result.instructions;
          _generatedCategoryTags = result.categoryTags;
          _respectsDietaryRestrictions = result.respectsDietaryRestrictions;
          _generatedRecipe = result;
          _isRecipeGenerated = true;
          _isLoading = false;
          
          // Remove loading message
          _messages.removeLast();
          
          // Add modified recipe message
          _messages.add(
            ChatMessage(
              content: 'I\'ve updated the recipe based on your feedback. Here\'s the new version:',
              type: MessageType.response,
            )
          );
          _lastAnimatedMessageIndex = _messages.length - 1;
          
          // Find the future index of this message for toggle functionality
          final futureMessageIndex = _messages.length;
          
          // Add recipe as a special message
          _messages.add(
            ChatMessage(
              content: result.title,
              type: MessageType.recipe,
              extraContent: RecipeChatPreview(
                recipe: result,
                isExpanded: false,
                onToggleExpand: () => _toggleExpandRecipe(futureMessageIndex),
                onSave: _saveRecipe,
                isSaving: _isSavingRecipe,
              ),
              expandedContent: RecipeChatPreview(
                recipe: result,
                isExpanded: true,
                onToggleExpand: () => _toggleExpandRecipe(futureMessageIndex),
                onSave: _saveRecipe,
                isSaving: _isSavingRecipe,
              ),
              respectsDietaryRestrictions: result.respectsDietaryRestrictions,
              dietaryRestrictions: _dietaryRestrictions,
            )
          );
          _lastAnimatedMessageIndex = _messages.length - 1;
          
          // Add follow-up message
          _messages.add(
            ChatMessage(
              content: 'How does this look? You can ask for more changes or save this recipe.',
              type: MessageType.response,
            )
          );
          _lastAnimatedMessageIndex = _messages.length - 1;
        });
        _scrollToBottom();
      }
    } catch (e) {
      throw e;
    }
  }
  
  Future<void> _saveRecipe() async {
    if (_currentUserProfile == null || !_isRecipeGenerated) return;
    
    try {
      setState(() {
        _isLoading = true;
        _isSavingRecipe = true; // Set to true when saving starts

        // Find the recipe message and update it with the saving state
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].type == MessageType.recipe) {
            final message = _messages[i];
            _messages[i] = ChatMessage(
              content: message.content,
              type: MessageType.recipe,
              extraContent: RecipeChatPreview(
                recipe: _generatedRecipe,
                isExpanded: false,
                onToggleExpand: () => _toggleExpandRecipe(i),
                onSave: _saveRecipe,
                isSaving: true, // Set to true
              ),
              expandedContent: RecipeChatPreview(
                recipe: _generatedRecipe,
                isExpanded: true,
                onToggleExpand: () => _toggleExpandRecipe(i),
                onSave: _saveRecipe,
                isSaving: true, // Set to true
              ),
              respectsDietaryRestrictions: message.respectsDietaryRestrictions,
              dietaryRestrictions: message.dietaryRestrictions,
              isExpanded: message.isExpanded,
            );
          }
        }
        
        _messages.add(
          ChatMessage(
            content: 'Saving your recipe...',
            type: MessageType.response,
          )
        );
        _lastAnimatedMessageIndex = _messages.length - 1;
      });
      _scrollToBottom();
      
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
        nutritionInfo: _generatedRecipe.nutrition,
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
        nutritionInfo: _generatedRecipe.nutrition,
        isPublic: true,
        isFavorited: false,
        createdAt: DateTime.now(),
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSavingRecipe = false; // Reset saving state
          // Remove "Saving..." message
          _messages.removeLast();
          // Add success message
          _messages.add(
            ChatMessage(
              content: 'Recipe saved successfully! Taking you to the recipe page...',
              type: MessageType.response,
            )
          );
          _lastAnimatedMessageIndex = _messages.length - 1;
        });
        _scrollToBottom();
        
        // Navigate to recipe screen after a short delay
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            NoAnimationPageRoute(
              builder: (context) => RecipeScreen(recipe: savedRecipe),
            ),
          );
        });
      }
    } catch (e) {
      print('Error saving recipe: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSavingRecipe = false; // Reset saving state
          // Remove "Saving..." message
          _messages.removeLast();
          // Add error message
          _messages.add(
            ChatMessage(
              content: 'Sorry, I couldn\'t save your recipe. Please try again.',
              type: MessageType.response,
            )
          );
          _lastAnimatedMessageIndex = _messages.length - 1;
        });
        _scrollToBottom();
      }
    }
  }
  
  void _restartChat() {
  RestartChatDialog.show(
    context: context,
    onRestartConfirmed: () {
      setState(() {
        // Use the consolidated message style
        if (_dietaryRestrictions.isEmpty) {
          _messages = [
            ChatMessage(
              content: 'Hi there! Tell me what you\'d like to cook, and I\'ll create a custom recipe for you. Each chat creates a single recipe - after your first message, all follow-up messages will modify that recipe. To start fresh, use the restart button in the top right.',
              type: MessageType.response,
            )
          ];
        } else {
          _messages = [
            ChatMessage(
              content: 'Hi there! Tell me what you\'d like to cook, and I\'ll create a custom recipe for you. I\'ll account for your dietary preferences: ${_dietaryRestrictions}.\n\nEach chat creates a single recipe - after your first message, all follow-up messages will modify that recipe. To start fresh, use the restart button in the top right.',
              type: MessageType.response,
            )
          ];
        }
        
        _lastAnimatedMessageIndex = 0; // Reset animation for the first message
        _isFirstMessage = true;
        _isRecipeGenerated = false;
        _isLoading = false;
        _isSavingRecipe = false; // Reset saving state
      });
    }
  );
}

  @override
  Widget build(BuildContext context) {
    return PersistentBottomNavScaffold(
      currentUserId: _currentUserId,
      backgroundColor: Color(0xFFF7F7F7),
      resizeToAvoidBottomInset: true,
      onNavItemTap: (index) {
        // Navigation handled by the scaffold
      },
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Create a new recipe',
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
        actions: [
          // Add restart button
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(Icons.refresh),
              tooltip: 'New Recipe',
              onPressed: _restartChat,
            ),
          ),
        ],
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Chat messages area - optimized with caching
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              physics: const AlwaysScrollableScrollPhysics(),
              cacheExtent: 1000, // Increase cache extent for better performance
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isNewMessage = index == _lastAnimatedMessageIndex;
                
                Widget chatBubble;
                if (message.type == MessageType.prompt) {
                  chatBubble = ChatBubble(
                    message: message.content,
                    type: BubbleType.user,
                  );
                } else if (message.type == MessageType.recipe) {
                  chatBubble = ChatBubble(
                    message: message.content,
                    type: BubbleType.assistant,
                    child: message.isExpanded ? message.expandedContent : message.extraContent,
                    respectsDietaryRestrictions: message.respectsDietaryRestrictions,
                    dietaryRestrictions: message.dietaryRestrictions,
                    onTapExpand: () => _toggleExpandRecipe(index),
                    isExpanded: message.isExpanded,
                    isRecipe: true, 
                  );
                } else {
                  chatBubble = ChatBubble(
                    message: message.content,
                    type: BubbleType.assistant,
                  );
                }
                
                // Wrap with animation if it's a new message
                return AnimatedChatMessage(
                  key: ValueKey('message_$index'),
                  child: chatBubble,
                  isNewMessage: isNewMessage,
                );
              },
            ),
          ),
          
          // White background container for input area with 5px bottom padding
          Container(
            color: Colors.white, // Ensure white background
            padding: EdgeInsets.only(
              bottom: _isKeyboardVisible ? 0 : 5, // 5px padding when keyboard is not visible
            ),
            child: ChatInput(
              controller: _promptController,
              focusNode: _promptFocusNode,
              isLoading: _isLoading,
              isFirstMessage: _isFirstMessage,
              onSend: _handleSendPrompt,
            ),
          ),
        ],
      ),
    );
  }
}