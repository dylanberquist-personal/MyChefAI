// lib/models/chat_message.dart
import 'package:flutter/material.dart';

enum MessageType {
  prompt,
  response,
  recipe
}

class ChatMessage {
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final Widget? extraContent;
  final Widget? expandedContent;
  final bool? respectsDietaryRestrictions;
  final String? dietaryRestrictions;
  bool isExpanded;

  ChatMessage({
    required this.content,
    required this.type,
    Widget? extraContent,
    this.expandedContent,
    this.respectsDietaryRestrictions,
    this.dietaryRestrictions,
    this.isExpanded = false,
  }) : 
    this.timestamp = DateTime.now(),
    this.extraContent = extraContent;
}