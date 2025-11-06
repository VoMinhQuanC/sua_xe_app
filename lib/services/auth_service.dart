// File: lib/services/auth_service.dart
// Service quản lý authentication và user session

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Storage keys
  static const String _keyUserId = 'user_id';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // Secure storage for sensitive data (token)
  final _secureStorage = const FlutterSecureStorage();
  
  // ✅ THÊM: Cache SharedPreferences instance
  static SharedPreferences? _prefsInstance;
  
  // ✅ THÊM: Helper để lấy SharedPreferences instance
  static Future<SharedPreferences> _getPrefs() async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }

  // ==================== USER ID ====================
  
  /// Lưu userId sau khi login thành công
  static Future<void> saveUserId(int userId) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setBool(_keyIsLoggedIn, true);
    // ✅ QUAN TRỌNG: Force commit để đảm bảo dữ liệu được lưu ngay
    await prefs.reload();
    print('✅ Đã lưu userId: $userId');
    
    // Debug: Kiểm tra lại ngay sau khi lưu
    final savedId = prefs.getInt(_keyUserId);
    print('🔍 Kiểm tra lại userId sau khi lưu: $savedId');
  }

  /// Lấy userId hiện tại
  static Future<int?> getUserId() async {
    try {
      final prefs = await _getPrefs();
      // ✅ Reload để đảm bảo lấy dữ liệu mới nhất
      await prefs.reload();
      final userId = prefs.getInt(_keyUserId);
      print('🔍 getUserId() trả về: $userId');
      return userId;
    } catch (e) {
      print('❌ Lỗi khi lấy userId: $e');
      return null;
    }
  }

  /// Kiểm tra user đã login chưa
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await _getPrefs();
      await prefs.reload();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final userId = prefs.getInt(_keyUserId);
      print('🔍 isLoggedIn: $isLoggedIn, userId: $userId');
      // ✅ Chỉ trả về true nếu CẢ HAI điều kiện đều đúng
      return isLoggedIn && userId != null;
    } catch (e) {
      print('❌ Lỗi khi kiểm tra login: $e');
      return false;
    }
  }

  // ==================== AUTH TOKEN ====================
  
  /// Lưu auth token (JWT)
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _keyAuthToken, value: token);
    print('✅ Đã lưu auth token');
  }

  /// Lấy auth token
  Future<String?> getAuthToken() async {
    final token = await _secureStorage.read(key: _keyAuthToken);
    print('🔍 Auth token: ${token != null ? "có" : "không"}');
    return token;
  }

  // ==================== USER INFO ====================
  
  /// Lưu thông tin user sau khi login
  static Future<void> saveUserInfo({
    required int userId,
    required String email,
    required String name,
    int? roleId,
  }) async {
    final prefs = await _getPrefs();
    
    await prefs.setInt(_keyUserId, userId);
    await prefs.setBool(_keyIsLoggedIn, true);
    
    if (email.isNotEmpty) {
      await prefs.setString(_keyUserEmail, email);
    }
    if (name.isNotEmpty) {
      await prefs.setString(_keyUserName, name);
    }
    if (roleId != null) {
      await prefs.setInt(_keyUserRole, roleId);
    }
    
    // ✅ Force commit
    await prefs.reload();
    
    print('✅ Đã lưu thông tin user:');
    print('   - UserId: $userId');
    print('   - Email: $email');
    print('   - Name: $name');
    print('   - RoleId: $roleId');
    
    // Debug: Kiểm tra lại
    await debugPrintUserInfo();
  }

  /// Lấy thông tin user
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await _getPrefs();
    await prefs.reload();
    final userId = prefs.getInt(_keyUserId);
    
    if (userId == null) {
      print('❌ getUserInfo: userId là null');
      return null;
    }
    
    return {
      'userId': userId,
      'email': prefs.getString(_keyUserEmail) ?? '',
      'name': prefs.getString(_keyUserName) ?? 'Khách hàng',
      'roleId': prefs.getInt(_keyUserRole),
    };
  }

  /// Kiểm tra có phải admin không
  static Future<bool> isAdmin() async {
    final prefs = await _getPrefs();
    await prefs.reload();
    final roleId = prefs.getInt(_keyUserRole);
    return roleId == 1;
  }

  /// Đăng xuất
  static Future<void> logout() async {
    final prefs = await _getPrefs();
    await prefs.clear(); // ✅ Xóa tất cả dữ liệu
    
    // Xóa token từ secure storage
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: _keyAuthToken);
    
    // ✅ Reset cache
    _prefsInstance = null;
    
    print('✅ Đã đăng xuất và xóa toàn bộ thông tin user');
  }

  // ==================== DEBUG ====================
  
  /// Debug: In ra tất cả thông tin đã lưu
  static Future<void> debugPrintUserInfo() async {
    try {
      final prefs = await _getPrefs();
      await prefs.reload();
      print('=================================');
      print('🔍 DEBUG AUTH SERVICE');
      print('=================================');
      print('✅ UserId: ${prefs.getInt(_keyUserId)}');
      print('✅ Email: ${prefs.getString(_keyUserEmail)}');
      print('✅ Name: ${prefs.getString(_keyUserName)}');
      print('✅ Role: ${prefs.getInt(_keyUserRole)}');
      print('✅ IsLoggedIn: ${prefs.getBool(_keyIsLoggedIn)}');
      
      // ✅ THÊM: In tất cả keys có trong SharedPreferences
      final keys = prefs.getKeys();
      print('✅ Tất cả keys: $keys');
      print('=================================');
    } catch (e) {
      print('❌ Lỗi khi debug: $e');
    }
  }
}