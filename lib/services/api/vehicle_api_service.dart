import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api_config.dart';
import '../../models/vehicle_model.dart';

class VehicleApiService {
  static const _storage = FlutterSecureStorage();
  static final String baseUrl = ApiConfig.baseUrl;

  static Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Lấy danh sách xe của user
  static Future<List<VehicleModel>> getUserVehicles(int userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/vehicles/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Get vehicles response: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List vehiclesJson = data['data'] ?? data['vehicles'] ?? [];
          return vehiclesJson.map((v) => VehicleModel.fromJson(v)).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách xe: $e');
      return [];
    }
  }

  /// Thêm xe mới
  static Future<Map<String, dynamic>> createVehicle(VehicleModel vehicle) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(vehicle.toJson()),
      );

      print('📤 Create vehicle response: ${response.statusCode}');
      print('📤 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Thêm xe thành công',
            'vehicleId': data['id'],
          };
        }
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể thêm xe');
    } catch (e) {
      print('❌ Lỗi khi thêm xe: $e');
      throw Exception('Lỗi khi thêm xe: $e');
    }
  }

  /// Cập nhật xe
  static Future<Map<String, dynamic>> updateVehicle(
    int vehicleId,
    VehicleModel vehicle,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/vehicles/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(vehicle.toJson()),
      );

      print('📤 Update vehicle response: ${response.statusCode}');
      print('📤 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Cập nhật xe thành công',
          };
        }
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể cập nhật xe');
    } catch (e) {
      print('❌ Lỗi khi cập nhật xe: $e');
      throw Exception('Lỗi khi cập nhật xe: $e');
    }
  }

  /// Xóa xe
  static Future<Map<String, dynamic>> deleteVehicle(int vehicleId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/vehicles/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🗑️ Delete vehicle response: ${response.statusCode}');
      print('🗑️ Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Xóa xe thành công',
          };
        }
      }

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể xóa xe');
    } catch (e) {
      print('❌ Lỗi khi xóa xe: $e');
      throw Exception('Lỗi khi xóa xe: $e');
    }
  }
}