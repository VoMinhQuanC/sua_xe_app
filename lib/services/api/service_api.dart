// lib/services/api/service_api.dart

import 'package:dio/dio.dart';
import 'api_service.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// Service Model - Simple version
class ServiceModel {
  final int? serviceId;
  final String serviceName;
  final double? price;
  final String? serviceImage;
  final String? description;

  ServiceModel({
    this.serviceId,
    required this.serviceName,
    this.price,
    this.serviceImage,
    this.description,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['ServiceId'],
      serviceName: json['ServiceName'] ?? '',
      price: json['Price']?.toDouble(),
      serviceImage: json['ServiceImage'],
      description: json['Description'],
    );
  }

  String get formattedPrice {
    if (price == null) return '0 ₫';
    return '${price!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} ₫';
  }
}

/// Service API - Xử lý tất cả API calls về dịch vụ
class ServiceApi {
  final ApiService _apiService;

  ServiceApi({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  /// Lấy tất cả dịch vụ
  Future<ApiResponse<List<ServiceModel>>> getAllServices() async {
    try {
      final response = await _apiService.getServices();

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['success'] == true) {
          final List<dynamic> servicesJson = data['services'] ?? [];
          final List<ServiceModel> services = servicesJson
              .map((json) => ServiceModel.fromJson(json))
              .toList();
          
          return ApiResponse.success(services);
        } else {
          return ApiResponse.error(
            data['message'] ?? 'Không thể tải dịch vụ',
          );
        }
      } else {
        return ApiResponse.error(
          'Lỗi server: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Lấy chi tiết dịch vụ
  Future<ApiResponse<ServiceModel>> getServiceById(int serviceId) async {
    try {
      // SỬA: Gọi qua ApiService thay vì truy cập _dio trực tiếp
      final response = await _apiService.getServiceById(serviceId);

      if (response.statusCode == 200) {
        final service = ServiceModel.fromJson(response.data);
        return ApiResponse.success(service);
      } else {
        return ApiResponse.error(
          'Không tìm thấy dịch vụ',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('Lỗi: ${e.toString()}');
    }
  }

  /// Tìm kiếm dịch vụ
  Future<ApiResponse<List<ServiceModel>>> searchServices(
    String keyword,
  ) async {
    try {
      final response = await getAllServices();
      
      if (response.success && response.data != null) {
        final filteredServices = response.data!
            .where((service) =>
                service.serviceName
                    .toLowerCase()
                    .contains(keyword.toLowerCase()))
            .toList();
        
        return ApiResponse.success(filteredServices);
      } else {
        return response;
      }
    } catch (e) {
      return ApiResponse.error('Lỗi tìm kiếm: ${e.toString()}');
    }
  }

  /// Lọc theo giá
  Future<ApiResponse<List<ServiceModel>>> filterByPrice(
    double? minPrice,
    double? maxPrice,
  ) async {
    try {
      final response = await getAllServices();
      
      if (response.success && response.data != null) {
        final filteredServices = response.data!.where((service) {
          if (service.price == null) return false;
          
          final price = service.price!;
          final passMin = minPrice == null || price >= minPrice;
          final passMax = maxPrice == null || price <= maxPrice;
          
          return passMin && passMax;
        }).toList();
        
        return ApiResponse.success(filteredServices);
      } else {
        return response;
      }
    } catch (e) {
      return ApiResponse.error('Lỗi lọc: ${e.toString()}');
    }
  }

  /// Sắp xếp dịch vụ
  List<ServiceModel> sortServices(
    List<ServiceModel> services, {
    required SortType sortType,
  }) {
    final sortedList = List<ServiceModel>.from(services);
    
    switch (sortType) {
      case SortType.nameAsc:
        sortedList.sort((a, b) => a.serviceName.compareTo(b.serviceName));
        break;
      case SortType.nameDesc:
        sortedList.sort((a, b) => b.serviceName.compareTo(a.serviceName));
        break;
      case SortType.priceAsc:
        sortedList.sort((a, b) {
          if (a.price == null) return 1;
          if (b.price == null) return -1;
          return a.price!.compareTo(b.price!);
        });
        break;
      case SortType.priceDesc:
        sortedList.sort((a, b) {
          if (a.price == null) return 1;
          if (b.price == null) return -1;
          return b.price!.compareTo(a.price!);
        });
        break;
    }
    
    return sortedList;
  }

  /// Handle Dio errors
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Kết nối quá lâu';
      case DioExceptionType.sendTimeout:
        return 'Gửi dữ liệu quá lâu';
      case DioExceptionType.receiveTimeout:
        return 'Nhận dữ liệu quá lâu';
      case DioExceptionType.badResponse:
        return 'Lỗi server: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy';
      case DioExceptionType.connectionError:
        return 'Không có kết nối internet';
      default:
        return 'Lỗi: ${e.message}';
    }
  }
}

/// Sort types
enum SortType {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
}