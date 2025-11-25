import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api_config.dart';

class ProfileApiService {
  static const _storage = FlutterSecureStorage();
  static final String baseUrl = ApiConfig.baseUrl;

  /// Lấy token từ storage
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Cập nhật thông tin profile
  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? address,
  }) async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'address': address,
        }),
      );

      print('📩 Update profile response: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Cập nhật thành công',
          };
        }
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể cập nhật thông tin');
    } catch (e) {
      print('❌ Lỗi khi cập nhật profile: $e');
      throw Exception('Lỗi khi cập nhật thông tin: $e');
    }
  }

  /// Lấy thông tin profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['user'];
        }
      }

      throw Exception('Không thể tải thông tin');
    } catch (e) {
      print('❌ Lỗi khi tải profile: $e');
      throw Exception('Lỗi khi tải thông tin: $e');
    }
  }
}