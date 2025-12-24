import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';  // ✅ THÊM
import '../models/attendance_model.dart';

class AttendanceService {
  static const String baseUrl = 'https://suaxeweb-production.up.railway.app/api';
  final _storage = FlutterSecureStorage();
  
  // Get auth token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  // ✅ FIX: Get mechanic ID from SharedPreferences (not FlutterSecureStorage)
  Future<int?> _getMechanicId() async {
    try {
      // ✅ READ FROM SHAREDPREFERENCES (như auth_service)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');  // ✅ Key: 'user_id'
      
      print('🔍 DEBUG: SharedPreferences user_id: $userId');
      
      // ✅ Debug: In tất cả keys
      final keys = prefs.getKeys();
      print('🔍 DEBUG: All keys in SharedPreferences: $keys');
      
      return userId;
    } catch (e) {
      print('❌ Error getting mechanic ID: $e');
      return null;
    }
  }
  
  // Check-in
  Future<AttendanceModel?> checkIn({
    required String qrToken,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ No token found');
        throw Exception('Chưa đăng nhập');
      }
      
      print('✅ Token: ${token.substring(0, 20)}...');
      print('✅ QR Token: $qrToken');
      print('✅ Location: $latitude, $longitude');
      
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'qrToken': qrToken,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      
      print('✅ Response status: ${response.statusCode}');
      print('✅ Response body: ${response.body}');
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        if (data['attendance'] != null) {
          print('📦 Using nested attendance object');
          return AttendanceModel.fromJson(data['attendance']);
        } else {
          print('📦 Using flat structure, creating attendance from root');
          return AttendanceModel.fromJson(data);
        }
      } else {
        throw Exception(data['message'] ?? 'Check-in thất bại');
      }
    } catch (e) {
      print('❌ Check-in error: $e');
      rethrow;
    }
  }
  
  // Check-out
  Future<AttendanceModel?> checkOut({
    required String qrToken,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ No token found');
        throw Exception('Chưa đăng nhập');
      }
      
      print('✅ Token: ${token.substring(0, 20)}...');
      print('✅ QR Token: $qrToken');
      print('✅ Location: $latitude, $longitude');
      
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-out'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'qrToken': qrToken,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      
      print('✅ Response status: ${response.statusCode}');
      print('✅ Response body: ${response.body}');
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        if (data['attendance'] != null) {
          print('📦 Using nested attendance object');
          return AttendanceModel.fromJson(data['attendance']);
        } else {
          print('📦 Using flat structure, creating attendance from root');
          return AttendanceModel.fromJson(data);
        }
      } else {
        throw Exception(data['message'] ?? 'Check-out thất bại');
      }
    } catch (e) {
      print('❌ Check-out error: $e');
      rethrow;
    }
  }
  
  // Get today's attendance
  Future<AttendanceModel?> getTodayAttendance() async {
    try {
      final token = await _getToken();
      
      print('🔍 Getting today attendance...');
      print('🔍 Token: ${token?.substring(0, 20) ?? "null"}...');
      
      if (token == null) {
        print('❌ No token');
        return null;
      }
      
      // ✅ FIXED: Endpoint đúng - /api/attendance/today (KHÔNG có /mechanic/{id})
      // MechanicID được lấy từ JWT token ở backend
      // Backend tự lấy today date, không cần truyền
      String url = '$baseUrl/attendance/today';
      
      print('🔍 URL: $url');
      
      var response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('✅ Response status: ${response.statusCode}');
      print('✅ Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        print('❌ API returned ${response.statusCode}');
        return null;
      }
      
      final data = json.decode(response.body);
      
      if (data == null) {
        print('❌ Response data is null');
        return null;
      }
      
      if (!data['success']) {
        print('❌ API success = false: ${data['message']}');
        return null;
      }
      
      if (data['attendance'] == null) {
        print('✅ No attendance today (attendance = null)');
        return null;
      }
      
      print('✅ Attendance found: ${data['attendance']}');
      return AttendanceModel.fromJson(data['attendance']);
      
    } catch (e) {
      print('❌ Error getting today attendance: $e');
      return null;
    }
  }
  
  // Get attendance history
  Future<List<AttendanceModel>> getHistory({
    int? month,
    int? year,
  }) async {
    try {
      final token = await _getToken();
      
      print('🔍 Getting history...');
      print('🔍 Token: ${token?.substring(0, 20) ?? "null"}...');
      
      if (token == null) {
        print('❌ Token is null');
        return [];
      }
      
      // ✅ FIXED: Endpoint đúng - /api/attendance/history (KHÔNG có /mechanic/{id})
      // MechanicID được lấy từ JWT token ở backend
      String url = '$baseUrl/attendance/history';
      
      // ✅ FIXED: Month format "YYYY-MM" (VD: "2025-12")
      if (month != null && year != null) {
        final monthStr = month.toString().padLeft(2, '0');
        url += '?month=$year-$monthStr';
      }
      
      print('🔍 URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('✅ Response status: ${response.statusCode}');
      print('✅ Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        print('❌ API returned ${response.statusCode}');
        return [];
      }
      
      final data = json.decode(response.body);
      
      if (data == null || !data['success']) {
        print('❌ API failed or data is null');
        return [];
      }
      
      List<dynamic> attendanceList = data['attendance'] ?? [];
      print('✅ Found ${attendanceList.length} records');
      
      return attendanceList.map((json) => AttendanceModel.fromJson(json)).toList();
      
    } catch (e) {
      print('❌ Error getting history: $e');
      return [];
    }
  }
}