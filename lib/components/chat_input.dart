// lib/components/chat_input.dart
import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isFirstMessage;
  final VoidCallback onSend;

  const ChatInput({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.isFirstMessage,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use AnimatedContainer for smoother transitions
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text field wrapped in Expanded for layout stability
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                minHeight: 48, // Set minimum height to avoid jumping
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: isFirstMessage 
                      ? 'What would you like to cook?' 
                      : 'Request changes or ask for a new recipe...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Color(0xFFD3D3D3),
                      width: 1,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                  isCollapsed: false, // Helps with sizing consistency
                ),
                onSubmitted: (_) => onSend(),
                // Improve text input performance
                enableSuggestions: false,
                keyboardAppearance: Brightness.light,
              ),
            ),
          ),
          SizedBox(width: 8),
          // Send button with consistent dimensions
          Container(
            width: 48, // Fixed width
            height: 48, // Fixed height
            decoration: BoxDecoration(
              color: Color(0xFFFFFFC1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: isLoading ? null : onSend,
              icon: Icon(
                Icons.send,
                color: isLoading ? Colors.grey : Colors.black,
              ),
              padding: EdgeInsets.zero, // Remove padding to maintain size
            ),
          ),
        ],
      ),
    );
  }
}