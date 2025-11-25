// lib/services/api/schedule_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:suaxe_app/models/mechanic_model.dart';
import 'package:suaxe_app/models/time_slot_model.dart';

class ScheduleApiService {
  static const String baseUrl = 'https://suaxeweb-production.up.railway.app';
  static const _secureStorage = FlutterSecureStorage();

  static Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    try {
      // ✅ FIX: Thử cả 2 key
      String? token = await _secureStorage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        token = await _secureStorage.read(key: 'auth_token');
      }
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('🔑 Token added to request');
      } else {
        print('⚠️ No token found in SecureStorage');
      }
    } catch (e) {
      print('❌ Error getting token: $e');
    }
    
    return headers;
  }

  /// Helper: Chuyển time "HH:mm" sang phút
  static int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  /// Helper: Check xem time có trong khoảng [start, end) không
  static bool _isTimeInRange(String time, String startTime, String endTime) {
    try {
      final timeMin = _timeToMinutes(time);
      final startMin = _timeToMinutes(startTime);
      final endMin = _timeToMinutes(endTime);
      
      return timeMin >= startMin && timeMin < endMin;
    } catch (e) {
      return false;
    }
  }

  /// Lấy danh sách khung giờ
  static Future<List<TimeSlotModel>> getAvailableTimeSlots(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('🔍 Đang lấy khung giờ cho ngày: $dateStr');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/schedules/available-slots?date=$dateStr'),
        headers: headers,
      );

      print('📩 Time slots response: ${response.statusCode}');
      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<TimeSlotModel> timeSlots = [
            TimeSlotModel(time: '09:00', isAvailable: true, availableMechanics: 0),
            TimeSlotModel(time: '10:00', isAvailable: true, availableMechanics: 0),
            TimeSlotModel(time: '11:00', isAvailable: true, availableMechanics: 0),
            TimeSlotModel(time: '12:00', isAvailable: true, availableMechanics: 0),
            TimeSlotModel(time: '13:00', isAvailable: true, availableMechanics: 0),
            TimeSlotModel(time: '14:00', isAvailable: true, availableMechanics: 0),
            TimeSlotModel(time: '15:00', isAvailable: true, availableMechanics: 0),
            TimeSlotModel(time: '16:00', isAvailable: true, availableMechanics: 0),
            TimeSlotModel(time: '17:00', isAvailable: true, availableMechanics: 0),
          ];
          
          print('✅ Tải thành công ${timeSlots.length} khung giờ');
          return timeSlots;
        }
      }
      
      throw Exception('Không thể tải khung giờ');
    } catch (e) {
      print('❌ Lỗi khi tải khung giờ: $e');
      throw Exception('Lỗi khi tải khung giờ: $e');
    }
  }

  /// Lấy danh sách kỹ thuật viên
  static Future<List<MechanicModel>> getAvailableMechanics({
    required DateTime date,
    required String time,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      print('==========================================');
      print('🔍 ĐANG LẤY KỸ THUẬT VIÊN');
      print('📅 Ngày: $dateStr');
      print('⏰ Khung giờ: $time');
      print('==========================================');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/schedules/available-slots?date=$dateStr'),
        headers: headers,
      );

      print('📩 Status: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final List availableSlots = data['availableSlots'] ?? [];
          
          print('📦 Tổng số slots từ backend: ${availableSlots.length}');
          
          if (availableSlots.isEmpty) {
            print('⚠️ Backend không trả về slots nào!');
            return [];
          }
          
          // In ra tất cả slots
          for (var i = 0; i < availableSlots.length; i++) {
            final slot = availableSlots[i];
            print('Slot $i: MechanicID=${slot['MechanicID']}, Name=${slot['MechanicName']}, StartTime=${slot['StartTime']}, EndTime=${slot['EndTime']}');
          }
          
          // Filter kỹ thuật viên
          final mechanicsList = <MechanicModel>[];
          
          for (var slot in availableSlots) {
            final startTime = slot['StartTime'] ?? '';
            final endTime = slot['EndTime'] ?? '';
            
            // Remove seconds
            final startShort = startTime.length > 5 ? startTime.substring(0, 5) : startTime;
            final endShort = endTime.length > 5 ? endTime.substring(0, 5) : endTime;
            
            print('  → Checking: ${slot['MechanicName']} ($startShort - $endShort)');
            
            if (_isTimeInRange(time, startShort, endShort)) {
              print('    ✅ MATCH! Adding to list');
              try {
                final mechanic = MechanicModel.fromJson(slot);
                mechanicsList.add(mechanic);
              } catch (e) {
                print('    ❌ Lỗi khi parse mechanic: $e');
              }
            } else {
              print('    ❌ Không match');
            }
          }
          
          // Remove duplicates
          final uniqueMechanics = <int, MechanicModel>{};
          for (var mechanic in mechanicsList) {
            uniqueMechanics[mechanic.mechanicId] = mechanic;
          }
          
          final result = uniqueMechanics.values.toList();
          
          print('==========================================');
          print('✅ KẾT QUẢ: ${result.length} kỹ thuật viên');
          for (var m in result) {
            print('  - ID=${m.mechanicId}, Name=${m.fullName}, Available=${m.isAvailable}');
          }
          print('==========================================');
          
          return result;
        }
      }
      
      throw Exception('Không thể tải danh sách kỹ thuật viên');
    } catch (e) {
      print('❌ LỖI NGHIÊM TRỌNG: $e');
      throw Exception('Lỗi khi tải kỹ thuật viên: $e');
    }
  }
}