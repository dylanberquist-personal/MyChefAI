// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';
import '../models/profile.dart';
import '../models/recipe.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user's notifications
  Future<List<UserNotification>> getUserNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit to most recent 50
          .get();
      
      print('Found ${snapshot.docs.length} notifications for user ${user.uid}');
      
      // For debugging, print the first notification's data
      if (snapshot.docs.isNotEmpty) {
        print('First notification data: ${snapshot.docs.first.data()}');
      }
      
      return snapshot.docs.map((doc) => 
        UserNotification.fromMap(doc.data(), doc.id)
      ).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // Get all unread notifications
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      // Use a batch to update them all at once
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
  
  // Get unread notification count
  Future<int> getUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
  
  // Create a new follower notification
  Future<void> createFollowerNotification(String recipientId, Profile followerProfile) async {
    try {
      final notificationRef = _firestore.collection('notifications').doc();
      
      final notification = UserNotification(
        id: notificationRef.id,
        type: NotificationType.follower,
        recipientId: recipientId,
        senderId: followerProfile.uid,
        senderUsername: followerProfile.username,
        senderProfilePicture: followerProfile.profilePicture,
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      await notificationRef.set(notification.toMap());
    } catch (e) {
      print('Error creating follower notification: $e');
    }
  }
  
  // Create a new recipe favorite notification
  Future<void> createFavoriteNotification(String recipientId, String recipeId, String recipeName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      print('Creating favorite notification: recipient=$recipientId, recipe=$recipeName');
      
      // For favorites, we keep the user anonymous
      final notificationRef = _firestore.collection('notifications').doc();
      
      final notification = UserNotification(
        id: notificationRef.id,
        type: NotificationType.favorite,
        recipientId: recipientId,
        recipeId: recipeId,
        recipeName: recipeName,
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      await notificationRef.set(notification.toMap());
      print('Favorite notification created successfully with ID: ${notificationRef.id}');
    } catch (e) {
      print('Error creating favorite notification: $e');
    }
  }
  
  // Create a new recipe rating notification
  Future<void> createRatingNotification(String recipientId, String recipeId, String recipeName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      print('Creating rating notification: recipient=$recipientId, recipe=$recipeName');
      
      // For ratings, we keep the user anonymous
      final notificationRef = _firestore.collection('notifications').doc();
      
      final notification = UserNotification(
        id: notificationRef.id,
        type: NotificationType.rating,
        recipientId: recipientId,
        recipeId: recipeId,
        recipeName: recipeName,
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      await notificationRef.set(notification.toMap());
      print('Rating notification created successfully with ID: ${notificationRef.id}');
    } catch (e) {
      print('Error creating rating notification: $e');
    }
  }
  
  // Create a new recipe notification for followers
  Future<void> createNewRecipeNotification(Recipe recipe, List<String> followerIds) async {
    try {
      // Create a batch to add notifications for all followers
      final batch = _firestore.batch();
      
      for (String followerId in followerIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        
        final notification = UserNotification(
          id: notificationRef.id,
          type: NotificationType.newRecipe,
          recipientId: followerId,
          senderId: recipe.creator.uid,
          senderUsername: recipe.creator.username,
          senderProfilePicture: recipe.creator.profilePicture,
          recipeId: recipe.id,
          recipeName: recipe.title,
          isRead: false,
          createdAt: DateTime.now(),
        );
        
        batch.set(notificationRef, notification.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error creating new recipe notifications: $e');
    }
  }
}