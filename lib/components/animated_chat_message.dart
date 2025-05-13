// lib/components/animated_chat_message.dart
import 'package:flutter/material.dart';

class AnimatedChatMessage extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool isNewMessage;

  const AnimatedChatMessage({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    required this.isNewMessage,
  }) : super(key: key);

  @override
  _AnimatedChatMessageState createState() => _AnimatedChatMessageState();
}

class _AnimatedChatMessageState extends State<AnimatedChatMessage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.25), // Slide up from slightly below
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start the animation if this is a new message
    if (widget.isNewMessage) {
      _controller.forward();
    } else {
      _controller.value = 1.0; // Set to completed state for existing messages
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}