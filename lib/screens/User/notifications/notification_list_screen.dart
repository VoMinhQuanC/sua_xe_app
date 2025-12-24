// lib/screens/User/notifications/notification_list_screen.dart

import 'package:flutter/material.dart';
import 'package:suaxe_app/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final notifications = await _notificationService.getInAppNotifications();
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    
    if (success) {
      // Reload notifications từ server
      await _loadNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã đánh dấu tất cả là đã đọc'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Không thể đánh dấu đã đọc'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đọc hết',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các thông báo mới sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final notificationId = notification['NotificationID'] ?? notification['notificationId'];
    final title = notification['Title'] ?? notification['title'] ?? '';
    final message = notification['Message'] ?? notification['message'] ?? '';
    final type = notification['Type'] ?? notification['type'] ?? 'general';
    final isRead = notification['IsRead'] == 1 || notification['isRead'] == true;
    final createdAt = notification['CreatedAt'] ?? notification['createdAt'];
    
    // Parse time
    String timeAgo = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final diff = now.difference(date);
        
        if (diff.inDays > 0) {
          timeAgo = '${diff.inDays} ngày trước';
        } else if (diff.inHours > 0) {
          timeAgo = '${diff.inHours} giờ trước';
        } else if (diff.inMinutes > 0) {
          timeAgo = '${diff.inMinutes} phút trước';
        } else {
          timeAgo = 'Vừa xong';
        }
      } catch (e) {
        timeAgo = '';
      }
    }

    // Icon theo type
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'appointment':
      case 'booking':
        icon = Icons.event_note;
        iconColor = Colors.blue;
        break;
      case 'payment':
        icon = Icons.payment;
        iconColor = Colors.green;
        break;
      case 'reminder':
        icon = Icons.alarm;
        iconColor = Colors.orange;
        break;
      case 'system':
        icon = Icons.info;
        iconColor = Colors.grey;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.redAccent;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isRead ? Colors.white : Colors.blue.shade50,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Đánh dấu đã đọc
          if (!isRead) {
            final success = await _notificationService.markAsRead(notificationId);
            
            if (success) {
              // Reload toàn bộ list từ server
              await _loadNotifications();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã đánh dấu là đã đọc'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Không thể đánh dấu đã đọc'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
          
          // TODO: Navigate to detail page based on type
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (timeAgo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}