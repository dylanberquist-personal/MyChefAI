// lib/screens/create_recipe_screen.dart
import 'package:flutter/material.dart';
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

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({Key? key}) : super(key: key);

  @override
  _CreateRecipeScreenState createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _promptFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final RecipeService _recipeService = RecipeService();
  final LoadingMessageManager _loadingManager = LoadingMessageManager();
  
  String? _currentUserId;
  Profile? _currentUserProfile;
  bool _isLoading = false;
  bool _isRecipeGenerated = false;
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
  
  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _addInitialMessages();
  }
  
  @override
  void dispose() {
    _loadingManager.dispose();
    _promptController.dispose();
    _promptFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addInitialMessages() {
    // Add initial consolidated greeting message (with placeholder for dietary restrictions)
    // The dietary info will be updated after fetching user profile
    _messages.add(
      ChatMessage(
        content: 'Hi there! Tell me what you\'d like to cook, and I\'ll create a custom recipe for you.',
        type: MessageType.response,
      )
    );
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
              content: 'Hi there! Tell me what you\'d like to cook, and I\'ll create a custom recipe for you. I\'ll account for your dietary preferences: $_dietaryRestrictions.',
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
              ),
              expandedContent: RecipeChatPreview(
                recipe: result,
                isExpanded: true,
                onToggleExpand: () => _toggleExpandRecipe(futureMessageIndex),
                onSave: _saveRecipe,
              ),
              respectsDietaryRestrictions: result.respectsDietaryRestrictions,
              dietaryRestrictions: _dietaryRestrictions,
            )
          );
          
          // Add follow-up message
          _messages.add(
            ChatMessage(
              content: 'What do you think? If you\'d like any changes, just let me know!',
              type: MessageType.response,
            )
          );
          
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
          
          // Add modified recipe message
          _messages.add(
            ChatMessage(
              content: 'I\'ve updated the recipe based on your feedback. Here\'s the new version:',
              type: MessageType.response,
            )
          );
          
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
              ),
              expandedContent: RecipeChatPreview(
                recipe: result,
                isExpanded: true,
                onToggleExpand: () => _toggleExpandRecipe(futureMessageIndex),
                onSave: _saveRecipe,
              ),
              respectsDietaryRestrictions: result.respectsDietaryRestrictions,
              dietaryRestrictions: _dietaryRestrictions,
            )
          );
          
          // Add follow-up message
          _messages.add(
            ChatMessage(
              content: 'How does this look? You can ask for more changes or save this recipe.',
              type: MessageType.response,
            )
          );
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
        _messages.add(
          ChatMessage(
            content: 'Saving your recipe...',
            type: MessageType.response,
          )
        );
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
          // Remove "Saving..." message
          _messages.removeLast();
          // Add success message
          _messages.add(
            ChatMessage(
              content: 'Recipe saved successfully! Taking you to the recipe page...',
              type: MessageType.response,
            )
          );
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
          // Remove "Saving..." message
          _messages.removeLast();
          // Add error message
          _messages.add(
            ChatMessage(
              content: 'Sorry, I couldn\'t save your recipe. Please try again.',
              type: MessageType.response,
            )
          );
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
                content: 'Hi there! Tell me what you\'d like to cook, and I\'ll create a custom recipe for you.',
                type: MessageType.response,
              )
            ];
          } else {
            _messages = [
              ChatMessage(
                content: 'Hi there! Tell me what you\'d like to cook, and I\'ll create a custom recipe for you. I\'ll account for your dietary preferences: $_dietaryRestrictions.',
                type: MessageType.response,
              )
            ];
          }
          
          _isFirstMessage = true;
          _isRecipeGenerated = false;
          _isLoading = false;
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return PersistentBottomNavScaffold(
      currentUserId: _currentUserId,
      backgroundColor: Color(0xFFF7F7F7), // Light gray background for chat
      onNavItemTap: (index) {
        // Navigation handled by the scaffold
      },
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Create a new recipe', // Changed from 'Recipe Creator'
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
              style: IconButton.styleFrom(
                backgroundColor: Color(0xFFFFFFC1).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                
                if (message.type == MessageType.prompt) {
                  return ChatBubble(
                    message: message.content,
                    type: BubbleType.user,
                  );
                } else if (message.type == MessageType.recipe) {
                  return ChatBubble(
                    message: message.content,
                    type: BubbleType.assistant,
                    child: message.isExpanded ? message.expandedContent : message.extraContent,
                    respectsDietaryRestrictions: message.respectsDietaryRestrictions,
                    dietaryRestrictions: message.dietaryRestrictions,
                    onTapExpand: () => _toggleExpandRecipe(index),
                    isExpanded: message.isExpanded,
                    isRecipe: true, // Add this flag to identify recipe messages
                  );
                } else {
                  return ChatBubble(
                    message: message.content,
                    type: BubbleType.assistant,
                  );
                }
              },
            ),
          ),
          
          // Input area with padding below
          Padding(
            padding: EdgeInsets.only(bottom: 5), // 5px padding below the input area
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