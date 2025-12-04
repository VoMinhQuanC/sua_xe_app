// lib/models/mechanic_schedule_model.dart

class MechanicScheduleModel {
  final int? scheduleId;
  final int mechanicId;
  final String workDate; // YYYY-MM-DD
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String type; // available, unavailable
  final String status; // Pending, Approved, Rejected
  final int isAvailable; // 0 = nghỉ, 1 = làm việc
  final String? notes;
  final String? adminNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Thông tin bổ sung
  final String? mechanicName;

  MechanicScheduleModel({
    this.scheduleId,
    required this.mechanicId,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    this.type = 'available',
    this.status = 'Pending',
    this.isAvailable = 1,
    this.notes,
    this.adminNotes,
    this.createdAt,
    this.updatedAt,
    this.mechanicName,
  });

  factory MechanicScheduleModel.fromJson(Map<String, dynamic> json) {
    return MechanicScheduleModel(
      scheduleId: json['ScheduleID'] ?? json['scheduleId'],
      mechanicId: json['MechanicID'] ?? json['mechanicId'],
      workDate: _extractDate(json['WorkDate'] ?? json['workDate'] ?? ''),
      startTime: _extractTime(json['StartTime'] ?? json['startTime'] ?? json['StartTimeOnly'] ?? ''),
      endTime: _extractTime(json['EndTime'] ?? json['endTime'] ?? json['EndTimeOnly'] ?? ''),
      type: json['Type'] ?? json['type'] ?? 'available',
      status: json['Status'] ?? json['status'] ?? 'Pending',
      isAvailable: json['IsAvailable'] ?? json['isAvailable'] ?? 1,
      notes: json['Notes'] ?? json['notes'],
      adminNotes: json['AdminNotes'] ?? json['adminNotes'],
      createdAt: json['CreatedAt'] != null 
          ? DateTime.parse(json['CreatedAt']) 
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : null,
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.parse(json['UpdatedAt']) 
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : null,
      mechanicName: json['MechanicName'] ?? json['mechanicName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (scheduleId != null) 'ScheduleID': scheduleId,
      'MechanicID': mechanicId,
      'WorkDate': workDate,
      'StartTime': startTime,
      'EndTime': endTime,
      'Type': type,
      'Status': status,
      'IsAvailable': isAvailable,
      if (notes != null) 'Notes': notes,
      if (adminNotes != null) 'AdminNotes': adminNotes,
    };
  }

  /// Helper: Extract date từ ISO string
  /// "2025-12-04T00:00:00.000Z" -> "2025-12-04"
  /// "2025-12-04" -> "2025-12-04"
  static String _extractDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    
    try {
      // Nếu có 'T' hoặc ' ' -> ISO format hoặc datetime
      if (dateStr.contains('T') || dateStr.contains(' ')) {
        final date = DateTime.parse(dateStr);
        // Format YYYY-MM-DD
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      
      // Nếu đã là YYYY-MM-DD
      if (dateStr.length == 10 && dateStr.contains('-')) {
        return dateStr;
      }
      
      // Try parse anyway
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      // Nếu parse fail, return original
      return dateStr;
    }
  }

  /// Helper: Extract time từ format khác nhau
  /// "2025-01-15T08:00:00" -> "08:00"
  /// "08:00:00" -> "08:00"
  /// "08:00" -> "08:00"
  static String _extractTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    
    // Nếu có 'T' -> ISO format
    if (timeStr.contains('T')) {
      final parts = timeStr.split('T');
      if (parts.length > 1) {
        timeStr = parts[1];
      }
    }
    
    // Lấy HH:mm (bỏ seconds)
    final timeParts = timeStr.split(':');
    if (timeParts.length >= 2) {
      return '${timeParts[0]}:${timeParts[1]}';
    }
    
    return timeStr;
  }

  /// Trạng thái tiếng Việt
  String get statusInVietnamese {
    switch (status) {
      case 'Pending':
      case 'PendingEdit':      // ✅ Đơn xin sửa lịch chờ duyệt
      case 'PendingLeave':     // ✅ Đơn xin nghỉ chờ duyệt
        return 'Chờ duyệt';
      case 'Approved':
      case 'ApprovedEdit':     // ✅ Đã duyệt sửa lịch
      case 'ApprovedLeave':    // ✅ Đã duyệt nghỉ
        return 'Đã duyệt';
      case 'Rejected':
      case 'RejectedEdit':     // ✅ Từ chối sửa lịch
      case 'RejectedLeave':    // ✅ Từ chối nghỉ
        return 'Từ chối';
      default:
        return status;
    }
  }

  /// Loại lịch tiếng Việt
  String get typeInVietnamese {
    if (type == 'unavailable' || isAvailable == 0) {
      return 'Xin nghỉ';
    }
    return 'Làm việc';
  }

  /// Màu sắc cho status
  String get statusColor {
    switch (status) {
      case 'Pending':
      case 'PendingEdit':      // ✅ Màu vàng cho chờ duyệt sửa lịch
      case 'PendingLeave':     // ✅ Màu vàng cho chờ duyệt nghỉ
        return '#FF9800'; // Orange/Yellow
      case 'Approved':
      case 'ApprovedEdit':     // ✅ Màu xanh cho đã duyệt
      case 'ApprovedLeave':
        return '#4CAF50'; // Green
      case 'Rejected':
      case 'RejectedEdit':     // ✅ Màu đỏ cho từ chối
      case 'RejectedLeave':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Hiển thị thời gian làm việc
  String get displayTime => '$startTime - $endTime';

  /// Kiểm tra có phải đơn xin nghỉ không
  bool get isLeaveRequest => type == 'unavailable' || isAvailable == 0;

  /// Hiển thị ngày theo định dạng Việt Nam
  String get displayDate {
    try {
      final date = DateTime.parse(workDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return workDate;
    }
  }

  /// Lấy thứ trong tuần
  String get weekday {
    try {
      final date = DateTime.parse(workDate);
      const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return weekdays[date.weekday % 7];
    } catch (e) {
      return '';
    }
  }

  /// Copy với các giá trị mới
  MechanicScheduleModel copyWith({
    int? scheduleId,
    int? mechanicId,
    String? workDate,
    String? startTime,
    String? endTime,
    String? type,
    String? status,
    int? isAvailable,
    String? notes,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mechanicName,
  }) {
    return MechanicScheduleModel(
      scheduleId: scheduleId ?? this.scheduleId,
      mechanicId: mechanicId ?? this.mechanicId,
      workDate: workDate ?? this.workDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mechanicName: mechanicName ?? this.mechanicName,
    );
  }
}