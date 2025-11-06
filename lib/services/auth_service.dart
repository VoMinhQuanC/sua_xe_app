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

  // ==================== USER ID ====================
  
  /// Lưu userId sau khi login thành công
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setBool(_keyIsLoggedIn, true);
    print('✅ Đã lưu userId: $userId');
  }

  /// Lấy userId hiện tại
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_keyUserId);
    print('🔍 getUserId() trả về: $userId');
    return userId;
  }

  /// Kiểm tra user đã login chưa
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // ==================== AUTH TOKEN ====================
  
  /// Lưu auth token (JWT)
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _keyAuthToken, value: token);
  }

  /// Lấy auth token
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _keyAuthToken);
  }

  // ==================== USER INFO ====================
  
  /// Lưu thông tin user sau khi login
  static Future<void> saveUserInfo({
    required int userId,
    required String email,
    required String name,
    int? roleId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
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
    
    print('✅ Đã lưu thông tin user:');
    print('   - UserId: $userId');
    print('   - Email: $email');
    print('   - Name: $name');
    print('   - RoleId: $roleId');
  }

  /// Lấy thông tin user
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_keyUserId);
    
    if (userId == null) return null;
    
    return {
      'userId': userId,
      'email': prefs.getString(_keyUserEmail) ?? '',
      'name': prefs.getString(_keyUserName) ?? 'Khách hàng',
      'roleId': prefs.getInt(_keyUserRole),
    };
  }

  /// Kiểm tra có phải admin không
  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final roleId = prefs.getInt(_keyUserRole);
    return roleId == 1;
  }

  /// Đăng xuất
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserRole);
    await prefs.setBool(_keyIsLoggedIn, false);
    
    // Xóa token từ secure storage
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: _keyAuthToken);
    
    print('✅ Đã đăng xuất và xóa toàn bộ thông tin user');
  }

  // ==================== DEBUG ====================
  
  /// Debug: In ra tất cả thông tin đã lưu
  static Future<void> debugPrintUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    print('=================================');
    print('🔍 DEBUG AUTH SERVICE');
    print('=================================');
    print('✅ UserId: ${prefs.getInt(_keyUserId)}');
    print('✅ Email: ${prefs.getString(_keyUserEmail)}');
    print('✅ Name: ${prefs.getString(_keyUserName)}');
    print('✅ Role: ${prefs.getInt(_keyUserRole)}');
    print('✅ IsLoggedIn: ${prefs.getBool(_keyIsLoggedIn)}');
    print('=================================');
  }
}