// lib/models/mechanic_model.dart

class MechanicModel {
  final int mechanicId;
  final String fullName;
  final String? phoneNumber;
  final String? specialization;
  final bool isAvailable;
  final String? avatarUrl;
  final DateTime? estimatedEndTime;

  MechanicModel({
    required this.mechanicId,
    required this.fullName,
    this.phoneNumber,
    this.specialization,
    this.isAvailable = true,
    this.avatarUrl,
    this.estimatedEndTime,
  });

  factory MechanicModel.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: Nếu không có IsAvailable, mặc định là TRUE (có sẵn)
    bool available = true;
    
    if (json.containsKey('IsAvailable')) {
      available = json['IsAvailable'] == 1 || json['IsAvailable'] == true;
    } else if (json.containsKey('isAvailable')) {
      available = json['isAvailable'] == 1 || json['isAvailable'] == true;
    }
    // Nếu không có cả 2 trường → mặc định true
    
    return MechanicModel(
      mechanicId: json['MechanicID'] ?? json['mechanicId'] ?? json['UserID'] ?? json['userId'],
      fullName: json['FullName'] ?? json['fullName'] ?? json['MechanicName'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? json['phoneNumber'],
      specialization: json['Specialization'] ?? json['specialization'],
      isAvailable: available,
      avatarUrl: json['AvatarUrl'] ?? json['avatarUrl'],
      estimatedEndTime: json['EstimatedEndTime'] != null 
          ? DateTime.parse(json['EstimatedEndTime'])
          : json['estimatedEndTime'] != null
              ? DateTime.parse(json['estimatedEndTime'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MechanicID': mechanicId,
      'FullName': fullName,
      'PhoneNumber': phoneNumber,
      'Specialization': specialization,
      'IsAvailable': isAvailable ? 1 : 0,
      'AvatarUrl': avatarUrl,
      'EstimatedEndTime': estimatedEndTime?.toIso8601String(),
    };
  }

  String get statusText => isAvailable ? 'Có sẵn' : 'Đang bận';
  
  String get estimatedEndTimeText {
    if (estimatedEndTime == null) return '';
    final now = DateTime.now();
    final diff = estimatedEndTime!.difference(now);
    
    if (diff.inMinutes < 60) {
      return 'Kết thúc dự kiến: ${diff.inMinutes} phút nữa';
    } else {
      return 'Kết thúc dự kiến: ${estimatedEndTime!.hour}:${estimatedEndTime!.minute.toString().padLeft(2, '0')}';
    }
  }
}