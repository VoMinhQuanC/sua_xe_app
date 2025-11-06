import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:suaxe_app/models/booking_model.dart';
import 'package:suaxe_app/models/service_model.dart';

class BookingApiService {
  // URL base của API - thay đổi theo môi trường của bạn
  static const String baseUrl = 'https://suaxe-api.as.r.appspot.com'; // TODO: Thay đổi URL này
  
  // Lấy token từ shared preferences hoặc secure storage
  static Future<String?> _getAuthToken() async {
    // TODO: Implement lấy token từ local storage
    // Ví dụ: return await storage.read(key: 'auth_token');
    return null;
  }

  // Helper để tạo headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============ SERVICES API ============
  
  /// Lấy danh sách tất cả dịch vụ
  static Future<List<ServiceModel>> getAllServices() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/services'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List servicesList = data['data'] ?? data['services'] ?? [];
          return servicesList.map((json) => ServiceModel.fromJson(json)).toList();
        }
      }
      throw Exception('Không thể tải danh sách dịch vụ');
    } catch (e) {
      throw Exception('Lỗi khi tải dịch vụ: $e');
    }
  }

  /// Lấy thông tin chi tiết một dịch vụ
  static Future<ServiceModel> getServiceById(int serviceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/services/$serviceId'),
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

  // ============ BOOKING/APPOINTMENTS API ============
  
  /// Lấy danh sách lịch hẹn (có thể filter)
  static Future<List<BookingModel>> getAppointments({
    String? dateFrom,
    String? dateTo,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Xây dựng query parameters
      final queryParams = <String, String>{};
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;
      if (status != null) queryParams['status'] = status;
      
      final uri = Uri.parse('$baseUrl/booking/appointments').replace(
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
        Uri.parse('$baseUrl/booking/appointments/$appointmentId'),
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
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/booking/appointments'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return BookingModel.fromJson(data['appointment'] ?? data['data']);
        }
      }
      
      // Parse error message
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể tạo lịch hẹn');
    } catch (e) {
      throw Exception('Lỗi khi tạo lịch hẹn: $e');
    }
  }

  /// Cập nhật lịch hẹn
  static Future<BookingModel> updateAppointment(
    int appointmentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/booking/appointments/$appointmentId'),
        headers: headers,
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return BookingModel.fromJson(data['appointment'] ?? data['data']);
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể cập nhật lịch hẹn');
    } catch (e) {
      throw Exception('Lỗi khi cập nhật lịch hẹn: $e');
    }
  }

  /// Hủy lịch hẹn
  static Future<bool> cancelAppointment(int appointmentId, String? reason) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/booking/appointments/$appointmentId/cancel'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể hủy lịch hẹn');
    } catch (e) {
      throw Exception('Lỗi khi hủy lịch hẹn: $e');
    }
  }

  /// Xóa lịch hẹn (soft delete)
  static Future<bool> deleteAppointment(int appointmentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/booking/appointments/$appointmentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể xóa lịch hẹn');
    } catch (e) {
      throw Exception('Lỗi khi xóa lịch hẹn: $e');
    }
  }

  // ============ VEHICLES API ============
  
  /// Lấy danh sách xe của user
  static Future<List<Vehicle>> getUserVehicles(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/vehicles'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List vehiclesList = data['vehicles'] ?? data['data'] ?? [];
          return vehiclesList.map((json) => Vehicle.fromJson(json)).toList();
        }
      }
      throw Exception('Không thể tải danh sách xe');
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách xe: $e');
    }
  }

  /// Thêm xe mới
  static Future<Vehicle> addVehicle(Vehicle vehicle) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles'),
        headers: headers,
        body: json.encode(vehicle.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Vehicle.fromJson(data['vehicle'] ?? data['data']);
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể thêm xe');
    } catch (e) {
      throw Exception('Lỗi khi thêm xe: $e');
    }
  }

  // ============ HELPER METHODS ============
  
  /// Kiểm tra slot thời gian còn trống
  static Future<bool> checkAvailableSlot(DateTime dateTime) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/booking/check-availability'),
        headers: headers,
        body: json.encode({
          'appointmentDate': dateTime.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['available'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Lỗi khi kiểm tra slot: $e');
    }
  }

  /// Lấy các slot thời gian khả dụng trong ngày
  static Future<List<DateTime>> getAvailableSlots(DateTime date) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/booking/available-slots?date=${date.toIso8601String()}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List slots = data['slots'] ?? [];
          return slots.map((slot) => DateTime.parse(slot)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi khi lấy slot khả dụng: $e');
    }
  }
}