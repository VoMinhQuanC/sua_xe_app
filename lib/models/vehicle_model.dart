class VehicleModel {
  final int? vehicleId;
  final int userId;
  final String licensePlate;
  final String? brand;
  final String? model;
  final int? year;
  final DateTime? createdAt;

  VehicleModel({
    this.vehicleId,
    required this.userId,
    required this.licensePlate,
    this.brand,
    this.model,
    this.year,
    this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleId: json['VehicleID'] ?? json['vehicleId'],
      userId: json['UserID'] ?? json['userId'],
      licensePlate: json['LicensePlate'] ?? json['licensePlate'] ?? '',
      brand: json['Brand'] ?? json['brand'],
      model: json['Model'] ?? json['model'],
      year: json['Year'] ?? json['year'],
      createdAt: json['CreatedAt'] != null 
          ? DateTime.parse(json['CreatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'userId': userId,
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'year': year,
    };
  }

  String get displayName {
    if (brand != null && model != null) {
      return '$brand $model';
    } else if (brand != null) {
      return brand!;
    } else if (model != null) {
      return model!;
    }
    return licensePlate;
  }
}