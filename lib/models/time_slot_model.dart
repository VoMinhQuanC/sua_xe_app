// lib/models/time_slot_model.dart

class TimeSlotModel {
  final String time; // Format: "09:00"
  final bool isAvailable;
  final int availableMechanics;

  TimeSlotModel({
    required this.time,
    required this.isAvailable,
    this.availableMechanics = 0,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      time: json['time'] ?? json['Time'] ?? '',
      isAvailable: json['isAvailable'] ?? json['IsAvailable'] ?? true,
      availableMechanics: json['availableMechanics'] ?? json['AvailableMechanics'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'isAvailable': isAvailable,
      'availableMechanics': availableMechanics,
    };
  }

  // Lấy giờ từ time string (09:00 -> 9)
  int get hour {
    try {
      return int.parse(time.split(':')[0]);
    } catch (e) {
      return 0;
    }
  }

  // Lấy phút từ time string (09:00 -> 0)
  int get minute {
    try {
      return int.parse(time.split(':')[1]);
    } catch (e) {
      return 0;
    }
  }

  // Hiển thị text cho khung giờ
  String get displayText => time;
}