// lib/services/api/mechanic_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:suaxe_app/models/booking_model.dart';

class MechanicApiService {
  static const String baseUrl = 'https://suaxeweb-production.up.railway.app';
  static const _secureStorage = FlutterSecureStorage();

  /// Lấy token từ storage
  static Future<String?> _getAuthToken() async {
    try {
      return await _secureStorage.read(key: 'auth_token');
    } catch (e) {
      print('❌ Lỗi khi lấy token: $e');
      return null;
    }
  }

  /// Tạo headers với token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // SCHEDULE APIs - QUẢN LÝ LỊCH LÀM VIỆC
  // ============================================

  /// Lấy danh sách lịch làm việc của thợ
  /// GET /api/mechanics/schedules
  static Future<List<Map<String, dynamic>>> getMySchedules({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Build query params
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      
      final uri = Uri.parse('$baseUrl/api/mechanics/schedules')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      print('🔍 GET schedules: $uri');
      
      final response = await http.get(uri, headers: headers);
      
      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List schedules = data['schedules'] ?? [];
          return schedules.cast<Map<String, dynamic>>();
        }
      }
      
      throw Exception('Không thể tải lịch làm việc');
    } catch (e) {
      print('❌ Lỗi khi lấy lịch làm việc: $e');
      throw Exception('Lỗi khi tải lịch làm việc: $e');
    }
  }

  /// Đăng ký lịch làm việc mới
  /// POST /api/mechanics/schedules
  static Future<Map<String, dynamic>> createSchedule({
    required String workDate,
    required String startTime,
    required String endTime,
    String? type,
    String? notes,
    int? isAvailable,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // ✅ Format datetime theo backend expects (ISO format)
      final startDateTime = '${workDate}T$startTime:00';
      final endDateTime = '${workDate}T$endTime:00';
      
      // ✅ Body theo đúng format backend mong đợi
      final body = {
        'startTime': startDateTime,  // ← LOWERCASE, ISO format
        'endTime': endDateTime,      // ← LOWERCASE, ISO format
        'type': type ?? 'available',
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      
      print('📤 POST create schedule: $body');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/mechanics/schedules'),
        headers: headers,
        body: json.encode(body),
      );
      
      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Đăng ký lịch thành công',
            'scheduleId': data['scheduleId'],
          };
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể tạo lịch làm việc');
    } catch (e) {
      print('❌ Lỗi khi tạo lịch làm việc: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// Cập nhật lịch làm việc
  /// PUT /api/mechanics/schedules/:id
  static Future<Map<String, dynamic>> updateSchedule({
    required int scheduleId,
    String? workDate,
    String? startTime,
    String? endTime,
    String? type,
    String? notes,
    int? isAvailable,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final body = <String, dynamic>{};
      
      // ✅ Nếu có workDate và startTime/endTime → tạo datetime ISO cho validation
      if (workDate != null && startTime != null && endTime != null) {
        body['validationStartTime'] = '${workDate}T$startTime:00';
        body['validationEndTime'] = '${workDate}T$endTime:00';
        body['WorkDate'] = workDate;
        body['StartTime'] = '$startTime:00';
        body['EndTime'] = '$endTime:00';
      } else {
        if (workDate != null) body['WorkDate'] = workDate;
        if (startTime != null) body['StartTime'] = '$startTime:00';
        if (endTime != null) body['EndTime'] = '$endTime:00';
      }
      
      if (type != null) body['Type'] = type;
      if (notes != null) body['notes'] = notes;
      if (isAvailable != null) body['IsAvailable'] = isAvailable;
      
      print('📤 PUT update schedule $scheduleId: $body');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/mechanics/schedules/$scheduleId'),
        headers: headers,
        body: json.encode(body),
      );
      
      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Cập nhật lịch thành công',
          };
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể cập nhật lịch');
    } catch (e) {
      print('❌ Lỗi khi cập nhật lịch: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// Xóa lịch làm việc
  /// DELETE /api/mechanics/schedules/:id
  static Future<Map<String, dynamic>> deleteSchedule(int scheduleId) async {
    try {
      final headers = await _getHeaders();
      
      print('🗑️ DELETE schedule $scheduleId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/mechanics/schedules/$scheduleId'),
        headers: headers,
      );
      
      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Xóa lịch thành công',
          };
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể xóa lịch');
    } catch (e) {
      print('❌ Lỗi khi xóa lịch: $e');
      throw Exception('Lỗi: $e');
    }
  }

  // ============================================
  // SCHEDULE REQUEST APIs - XIN NGHỈ / XIN SỬA
  // ============================================

  /// Xin nghỉ (cần Admin duyệt)
  /// POST /api/mechanics/schedules/:id/request-edit
  static Future<Map<String, dynamic>> requestLeave({
    required int scheduleId,
    required String workDate,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final body = {
        'type': 'leave',            // ✅ THÊM: Để backend biết đây là xin nghỉ
        'newWorkDate': workDate,
        'newStartTime': startTime,
        'newEndTime': endTime,
        'reason': reason,
      };

      print('📤 POST request LEAVE schedule $scheduleId');
      print('   🏷️  Type: leave');
      print('   📅 WorkDate: $workDate');
      print('   ⏰ Time: $startTime - $endTime');
      print('   📝 Reason: $reason');

      final response = await http.post(
        Uri.parse('$baseUrl/api/mechanics/schedules/$scheduleId/request-edit'),
        headers: headers,
        body: json.encode(body),
      );

      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Đã gửi đơn xin nghỉ',
        };
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Không thể gửi đơn xin nghỉ',
      };
    } catch (e) {
      print('❌ Lỗi khi gửi đơn xin nghỉ: $e');
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  /// Xin sửa lịch (cần Admin duyệt)
  /// POST /api/mechanics/schedules/:id/request-edit
  static Future<Map<String, dynamic>> requestEditSchedule({
    required int scheduleId,
    required String newWorkDate,
    required String newStartTime,
    required String newEndTime,
    required String reason,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final body = {
        'type': 'edit',             // ✅ THÊM: Để backend biết đây là xin sửa
        'newWorkDate': newWorkDate,
        'newStartTime': newStartTime,
        'newEndTime': newEndTime,
        'reason': reason,
      };

      print('📤 POST request EDIT schedule $scheduleId');
      print('   🏷️  Type: edit');
      print('   📅 New Date: $newWorkDate');
      print('   ⏰ New Time: $newStartTime - $newEndTime');
      print('   📝 Reason: $reason');

      final response = await http.post(
        Uri.parse('$baseUrl/api/mechanics/schedules/$scheduleId/request-edit'),
        headers: headers,
        body: json.encode(body),
      );

      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Đã gửi đơn xin sửa lịch',
        };
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Không thể gửi đơn xin sửa lịch',
      };
    } catch (e) {
      print('❌ Lỗi khi gửi đơn xin sửa lịch: $e');
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  // ============================================
  // APPOINTMENT APIs - QUẢN LÝ LỊCH HẸN
  // ============================================

  /// Lấy danh sách lịch hẹn của thợ
  /// GET /api/mechanics/appointments
  static Future<List<BookingModel>> getMyAppointments({
    String? status,
    String? date,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Build query params
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (date != null) queryParams['date'] = date;
      
      final uri = Uri.parse('$baseUrl/api/mechanics/appointments')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      print('🔍 GET appointments: $uri');
      
      final response = await http.get(uri, headers: headers);
      
      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List appointments = data['appointments'] ?? [];
          return appointments.map((json) => BookingModel.fromJson(json)).toList();
        }
      }
      
      throw Exception('Không thể tải lịch hẹn');
    } catch (e) {
      print('❌ Lỗi khi lấy lịch hẹn: $e');
      throw Exception('Lỗi khi tải lịch hẹn: $e');
    }
  }

  /// Cập nhật trạng thái lịch hẹn
  /// PUT /api/mechanics/appointments/:id/status
  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required int appointmentId,
    required String status, // Confirmed, Completed, Canceled
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final body = {
        'status': status,
        if (notes != null) 'notes': notes,
      };
      
      print('📤 PUT update appointment $appointmentId status: $body');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/mechanics/appointments/$appointmentId/status'),
        headers: headers,
        body: json.encode(body),
      );
      
      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Cập nhật trạng thái thành công',
          };
        }
      }
      
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể cập nhật trạng thái');
    } catch (e) {
      print('❌ Lỗi khi cập nhật trạng thái: $e');
      throw Exception('Lỗi: $e');
    }
  }

  // ============================================
  // NOTIFICATION APIs - QUẢN LÝ THÔNG BÁO
  // ============================================

  /// Lấy danh sách thông báo
  /// GET /api/mechanics/notifications
  static Future<List<Map<String, dynamic>>> getNotifications({int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      
      final uri = Uri.parse('$baseUrl/api/mechanics/notifications')
          .replace(queryParameters: {'limit': limit.toString()});
      
      print('🔍 GET notifications: $uri');
      
      final response = await http.get(uri, headers: headers);
      
      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List notifications = data['notifications'] ?? [];
          return notifications.cast<Map<String, dynamic>>();
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Lỗi khi lấy thông báo: $e');
      return [];
    }
  }

  /// Đánh dấu thông báo đã đọc
  /// PUT /api/mechanics/notifications/:id/read
  static Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    try {
      final headers = await _getHeaders();
      
      print('📤 PUT mark notification $notificationId as read');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/mechanics/notifications/$notificationId/read'),
        headers: headers,
      );
      
      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Đã đánh dấu là đã đọc',
          };
        }
      }
      
      return {'success': false, 'message': 'Không thể cập nhật'};
    } catch (e) {
      print('❌ Lỗi khi đánh dấu thông báo: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Format date sang YYYY-MM-DD
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format time sang HH:mm
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}