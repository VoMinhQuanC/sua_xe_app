import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Thay giá trị này bằng URL API đã deploy của bạn (ví dụ https://PROJECT_ID.uc.r.appspot.com)
  static const String baseUrl = 'https://suaxeweb-production.up.railway.app'; // <-- chỉnh lại

  ApiService._internal(this._dio);

  factory ApiService() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    final service = ApiService._internal(dio);

    // Interceptor: đính kèm token nếu có
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      try {
        final token = await service._storage.read(key: 'auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}
      return handler.next(options);
    }));

    // Log interceptor (giúp debug)
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

    return service;
  }

  Future<Response> login(String email, String password) async {
    return _dio.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  // ⬇️ THÊM METHOD REGISTER
  Future<Response> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required int roleId,
  }) async {
    return _dio.post(
      '/api/auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'roleId': roleId,
      },
    );
  }
  // ⬆️ KẾT THÚC THÊM

  Future<Response> firebaseAuth(String idToken) async {
    return _dio.post('/api/auth/firebase', data: {
      'idToken': idToken,
    });
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<Response> getServices() async {
    return _dio.get('/api/services');
  }

  Future<Response> getProfile() async {
    return _dio.get('/api/users/profile');
  }   

  /// Lấy chi tiết dịch vụ theo ID
  Future<Response> getServiceById(int serviceId) async {
    return _dio.get('/api/services/$serviceId');
  }
}