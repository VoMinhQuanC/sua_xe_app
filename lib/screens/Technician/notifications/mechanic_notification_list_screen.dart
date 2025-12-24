// lib/screens/Technician/notifications/mechanic_notification_list_screen.dart
// ✅ ENHANCED VERSION - Full features

import 'package:flutter/material.dart';
import 'package:suaxe_app/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:suaxe_app/screens/Technician/technician_schedule_screen.dart';
import 'package:suaxe_app/screens/Technician/technician_task_detail_screen.dart';

class MechanicNotificationListScreen extends StatefulWidget {
  const MechanicNotificationListScreen({super.key});

  @override
  State<MechanicNotificationListScreen> createState() => _MechanicNotificationListScreenState();
}

class _MechanicNotificationListScreenState extends State<MechanicNotificationListScreen> {
  final _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _allNotifications = [];
  bool _isLoading = true;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final notifications = await _notificationService.getInAppNotifications();
      
      if (mounted) {
        setState(() {
          _allNotifications = notifications;
          _applyFilter();
        });
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải thông báo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    if (_showUnreadOnly) {
      _notifications = _allNotifications.where((n) {
        final isRead = n['IsRead'] == 1 || n['isRead'] == true;
        return !isRead;
      }).toList();
    } else {
      _notifications = List.from(_allNotifications);
    }
  }

  void _toggleFilter() {
    setState(() {
      _showUnreadOnly = !_showUnreadOnly;
      _applyFilter();
    });
  }

  Future<void> _markAllAsRead() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Đánh dấu tất cả thông báo đã đọc?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    final success = await _notificationService.markAllAsRead();
    
    if (success && mounted) {
      // Update all notifications to read
      for (var notification in _allNotifications) {
        notification['IsRead'] = 1;
        notification['isRead'] = true;
      }
      
      setState(() {
        _applyFilter();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả đã đọc'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
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
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Filter toggle
          IconButton(
            icon: Icon(
              _showUnreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            onPressed: _toggleFilter,
            tooltip: _showUnreadOnly ? 'Hiện tất cả' : 'Chỉ chưa đọc',
          ),
          
          // Mark all as read
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              onPressed: _markAllAsRead,
              tooltip: 'Đánh dấu tất cả đã đọc',
            ),
          
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadNotifications,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: Colors.orange,
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
            _showUnreadOnly 
                ? Icons.mark_email_read
                : Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _showUnreadOnly
                ? 'Không có thông báo chưa đọc'
                : 'Chưa có thông báo',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showUnreadOnly
                ? 'Tất cả thông báo đã được đọc'
                : 'Các thông báo mới sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
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
    final referenceId = notification['ReferenceID'] ?? notification['referenceId'] ?? notification['RelatedID'];
    
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

    // Icon and color based on type
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'schedule':
      case 'work_schedule':
        icon = Icons.calendar_today;
        iconColor = isRead ? Colors.blue : Colors.orange;
        break;
        
      case 'appointment':
      case 'new_appointment':
      case 'appointment_assigned':
        icon = Icons.assignment;
        iconColor = isRead ? Colors.green : Colors.orange;
        break;
        
      case 'leave_request':
      case 'leave_approved':
      case 'leave_rejected':
      case 'leave_response':
        icon = Icons.event_busy;
        iconColor = type.contains('approved') ? Colors.green : 
                   type.contains('rejected') ? Colors.red : 
                   isRead ? Colors.purple : Colors.orange;
        break;
        
      case 'schedule_update':
      case 'schedule_change':
        icon = Icons.update;
        iconColor = isRead ? Colors.purple : Colors.orange;
        break;
        
      case 'reminder':
      case 'work_reminder':
        icon = Icons.alarm;
        iconColor = Colors.orange;
        break;
        
      case 'system':
        icon = Icons.info;
        iconColor = isRead ? Colors.grey : Colors.orange;
        break;
        
      default:
        icon = Icons.notifications;
        iconColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isRead ? Colors.white : Colors.orange.shade50,
      elevation: isRead ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Mark as read
          if (!isRead) {
            await _notificationService.markAsRead(notificationId);
            setState(() {
              notification['IsRead'] = 1;
              notification['isRead'] = true;
            });
          }
          
          // Handle navigation
          if (mounted) {
            _handleNotificationTap(type, referenceId);
          }
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
                              color: Colors.orange,
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

  /// ✅ HANDLE NAVIGATION WITH ACTUAL SCREENS
  void _handleNotificationTap(String type, dynamic referenceId) {
    print('🔔 Notification tap: type=$type, ref=$referenceId');
    
    switch (type) {
      case 'schedule':
      case 'work_schedule':
      case 'schedule_update':
      case 'schedule_change':
        // Navigate to schedule screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TechnicianScheduleScreen(),
          ),
        );
        break;
        
      case 'appointment':
      case 'new_appointment':
      case 'appointment_assigned':
        // Navigate to appointment detail
        if (referenceId != null) {
          final appointmentId = referenceId is int ? referenceId : int.tryParse(referenceId.toString());
          
          if (appointmentId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TechnicianTaskDetailScreen(
                  appointmentId: appointmentId,
                ),
              ),
            );
          } else {
            _showErrorSnackbar('ID công việc không hợp lệ');
          }
        } else {
          _showErrorSnackbar('Không tìm thấy ID công việc');
        }
        break;
        
      case 'leave_request':
      case 'leave_approved':
      case 'leave_rejected':
      case 'leave_response':
        // Navigate to schedule (leave requests tab if exists)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xem chi tiết đơn nghỉ phép trong Lịch làm việc'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TechnicianScheduleScreen(),
          ),
        );
        break;
        
      case 'system':
      case 'general':
      default:
        // Show detail dialog for system/general notifications
        _showNotificationDetail(type);
        break;
    }
  }

  void _showNotificationDetail(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              type == 'system' ? Icons.info : Icons.notifications,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Chi tiết thông báo'),
          ],
        ),
        content: const Text(
          'Đây là thông báo hệ thống. Không có hành động cụ thể.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}