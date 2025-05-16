// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../components/persistent_bottom_nav_scaffold.dart';
import '../navigation/no_animation_page_route.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recipe_screen.dart';
import '../screens/create_recipe_screen.dart';
import '../services/recipe_service.dart';
import '../services/profile_service.dart';
import '../services/data_cache_service.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isPersistentNavigation;
  
  const NotificationsScreen({Key? key, this.isPersistentNavigation = false}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with AutomaticKeepAliveClientMixin {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final RecipeService _recipeService = RecipeService();
  final ProfileService _profileService = ProfileService();
  final DataCacheService _dataCache = DataCacheService();
  
  List<UserNotification> _notifications = [];
  bool _isLoading = true;
  String? _currentUserId;
  
  // Cache keys
  static const String _notificationsKey = 'user_notifications';
  static const String _notificationsTimestampKey = 'notifications_timestamp';
  
  @override
  bool get wantKeepAlive => true; // Keep this screen alive when navigating away
  
  @override
  void initState() {
    super.initState();
    
    // Try to restore notifications from cache first
    _restoreFromCache();
    
    // Fetch current user and load notifications
    _fetchCurrentUser();
  }
  
  void _restoreFromCache() {
    final cachedNotifications = _dataCache.get<List<dynamic>>(_notificationsKey);
    final cachedTimestamp = _dataCache.get<DateTime>(_notificationsTimestampKey);
    
    if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
      setState(() {
        _notifications = cachedNotifications.map((notifData) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          Map<String, dynamic> data = {};
          (notifData as Map).forEach((key, value) {
            data[key.toString()] = value;
          });
          
          return UserNotification(
            id: data['id'] ?? '',
            type: _getNotificationTypeFromString(data['type']),
            recipientId: data['recipientId'] ?? '',
            senderId: data['senderId'],
            senderUsername: data['senderUsername'],
            senderProfilePicture: data['senderProfilePicture'],
            recipeId: data['recipeId'],
            recipeName: data['recipeName'],
            isRead: data['isRead'] ?? false,
            createdAt: data['createdAt'] != null ? 
              DateTime.parse(data['createdAt']) : 
              DateTime.now(),
          );
        }).toList();
        
        // If cache is older than 5 minutes, we'll still show loading indicator
        bool isCacheStale = cachedTimestamp == null || 
            DateTime.now().difference(cachedTimestamp).inMinutes > 5;
        
        _isLoading = isCacheStale;
      });
    }
  }
  
  NotificationType _getNotificationTypeFromString(String? typeStr) {
    switch (typeStr) {
      case 'follower': return NotificationType.follower;
      case 'favorite': return NotificationType.favorite;
      case 'rating': return NotificationType.rating;
      case 'newRecipe': return NotificationType.newRecipe;
      default: return NotificationType.follower; // Default case
    }
  }
  
  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.uid;
      });
      await _loadNotifications();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('Loading notifications for user: $_currentUserId');
      final notifications = await _notificationService.getUserNotifications();
      print('Loaded ${notifications.length} notifications');
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        
        // Cache the notifications and timestamp
        _cacheNotifications();
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _cacheNotifications() {
    // Convert notifications to maps for caching
    final notificationMaps = _notifications.map((notification) => {
      'id': notification.id,
      'type': notification.type.toString().split('.').last,
      'recipientId': notification.recipientId,
      'senderId': notification.senderId,
      'senderUsername': notification.senderUsername,
      'senderProfilePicture': notification.senderProfilePicture,
      'recipeId': notification.recipeId,
      'recipeName': notification.recipeName,
      'isRead': notification.isRead,
      'createdAt': notification.createdAt.toIso8601String(),
    }).toList();
    
    _dataCache.set(_notificationsKey, notificationMaps);
    _dataCache.set(_notificationsTimestampKey, DateTime.now());
  }
  
  // Mark all notifications as read
  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      // Update UI to reflect read status
      if (mounted) {
        setState(() {
          for (var notification in _notifications) {
            notification.isRead = true;
          }
        });
        
        // Update cache
        _cacheNotifications();
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }
  
  // Mark single notification as read
  Future<void> _markAsRead(UserNotification notification) async {
    if (notification.isRead) return;
    
    try {
      await _notificationService.markAsRead(notification.id);
      
      // Update UI to reflect read status
      if (mounted) {
        setState(() {
          notification.isRead = true;
        });
        
        // Update cache
        _cacheNotifications();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  
  // Handle notification tap - navigate and mark as read
  Future<void> _handleNotificationTap(UserNotification notification) async {
    // Mark as read
    _markAsRead(notification);
    
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.follower:
        if (notification.senderId != null) {
          Navigator.push(
            context,
            NoAnimationPageRoute(
              builder: (context) => ProfileScreen(userId: notification.senderId!),
            ),
          );
        }
        break;
        
      case NotificationType.favorite:
      case NotificationType.rating:
      case NotificationType.newRecipe:
        if (notification.recipeId != null) {
          // Get the recipe details
          final recipe = await _recipeService.getRecipeById(notification.recipeId!);
          if (recipe != null) {
            Navigator.push(
              context,
              NoAnimationPageRoute(
                builder: (context) => RecipeScreen(recipe: recipe),
              ),
            );
          }
        }
        break;
    }
  }
  
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      NoAnimationPageRoute(
        builder: (context) => HomeScreen(),
      ),
    );
  }
  
  void _navigateToProfile() {
    if (_currentUserId != null) {
      Navigator.push(
        context,
        NoAnimationPageRoute(
          builder: (context) => ProfileScreen(userId: _currentUserId!),
        ),
      );
    }
  }
  
  void _navigateToCreateRecipe() {
    Navigator.push(
      context,
      NoAnimationPageRoute(
        builder: (context) => CreateRecipeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    
    // Use conditional to determine whether to include the nav bar
    return widget.isPersistentNavigation 
      ? _buildMainContent() 
      : PersistentBottomNavScaffold(
          currentUserId: _currentUserId,
          backgroundColor: Colors.white,
          appBar: _buildAppBar(),
          onNavItemTap: (index) {
            if (index == 0) {
              _navigateToHome();
            } else if (index == 2) {
              _navigateToCreateRecipe();
            } else if (index == 4 && _currentUserId != null) {
              _navigateToProfile();
            }
          },
          body: _buildMainContent(),
        );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      title: Text(
        'Notifications',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'Open Sans',
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        // Mark all as read button (only button in app bar now)
        if (_notifications.any((n) => !n.isRead))
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark all as read',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.transparent,
    );
  }
  
  Widget _buildMainContent() {
    return Column(
      children: [
        // Show app bar when in persistent navigation mode
        if (widget.isPersistentNavigation)
          _buildAppBar(),
        
        // Notifications list
        Expanded(
          child: _buildNotificationsList(),
        ),
      ],
    );
  }
  
  Widget _buildNotificationsList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'Open Sans',
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: 80, // Add bottom padding for nav bar
        ),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }
  
  Widget _buildNotificationItem(UserNotification notification) {
    // Format timestamp
    final dateFormat = DateFormat.yMMMd().add_jm();
    final formattedDate = dateFormat.format(notification.createdAt);
    
    // Define icon, color and message based on notification type
    IconData icon;
    Color iconColor;
    String message;
    
    switch (notification.type) {
      case NotificationType.follower:
        icon = Icons.person_add;
        iconColor = Colors.blue;
        message = '${notification.senderUsername ?? 'Someone'} started following you';
        break;
        
      case NotificationType.favorite:
        icon = Icons.favorite;
        iconColor = Colors.red;
        message = 'Someone favorited your recipe "${notification.recipeName ?? 'Unknown'}"';
        break;
        
      case NotificationType.rating:
        icon = Icons.star;
        iconColor = Colors.amber;
        message = 'Someone rated your recipe "${notification.recipeName ?? 'Unknown'}"';
        break;
        
      case NotificationType.newRecipe:
        icon = Icons.restaurant_menu;
        iconColor = Colors.green;
        message = '${notification.senderUsername ?? 'Someone'} posted a new recipe: "${notification.recipeName ?? 'Unknown'}"';
        break;
        
      default:
        // Fallback for unexpected types
        icon = Icons.notification_important;
        iconColor = Colors.purple;
        message = 'You have a new notification';
    }
    
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        color: notification.isRead ? Colors.white : Color(0xFFFFFFC1).withOpacity(0.2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification icon
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            
            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Open Sans',
                      fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  
                  // Timestamp
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Open Sans',
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}