// lib/models/service_model.dart

/// Service Model
class ServiceModel {
  final int? serviceId;
  final String serviceName;
  final double? price;
  final String? serviceImage;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceModel({
    this.serviceId,
    required this.serviceName,
    this.price,
    this.serviceImage,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  /// From JSON
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['ServiceId'],
      serviceName: json['ServiceName'] ?? '',
      price: json['Price']?.toDouble(),
      serviceImage: json['ServiceImage'],
      description: json['Description'],
      createdAt: json['CreatedAt'] != null 
          ? DateTime.parse(json['CreatedAt']) 
          : null,
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.parse(json['UpdatedAt']) 
          : null,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'ServiceId': serviceId,
      'ServiceName': serviceName,
      'Price': price,
      'ServiceImage': serviceImage,
      'Description': description,
      'CreatedAt': createdAt?.toIso8601String(),
      'UpdatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Format giá tiền
  String get formattedPrice {
    if (price == null) return '0 ₫';
    return '${price!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} ₫';
  }

  /// Copy with
  ServiceModel copyWith({
    int? serviceId,
    String? serviceName,
    double? price,
    String? serviceImage,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      price: price ?? this.price,
      serviceImage: serviceImage ?? this.serviceImage,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ServiceModel(id: $serviceId, name: $serviceName, price: $price)';
  }
}