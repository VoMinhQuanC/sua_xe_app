// lib/models/mechanic_notification_model.dart

class MechanicNotificationModel {
  final int notificationId;
  final int userId;
  final String title;
  final String message;
  final String type; // schedule, appointment, system, general, leave_request, leave_response
  final int? referenceId; // ID của lịch hẹn hoặc lịch làm việc
  final bool isRead;
  final DateTime createdAt;

  MechanicNotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory MechanicNotificationModel.fromJson(Map<String, dynamic> json) {
    return MechanicNotificationModel(
      notificationId: json['NotificationID'] ?? json['notificationId'],
      userId: json['UserID'] ?? json['userId'],
      title: json['Title'] ?? json['title'] ?? '',
      message: json['Message'] ?? json['message'] ?? '',
      type: json['Type'] ?? json['type'] ?? 'general',
      referenceId: json['ReferenceID'] ?? json['referenceId'],
      isRead: json['IsRead'] == 1 || json['isRead'] == true,
      createdAt: DateTime.parse(json['CreatedAt'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NotificationID': notificationId,
      'UserID': userId,
      'Title': title,
      'Message': message,
      'Type': type,
      if (referenceId != null) 'ReferenceID': referenceId,
      'IsRead': isRead ? 1 : 0,
      'CreatedAt': createdAt.toIso8601String(),
    };
  }

  /// Loại thông báo tiếng Việt
  String get typeInVietnamese {
    switch (type) {
      case 'schedule':
        return 'Lịch làm việc';
      case 'appointment':
        return 'Lịch hẹn';
      case 'leave_request':
        return 'Đơn xin nghỉ';
      case 'leave_response':
        return 'Phản hồi nghỉ phép';
      case 'system':
        return 'Hệ thống';
      default:
        return 'Thông báo';
    }
  }

  /// Icon cho từng loại thông báo
  String get iconName {
    switch (type) {
      case 'schedule':
        return 'calendar';
      case 'appointment':
        return 'calendar_check';
      case 'leave_request':
      case 'leave_response':
        return 'event_busy';
      case 'system':
        return 'info';
      default:
        return 'notifications';
    }
  }

  /// Màu sắc cho từng loại
  String get color {
    if (!isRead) {
      return '#2196F3'; // Blue - chưa đọc
    }
    
    switch (type) {
      case 'schedule':
        return '#4CAF50'; // Green
      case 'appointment':
        return '#FF9800'; // Orange
      case 'leave_request':
        return '#F44336'; // Red
      case 'leave_response':
        return '#9C27B0'; // Purple
      case 'system':
        return '#607D8B'; // Blue Grey
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Hiển thị thời gian tương đối
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Hiển thị ngày giờ đầy đủ
  String get formattedDateTime {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Copy với giá trị mới
  MechanicNotificationModel copyWith({
    int? notificationId,
    int? userId,
    String? title,
    String? message,
    String? type,
    int? referenceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MechanicNotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Đánh dấu đã đọc
  MechanicNotificationModel markAsRead() {
    return copyWith(isRead: true);
  }
}