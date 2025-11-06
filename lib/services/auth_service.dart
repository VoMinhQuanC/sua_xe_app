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
  }

  /// Lấy userId hiện tại
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
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
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserName, name);
    if (roleId != null) {
      await prefs.setInt(_keyUserRole, roleId);
    }
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Lấy email user
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  /// Lấy tên user
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  /// Lấy role user (1: admin, 2: customer, 3: technician)
  static Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserRole);
  }

  /// Kiểm tra user có phải admin không
  static Future<bool> isAdmin() async {
    final roleId = await getUserRole();
    return roleId == 1;
  }

  // ==================== LOGOUT ====================
  
  /// Xóa tất cả thông tin user khi logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = const FlutterSecureStorage();
    
    // Xóa từ SharedPreferences
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserRole);
    await prefs.setBool(_keyIsLoggedIn, false);
    
    // Xóa token từ secure storage
    await storage.delete(key: _keyAuthToken);
  }

  /// Clear tất cả data (dùng khi cần reset hoàn toàn)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = const FlutterSecureStorage();
    
    await prefs.clear();
    await storage.deleteAll();
  }

  // ==================== HELPER METHODS ====================
  
  /// Lấy tất cả thông tin user
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final userId = await getUserId();
    if (userId == null) return null;

    return {
      'userId': userId,
      'email': await getUserEmail(),
      'name': await getUserName(),
      'roleId': await getUserRole(),
      'isLoggedIn': await isLoggedIn(),
    };
  }

  /// Update thông tin user
  static Future<void> updateUserInfo({
    String? email,
    String? name,
    int? roleId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (email != null) {
      await prefs.setString(_keyUserEmail, email);
    }
    if (name != null) {
      await prefs.setString(_keyUserName, name);
    }
    if (roleId != null) {
      await prefs.setInt(_keyUserRole, roleId);
    }
  }
}

// ==================== USAGE EXAMPLES ====================

/*
// 1. Sau khi login thành công:
await AuthService.saveUserInfo(
  userId: response['userId'],
  email: response['email'],
  name: response['name'],
  roleId: response['roleId'],
);

// Hoặc chỉ lưu userId:
await AuthService.saveUserId(userId);

// 2. Lấy userId để sử dụng:
final userId = await AuthService.getUserId();
if (userId != null) {
  // User đã login
  print('User ID: $userId');
} else {
  // User chưa login, redirect to login screen
}

// 3. Kiểm tra login status:
final isLoggedIn = await AuthService.isLoggedIn();
if (isLoggedIn) {
  // Show main screen
} else {
  // Show login screen
}

// 4. Lấy thông tin user:
final userInfo = await AuthService.getUserInfo();
if (userInfo != null) {
  print('Name: ${userInfo['name']}');
  print('Email: ${userInfo['email']}');
}

// 5. Khi logout:
await AuthService.logout();
Navigator.pushReplacementNamed(context, '/login');

// 6. Kiểm tra admin:
final isAdmin = await AuthService.isAdmin();
if (isAdmin) {
  // Show admin features
}
*/