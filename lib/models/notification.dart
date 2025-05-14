// lib/models/notification.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  follower,
  favorite,
  rating,
  newRecipe
}

class UserNotification {
  String id;
  NotificationType type;
  String recipientId; // User receiving the notification
  String? senderId;   // User who triggered the notification (null for anonymous)
  String? senderUsername;
  String? senderProfilePicture;
  String? recipeId;   // Related recipe if applicable
  String? recipeName;
  bool isRead;
  DateTime createdAt;
  
  UserNotification({
    required this.id,
    required this.type,
    required this.recipientId,
    this.senderId,
    this.senderUsername,
    this.senderProfilePicture,
    this.recipeId,
    this.recipeName,
    this.isRead = false,
    required this.createdAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'recipientId': recipientId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderProfilePicture': senderProfilePicture,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'isRead': isRead,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt) : FieldValue.serverTimestamp(),
    };
  }
  
  factory UserNotification.fromMap(Map<String, dynamic> data, String id) {
    // Convert string type to enum
    NotificationType notificationType;
    switch (data['type']) {
      case 'follower':
        notificationType = NotificationType.follower;
        break;
      case 'favorite':
        notificationType = NotificationType.favorite;
        break;
      case 'rating':
        notificationType = NotificationType.rating;
        break;
      case 'newRecipe':
        notificationType = NotificationType.newRecipe;
        break;
      default:
        print('Unknown notification type: ${data['type']}');
        notificationType = NotificationType.follower;
    }
    
    // Handle timestamp with extra debug info
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else {
        print('Unexpected createdAt type: ${data['createdAt'].runtimeType}');
      }
    } else {
      print('createdAt is null in notification data');
    }
    
    return UserNotification(
      id: id,
      type: notificationType,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'],
      senderUsername: data['senderUsername'],
      senderProfilePicture: data['senderProfilePicture'],
      recipeId: data['recipeId'],
      recipeName: data['recipeName'],
      isRead: data['isRead'] ?? false,
      createdAt: createdAt,
    );
  }
}