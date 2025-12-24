// lib/widgets/mechanic_notification_bell.dart

import 'package:flutter/material.dart';
import 'package:suaxe_app/services/notification_service.dart';
import 'package:suaxe_app/screens/Technician/notifications/mechanic_notification_list_screen.dart';

class MechanicNotificationBell extends StatefulWidget {
  const MechanicNotificationBell({super.key});

  @override
  State<MechanicNotificationBell> createState() => _MechanicNotificationBellState();
}

class _MechanicNotificationBellState extends State<MechanicNotificationBell> {
  final _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    
    // Refresh every 30 seconds
    Future.delayed(const Duration(seconds: 30), _refreshUnreadCount);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('❌ Error loading unread count: $e');
    }
  }

  Future<void> _refreshUnreadCount() async {
    if (!mounted) return;
    
    await _loadUnreadCount();
    
    // Refresh again after 30 seconds
    Future.delayed(const Duration(seconds: 30), _refreshUnreadCount);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        // Navigate to notification list
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MechanicNotificationListScreen(),
          ),
        );
        
        // Refresh count after returning
        await _loadUnreadCount();
      },
      icon: Stack(
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 28,
          ),
          
          // Badge - MÀU CAM CHO MECHANIC
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orange, // ← Viền cam cho mechanic
                    width: 1,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}