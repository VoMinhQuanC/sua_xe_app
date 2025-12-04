class BookingModel {
  final int? appointmentId;
  final int? userId;
  final int? vehicleId;
  final DateTime appointmentDate;
  final String status;
  final String? notes;
  final int? mechanicId;
  final int? serviceDuration;
  final DateTime? estimatedEndTime;
  final bool isDeleted;
  
  // Thông tin bổ sung từ JOIN
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? licensePlate;
  final String? brand;
  final String? model;
  final int? year;
  final String? mechanicName;
  final String? services; // Danh sách dịch vụ cách nhau bởi dấu phẩy
  
  // Danh sách chi tiết dịch vụ
  final List<BookingServiceDetail>? serviceDetails;

  BookingModel({
    this.appointmentId,
    this.userId,
    this.vehicleId,
    required this.appointmentDate,
    required this.status,
    this.notes,
    this.mechanicId,
    this.serviceDuration,
    this.estimatedEndTime,
    this.isDeleted = false,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.licensePlate,
    this.brand,
    this.model,
    this.year,
    this.mechanicName,
    this.services,
    this.serviceDetails,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      appointmentId: json['AppointmentID'] ?? json['appointmentId'],
      userId: json['UserID'] ?? json['userId'],
      vehicleId: json['VehicleID'] ?? json['vehicleId'],
      appointmentDate: DateTime.parse(json['AppointmentDate'] ?? json['appointmentDate']),
      status: json['Status'] ?? json['status'] ?? 'Pending',
      notes: json['Notes'] ?? json['notes'],
      mechanicId: json['MechanicID'] ?? json['mechanicId'],
      serviceDuration: json['ServiceDuration'] ?? json['serviceDuration'],
      estimatedEndTime: json['EstimatedEndTime'] != null 
          ? DateTime.parse(json['EstimatedEndTime']) 
          : json['estimatedEndTime'] != null 
              ? DateTime.parse(json['estimatedEndTime'])
              : null,
      isDeleted: json['IsDeleted'] == 1 || json['isDeleted'] == true,
      fullName: json['FullName'] ?? json['fullName'],
      email: json['Email'] ?? json['email'],
      phoneNumber: json['PhoneNumber'] ?? json['phoneNumber'],
      licensePlate: json['LicensePlate'] ?? json['licensePlate'],
      brand: json['Brand'] ?? json['brand'],
      model: json['Model'] ?? json['model'],
      year: json['Year'] ?? json['year'],
      mechanicName: json['MechanicName'] ?? json['mechanicName'],
      services: json['Services'] is List
        ? (json['Services'] as List).join(', ')
        : json['services'] is List
            ? (json['services'] as List).join(', ')
            : json['Services'] ?? json['services'],
      serviceDetails: json['serviceDetails'] != null
          ? (json['serviceDetails'] as List)
              .map((e) => BookingServiceDetail.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AppointmentID': appointmentId,
      'UserID': userId,
      'VehicleID': vehicleId,
      'AppointmentDate': appointmentDate.toIso8601String(),
      'Status': status,
      'Notes': notes,
      'MechanicID': mechanicId,
      'ServiceDuration': serviceDuration,
      'EstimatedEndTime': estimatedEndTime?.toIso8601String(),
      'IsDeleted': isDeleted ? 1 : 0,
    };
  }

  // Helper để lấy trạng thái tiếng Việt
  String get statusInVietnamese {
    switch (status) {
      case 'Pending':
        return 'Chờ xác nhận';
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'Completed':
        return 'Hoàn thành';
      case 'Cancelled':
      case 'Canceled':  
        return 'Đã hủy';
      default:
        return status;
    }
  }

  // Helper để lấy màu trạng thái
  String get statusColor {
    switch (status) {
      case 'Pending':
        return '#FF9800'; // Cam đậm
      case 'Confirmed':
        return '#4CAF50'; // Xanh lá
      case 'Completed':
        return '#00897B'; // Xanh ngọc Material
      case 'Cancelled':
      case 'Canceled':
        return '#E53935'; // Đỏ đậm
      default:
        return '#757575'; // Xám đậm
    }
  }
}

class BookingServiceDetail {
  final int? appointmentServiceId;
  final int? appointmentId;
  final int serviceId;
  final int quantity;
  final String? serviceName;
  final double? price;
  final int? estimatedTime;

  BookingServiceDetail({
    this.appointmentServiceId,
    this.appointmentId,
    required this.serviceId,
    this.quantity = 1,
    this.serviceName,
    this.price,
    this.estimatedTime,
  });

  factory BookingServiceDetail.fromJson(Map<String, dynamic> json) {
    return BookingServiceDetail(
      appointmentServiceId: json['AppointmentServiceID'] ?? json['appointmentServiceId'],
      appointmentId: json['AppointmentID'] ?? json['appointmentId'],
      serviceId: json['ServiceID'] ?? json['serviceId'],
      quantity: json['Quantity'] ?? json['quantity'] ?? 1,
      serviceName: json['ServiceName'] ?? json['serviceName'],
      price: json['Price'] != null ? double.parse(json['Price'].toString()) : null,
      estimatedTime: json['EstimatedTime'] ?? json['estimatedTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AppointmentServiceID': appointmentServiceId,
      'AppointmentID': appointmentId,
      'ServiceID': serviceId,
      'Quantity': quantity,
    };
  }

  double get totalPrice => (price ?? 0) * quantity;
}

class CreateBookingRequest {
  final int userId;
  final int? vehicleId;
  final String? licensePlate;
  final String? brand;
  final String? model;
  final int? year;
  final DateTime appointmentDate;
  final String? notes;
  final List<int> serviceIds;

  CreateBookingRequest({
    required this.userId,
    this.vehicleId,
    this.licensePlate,
    this.brand,
    this.model,
    this.year,
    required this.appointmentDate,
    this.notes,
    required this.serviceIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'year': year,
      'appointmentDate': appointmentDate.toIso8601String(),
      'notes': notes,
      'serviceIds': serviceIds,
    };
  }
}

class Vehicle {
  final int? vehicleId;
  final int? userId;
  final String licensePlate;
  final String brand;
  final String model;
  final int? year;

  Vehicle({
    this.vehicleId,
    this.userId,
    required this.licensePlate,
    required this.brand,
    required this.model,
    this.year,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['VehicleID'] ?? json['vehicleId'],
      userId: json['UserID'] ?? json['userId'],
      licensePlate: json['LicensePlate'] ?? json['licensePlate'] ?? '',
      brand: json['Brand'] ?? json['brand'] ?? '',
      model: json['Model'] ?? json['model'] ?? '',
      year: json['Year'] ?? json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleID': vehicleId,
      'userID': userId,
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'year': year,
    };
  }

  String get displayName => '$brand $model${year != null ? " ($year)" : ""}';
}