// lib/components/loading_message_manager.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class LoadingMessageManager {
  final List<String> loadingMessages = [
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
  
  final Random _random = Random();
  Timer? _loadingMessageTimer;
  String _currentLoadingMessage = '';
  Function(String)? _onNewMessage;
  
  LoadingMessageManager() {
    _currentLoadingMessage = loadingMessages[_random.nextInt(loadingMessages.length)];
  }
  
  void startCycling({
    required List<ChatMessage> messages,
    required Function(VoidCallback) setState,
    required Function()? scrollToBottom,
  }) {
    _onNewMessage = (String newMessage) {
      setState(() {
        // Update the last message if it's a loading message
        if (messages.isNotEmpty && messages.last.type == MessageType.response && messages.last.content.contains('...')) {
          messages.removeLast();
          messages.add(
            ChatMessage(
              content: newMessage,
              type: MessageType.response,
            )
          );
        }
      });
      
      if (scrollToBottom != null) scrollToBottom();
    };
    
    _loadingMessageTimer = Timer.periodic(
      Duration(milliseconds: 2000 + _random.nextInt(1000)), 
      (timer) {
        _currentLoadingMessage = loadingMessages[_random.nextInt(loadingMessages.length)];
        if (_onNewMessage != null) _onNewMessage!(_currentLoadingMessage);
      }
    );
  }
  
  void stopCycling() {
    _loadingMessageTimer?.cancel();
    _loadingMessageTimer = null;
    _onNewMessage = null;
  }
  
  void dispose() {
    stopCycling();
  }
  
  String get currentMessage => _currentLoadingMessage;
  
  String getRandomMessage() {
    return loadingMessages[_random.nextInt(loadingMessages.length)];
  }
}