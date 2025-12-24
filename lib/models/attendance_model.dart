class AttendanceModel {
  final int? attendanceId;
  final int? mechanicId;  // ✅ Make optional for flat response
  final DateTime? attendanceDate;  // ✅ Make optional for flat response
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? status;
  
  // Schedule info
  final int? scheduleId;
  final String? scheduledStartTime; // TIME format: "08:00:00"
  final String? scheduledEndTime;
  final double? scheduledWorkHours;
  
  // Work hours
  final double? actualWorkHours;
  final double? overtimeHours;
  
  // Location
  final double? checkInLatitude;
  final double? checkInLongitude;
  final String? checkInAddress;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkOutAddress;
  
  final String? notes;
  
  AttendanceModel({
    this.attendanceId,
    this.mechanicId,  // ✅ No longer required
    this.attendanceDate,  // ✅ No longer required
    this.checkInTime,
    this.checkOutTime,
    this.status,
    this.scheduleId,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.scheduledWorkHours,
    this.actualWorkHours,
    this.overtimeHours,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInAddress,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutAddress,
    this.notes,
  });
  
  // ✅ UPDATED: Handle both flat and nested response formats
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    try {
      return AttendanceModel(
        // ✅ Handle both field name variations
        attendanceId: json['AttendanceID'] ?? json['attendanceId'],
        mechanicId: json['MechanicID'] ?? json['mechanicId'],
        
        // ✅ Handle date - might be AttendanceDate or Date or missing (flat response)
        attendanceDate: _parseDateTime(json['AttendanceDate'] ?? json['Date'] ?? json['date']),
        
        // ✅ Handle checkInTime - both uppercase and lowercase
        checkInTime: _parseDateTime(json['checkInTime'] ?? json['CheckInTime']),
        
        // ✅ Handle checkOutTime
        checkOutTime: _parseDateTime(json['checkOutTime'] ?? json['CheckOutTime']),
        
        // ✅ Status - both cases
        status: json['Status'] ?? json['status'],
        
        // ✅ Schedule info
        scheduleId: json['ScheduleID'] ?? json['scheduleId'],
        scheduledStartTime: json['ScheduledStartTime'] ?? json['scheduledStartTime'],
        scheduledEndTime: json['ScheduledEndTime'] ?? json['scheduledEndTime'],
        scheduledWorkHours: _parseDouble(json['ScheduledWorkHours'] ?? json['scheduledWorkHours']),
        
        // ✅ Work hours
        actualWorkHours: _parseDouble(json['ActualWorkHours'] ?? json['actualWorkHours']),
        overtimeHours: _parseDouble(json['OvertimeHours'] ?? json['overtimeHours']),
        
        // ✅ Location
        checkInLatitude: _parseDouble(json['CheckInLatitude'] ?? json['checkInLatitude']),
        checkInLongitude: _parseDouble(json['CheckInLongitude'] ?? json['checkInLongitude']),
        checkInAddress: json['CheckInAddress'] ?? json['checkInAddress'],
        checkOutLatitude: _parseDouble(json['CheckOutLatitude'] ?? json['checkOutLatitude']),
        checkOutLongitude: _parseDouble(json['CheckOutLongitude'] ?? json['checkOutLongitude']),
        checkOutAddress: json['CheckOutAddress'] ?? json['checkOutAddress'],
        
        // ✅ Notes
        notes: json['Notes'] ?? json['notes'],
      );
    } catch (e) {
      print('❌ Error parsing AttendanceModel: $e');
      print('❌ JSON: $json');
      rethrow;
    }
  }

  // ✅ Helper: Parse DateTime safely
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is DateTime) {
        return value;
      }
      return null;
    } catch (e) {
      print('⚠️ Error parsing DateTime: $value, error: $e');
      return null;
    }
  }

  // ✅ Helper: Parse double safely
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is double) {
        return value;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value);
      }
      return null;
    } catch (e) {
      print('⚠️ Error parsing double: $value, error: $e');
      return null;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'AttendanceID': attendanceId,
      'MechanicID': mechanicId,
      'AttendanceDate': attendanceDate?.toIso8601String(),
      'CheckInTime': checkInTime?.toIso8601String(),
      'CheckOutTime': checkOutTime?.toIso8601String(),
      'Status': status,
      'ScheduleID': scheduleId,
      'ScheduledStartTime': scheduledStartTime,
      'ScheduledEndTime': scheduledEndTime,
      'ScheduledWorkHours': scheduledWorkHours,
      'ActualWorkHours': actualWorkHours,
      'OvertimeHours': overtimeHours,
      'CheckInLatitude': checkInLatitude,
      'CheckInLongitude': checkInLongitude,
      'CheckInAddress': checkInAddress,
      'CheckOutLatitude': checkOutLatitude,
      'CheckOutLongitude': checkOutLongitude,
      'CheckOutAddress': checkOutAddress,
      'Notes': notes,
    };
  }
  
  // Helper getters
  String get statusText {
    switch (status) {
      case 'Late':
        return 'Đi muộn';
      case 'Present':
      case 'OnTime':
        return 'Đúng giờ';
      case 'Absent':
        return 'Vắng';
      default:
        return status ?? 'Không xác định';
    }
  }
  
  bool get isLate => status == 'Late';
  bool get isPresent => status == 'Present' || status == 'OnTime' || checkInTime != null;
  bool get hasOvertime => overtimeHours != null && overtimeHours! > 0;
}