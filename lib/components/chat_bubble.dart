// lib/components/chat_bubble.dart
import 'package:flutter/material.dart';

enum BubbleType {
  user,
  assistant
}

class ChatBubble extends StatefulWidget {
  final String message;
  final BubbleType type;
  final Widget? child;
  final bool? respectsDietaryRestrictions;
  final String? dietaryRestrictions;
  final Function()? onTapExpand;
  final bool isExpanded;
  final bool isRecipe;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.type,
    this.child,
    this.respectsDietaryRestrictions,
    this.dietaryRestrictions,
    this.onTapExpand,
    this.isExpanded = false,
    this.isRecipe = false,
  }) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showDietaryExplanation = false;
  
  void _toggleDietaryExplanation() {
    setState(() {
      _showDietaryExplanation = !_showDietaryExplanation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.type == BubbleType.user;
    final hasRestrictionInfo = widget.respectsDietaryRestrictions != null && 
                              widget.dietaryRestrictions != null && 
                              widget.dietaryRestrictions!.isNotEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isUser 
              ? MediaQuery.of(context).size.width * 0.8 
              : widget.isRecipe 
                  ? MediaQuery.of(context).size.width * 0.95
                  : MediaQuery.of(context).size.width * 0.9,
        ),
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: isUser ? 50 : 5,
          right: isUser ? 5 : 50,
        ),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? Color(0xFFFFFFC1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser ? Color(0xFFFFFFC1) : Color(0xFFD3D3D3),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // For normal messages (not recipes), show the text
            if (!widget.isRecipe)
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Open Sans',
                  color: Colors.black87,
                ),
              ),
              
            // For recipe messages with dietary restriction information
            if (widget.isRecipe && hasRestrictionInfo)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dietary explanation space when expanded (pushes content down)
                  if (_showDietaryExplanation)
                    Container(
                      margin: EdgeInsets.only(bottom: 12),
                      width: double.infinity,
                      child: DietaryExplanation(
                        respectsRestrictions: widget.respectsDietaryRestrictions!,
                        restrictions: widget.dietaryRestrictions!,
                        onTap: _toggleDietaryExplanation,
                      ),
                    ),
                    
                  // Recipe content
                  Stack(
                    children: [
                      // Main recipe content
                      widget.child ?? Container(),
                      
                      // Position the dietary indicator only when NOT showing explanation
                      if (!_showDietaryExplanation)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _toggleDietaryExplanation,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: widget.respectsDietaryRestrictions! 
                                    ? Colors.green 
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.respectsDietaryRestrictions! 
                                    ? Icons.check 
                                    : Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
            // For recipe messages without dietary info
            if (widget.isRecipe && !hasRestrictionInfo && widget.child != null)
              widget.child!,
          ],
        ),
      ),
    );
  }
}

// Extracted widget for the dietary explanation
class DietaryExplanation extends StatelessWidget {
  final bool respectsRestrictions;
  final String restrictions;
  final VoidCallback onTap;

  const DietaryExplanation({
    Key? key,
    required this.respectsRestrictions,
    required this.restrictions,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: respectsRestrictions 
              ? Colors.green.withOpacity(0.1) 
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: respectsRestrictions ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon in the explanation
            Container(
              margin: EdgeInsets.only(right: 8, top: 2),
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: respectsRestrictions ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                respectsRestrictions ? Icons.check : Icons.close,
                color: Colors.white,
                size: 12,
              ),
            ),
            
            // Explanation text
            Expanded(
              child: Text(
                respectsRestrictions
                    ? 'This recipe accounts for your dietary restrictions: $restrictions'
                    : 'This recipe may not fully account for your dietary restrictions: $restrictions',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Open Sans',
                  color: respectsRestrictions ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}