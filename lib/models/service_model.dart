class ServiceModel {
  final int serviceId;
  final String serviceName;
  final String? description;
  final double price;
  final int estimatedTime; // Thời gian ước tính (phút)
  final String? imageUrl;
  final bool isActive;

  ServiceModel({
    required this.serviceId,
    required this.serviceName,
    this.description,
    required this.price,
    required this.estimatedTime,
    this.imageUrl,
    this.isActive = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['ServiceID'] ?? json['serviceId'],
      serviceName: json['ServiceName'] ?? json['serviceName'] ?? '',
      description: json['Description'] ?? json['description'],
      price: json['Price'] != null 
          ? double.parse(json['Price'].toString()) 
          : 0.0,
      estimatedTime: json['EstimatedTime'] ?? json['estimatedTime'] ?? 0,
      imageUrl: json['ServiceImage'] ?? json['ImageUrl'] ?? json['imageUrl'],
      isActive: json['IsActive'] == 1 || json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ServiceID': serviceId,
      'ServiceName': serviceName,
      'Description': description,
      'Price': price,
      'EstimatedTime': estimatedTime,
      'ImageUrl': imageUrl,
      'IsActive': isActive ? 1 : 0,
    };
  }

  // Format giá tiền sang VND
  String get formattedPrice {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}đ';
  }

  // Format thời gian
  String get formattedTime {
    if (estimatedTime < 60) {
      return '$estimatedTime phút';
    } else {
      final hours = estimatedTime ~/ 60;
      final minutes = estimatedTime % 60;
      if (minutes == 0) {
        return '$hours giờ';
      }
      return '$hours giờ $minutes phút';
    }
  }
}

class ServiceCategory {
  final int categoryId;
  final String categoryName;
  final String? description;
  final List<ServiceModel> services;

  ServiceCategory({
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.services = const [],
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      categoryId: json['CategoryID'] ?? json['categoryId'],
      categoryName: json['CategoryName'] ?? json['categoryName'] ?? '',
      description: json['Description'] ?? json['description'],
      services: json['services'] != null
          ? (json['services'] as List)
              .map((service) => ServiceModel.fromJson(service))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CategoryID': categoryId,
      'CategoryName': categoryName,
      'Description': description,
      'services': services.map((s) => s.toJson()).toList(),
    };
  }
}