// lib/components/footer_nav_bar.dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class FooterNavBar extends StatefulWidget {
  final Function(int) onTap;
  final String? currentUserId;
  final String? currentProfileUserId;

  FooterNavBar({
    required this.onTap,
    this.currentUserId,
    this.currentProfileUserId,
  });

  @override
  _FooterNavBarState createState() => _FooterNavBarState();
}

class _FooterNavBarState extends State<FooterNavBar> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  
  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }
  
  Future<void> _fetchUnreadCount() async {
    if (widget.currentUserId != null) {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Icons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home Icon
              IconButton(
                onPressed: () => widget.onTap(0),
                icon: Icon(
                  Icons.home,
                  color: Color(0xFF2B2C2B),
                  size: 28,
                ),
              ),
              // Search Icon
              IconButton(
                onPressed: () => widget.onTap(1),
                icon: Icon(
                  Icons.search,
                  color: Color(0xFF030303),
                  size: 28,
                ),
              ),
              // Placeholder for Create Recipe Button (to maintain spacing)
              SizedBox(width: 60),
              // Notifications Icon with Badge
              Stack(
                children: [
                  IconButton(
                    onPressed: () => widget.onTap(3),
                    icon: Icon(
                      Icons.notifications,
                      color: Color(0xFF2B2C2B),
                      size: 28,
                    ),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 3,
                      top: 3,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // Profile Icon
              IconButton(
                onPressed: () {
                  if (widget.currentUserId != null && widget.currentUserId != widget.currentProfileUserId) {
                    widget.onTap(4);
                  }
                },
                icon: Icon(
                  Icons.person,
                  color: Color(0xFF2B2C2B),
                  size: 28,
                ),
              ),
            ],
          ),
          // Create Recipe Button (centered and oversized)
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30,
            bottom: 10,
            child: ClipOval(
              child: Material(
                color: Color(0xFFFFFFC1),
                child: InkWell(
                  onTap: () => widget.onTap(2),
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.add,
                      color: Color(0xFF2B2C2B),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}