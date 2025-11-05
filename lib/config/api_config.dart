// lib/config/api_config.dart

/// File cấu hình API
/// Chỉ cần thay đổi URL ở đây, toàn bộ app sẽ cập nhật
class ApiConfig {
  // ============================================
  // CẤU HÌNH CHÍNH - THAY ĐỔI Ở ĐÂY
  // ============================================
  
  /// Base URL của API trên Google Cloud
  /// Ví dụ: 
  /// - 'https://your-project.appspot.com'
  /// - 'https://your-backend-url.run.app'
  /// - 'http://localhost:3000' (cho development)
  static const String baseUrl = 'https://suaxe-api.as.r.appspot.com';
  
  /// Có sử dụng /api prefix hay không
  static const bool useApiPrefix = true;
  
  /// Timeout cho các request (giây)
  static const int timeoutSeconds = 30;
  
  // ============================================
  // ENDPOINTS - TỰ ĐỘNG TẠO TỪ BASE URL
  // ============================================
  
  static String get _apiPrefix => useApiPrefix ? '/api' : '';
  
  /// Endpoint cho dịch vụ
  static String get servicesUrl => '$baseUrl$_apiPrefix/services';
  
  /// Endpoint cho booking
  static String get bookingUrl => '$baseUrl$_apiPrefix/booking';
  
  /// Endpoint cho user
  static String get userUrl => '$baseUrl$_apiPrefix/users';
  
  /// Endpoint cho mechanics
  static String get mechanicsUrl => '$baseUrl$_apiPrefix/mechanics';
  
  /// Endpoint cho schedules
  static String get schedulesUrl => '$baseUrl$_apiPrefix/schedules';
  
  /// Endpoint cho revenue
  static String get revenueUrl => '$baseUrl$_apiPrefix/revenue';
  
  /// Endpoint cho auth
  static String get authUrl => '$baseUrl$_apiPrefix/auth';
  
  /// Endpoint cho profile
  static String get profileUrl => '$baseUrl$_apiPrefix/profile';
  
  /// Endpoint cho images
  static String get imageUrl => '$baseUrl$_apiPrefix/images';
  
  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Lấy URL đầy đủ cho service theo ID
  static String getServiceDetailUrl(int serviceId) {
    return '$servicesUrl/$serviceId';
  }
  
  /// Lấy URL đầy đủ cho booking theo ID
  static String getBookingDetailUrl(int bookingId) {
    return '$bookingUrl/$bookingId';
  }
  
  /// Kiểm tra có phải đang ở môi trường development không
  static bool get isDevelopment {
    return baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1');
  }
  
  /// In ra tất cả endpoints (dùng để debug)
  static void printAllEndpoints() {
    print('=== API ENDPOINTS ===');
    print('Base URL: $baseUrl');
    print('Services: $servicesUrl');
    print('Booking: $bookingUrl');
    print('User: $userUrl');
    print('Mechanics: $mechanicsUrl');
    print('Schedules: $schedulesUrl');
    print('Revenue: $revenueUrl');
    print('Auth: $authUrl');
    print('Profile: $profileUrl');
    print('Image: $imageUrl');
    print('Development mode: $isDevelopment');
    print('====================');
  }
}

// ============================================
// CÁC CONSTANT KHÁC
// ============================================

/// Header mặc định cho các request
class ApiHeaders {
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// Header với authentication token
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}

/// HTTP Status Codes
class HttpStatus {
  static const int ok = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int internalServerError = 500;
}