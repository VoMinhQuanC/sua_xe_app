import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:suaxe_app/models/booking_model.dart';
import 'package:suaxe_app/models/service_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BookingApiService {
  // ✅ FIX 1: Đổi URL sang suaxe-api-2
  static const String baseUrl = 'https://suaxe-api-2.as.r.appspot.com';
  
  static const _secureStorage = FlutterSecureStorage();
  
  static Future<String?> _getAuthToken() async {
    try {
      return await _secureStorage.read(key: 'access_token');
    } catch (e) {
      print('Lỗi khi lấy token: $e');
      return null;
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============ SERVICES API ============
  
  /// Lấy danh sách tất cả dịch vụ
  static Future<List<ServiceModel>> getAllServices() async {
    try {
      print('🔍 Đang tải danh sách dịch vụ...');
      print('🔍 URL: $baseUrl/api/services');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/services'),
        headers: headers,
      );

      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List servicesList = data['services'] ?? data['data'] ?? [];
          print('✅ Tải thành công ${servicesList.length} dịch vụ');
          return servicesList.map((json) => ServiceModel.fromJson(json)).toList();
        }
      }
      throw Exception('API trả về không thành công: ${response.statusCode}');
    } catch (e) {
      print('❌ Lỗi khi tải dịch vụ: $e');
      throw Exception('Lỗi khi tải dịch vụ: $e');
    }
  }

  /// Lấy thông tin chi tiết một dịch vụ
  static Future<ServiceModel> getServiceById(int serviceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/services/$serviceId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ServiceModel.fromJson(data['data'] ?? data['service']);
        }
      }
      throw Exception('Không thể tải thông tin dịch vụ');
    } catch (e) {
      throw Exception('Lỗi khi tải dịch vụ: $e');
    }
  }

  // ============ VEHICLES API ============
  
  /// Lấy danh sách xe của user
  static Future<List<Vehicle>> getUserVehicles(int userId) async {
    try {
      print('🔍 Đang tải danh sách xe cho userId: $userId');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/vehicles/user'), // Bỏ /$userId
        headers: headers,
      );

      print('📩 Vehicles Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List vehiclesList = data['vehicles'] ?? data['data'] ?? [];
          print('✅ Tải thành công ${vehiclesList.length} xe');
          return vehiclesList.map((json) => Vehicle.fromJson(json)).toList();
        }
      }
      
      // Nếu không có xe, trả về list rỗng
      if (response.statusCode == 200) {
        print('ℹ️ User chưa có xe nào');
        return [];
      }
      
      throw Exception('Không thể tải danh sách xe');
    } catch (e) {
      print('❌ Lỗi khi tải xe: $e');
      return [];
    }
  }
  
  /// Thêm xe mới
  static Future<Vehicle> addVehicle(Vehicle request) async {
    try {
      print('🔍 Đang thêm xe mới...');
      print('🔍 Vehicle data: ${request.toJson()}');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/vehicles'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      print('📩 Add vehicle response: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Thêm xe thành công');
          
          // ✅ FIX: Tạo Vehicle object từ request + vehicleId từ response
          return Vehicle(
            vehicleId: data['vehicleId'],  // Lấy từ backend response
            userId: request.userId,        // Lấy từ request
            licensePlate: request.licensePlate,
            brand: request.brand,
            model: request.model,
            year: request.year,
          );
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể thêm xe');
    } catch (e) {
      print('❌ Lỗi khi thêm xe: $e');
      throw Exception('Lỗi khi thêm xe: $e');
    }
  }


  static Future<void> deleteVehicle(int vehicleId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/vehicles/$vehicleId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) throw Exception('Cannot delete');
  }

  // ============ BOOKING/APPOINTMENTS API ============
  
  /// Lấy danh sách lịch hẹn
  static Future<List<BookingModel>> getAppointments({
    String? dateFrom,
    String? dateTo,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final queryParams = <String, String>{};
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;
      if (status != null) queryParams['status'] = status;
      
      final uri = Uri.parse('$baseUrl/api/booking/appointments').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List appointmentsList = data['appointments'] ?? data['data'] ?? [];
          return appointmentsList.map((json) => BookingModel.fromJson(json)).toList();
        }
      }
      throw Exception('Không thể tải danh sách lịch hẹn');
    } catch (e) {
      throw Exception('Lỗi khi tải lịch hẹn: $e');
    }
  }

  /// Lấy chi tiết một lịch hẹn
  static Future<BookingModel> getAppointmentById(int appointmentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/booking/appointments/$appointmentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return BookingModel.fromJson(data['appointment'] ?? data['data']);
        }
      }
      throw Exception('Không thể tải thông tin lịch hẹn');
    } catch (e) {
      throw Exception('Lỗi khi tải lịch hẹn: $e');
    }
  }

  /// Tạo lịch hẹn mới
  static Future<BookingModel> createAppointment(CreateBookingRequest request) async {
    try {
      print('🔍 Đang tạo lịch hẹn...');
      print('🔍 Request data: ${request.toJson()}');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/booking/create'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      print('📩 Create booking response: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Tạo lịch hẹn thành công');
          return BookingModel.fromJson(data['appointment'] ?? data['data']);
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể tạo lịch hẹn');
    } catch (e) {
      print('❌ Lỗi khi tạo lịch hẹn: $e');
      throw Exception('Lỗi khi tạo lịch hẹn: $e');
    }
  }

  /// Hủy lịch hẹn
  static Future<void> cancelAppointment(int appointmentId, String reason) async {
    try {
      print('🔍 Đang hủy lịch hẹn $appointmentId...');
      
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/booking/appointments/$appointmentId/cancel'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );

      print('📩 Cancel appointment response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Hủy lịch hẹn thành công');
        return;
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể hủy lịch hẹn');
    } catch (e) {
      print('❌ Lỗi khi hủy lịch hẹn: $e');
      throw Exception('Lỗi khi hủy lịch hẹn: $e');
    }
  }

  /// Lấy lịch hẹn của user
  static Future<List<BookingModel>> getUserAppointments(int userId) async {
    try {
      print('🔍 Đang tải lịch hẹn của user $userId...');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/booking/user/$userId'),
        headers: headers,
      );

      print('📩 User appointments response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List appointmentsList = data['appointments'] ?? data['data'] ?? [];
          print('✅ Tải thành công ${appointmentsList.length} lịch hẹn');
          return appointmentsList.map((json) => BookingModel.fromJson(json)).toList();
        }
      }
      
      throw Exception('Không thể tải lịch hẹn của user');
    } catch (e) {
      print('❌ Lỗi khi tải lịch hẹn: $e');
      return [];
    }
  }
}