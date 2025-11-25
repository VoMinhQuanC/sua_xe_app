// File: booking_api_config.dart
// Cấu hình API cho module Booking

class BookingApiConfig {
  // ==================== CẤU HÌNH QUAN TRỌNG ====================
  // TODO: Thay đổi các giá trị sau đây theo môi trường của bạn
  
  /// URL base của API backend
  /// - Development (local): 'http://localhost:3001/api'
  /// - Production (Google Cloud): 'https://your-domain.com/api'
  static const String baseUrl = 'https://suaxeweb-production.up.railway.app'; // TODO: Thay đổi URL này
  
  /// Timeout cho các request API (milliseconds)
  static const int requestTimeout = 30000; // 30 seconds
  
  /// Có log request/response không (chỉ dùng trong development)
  static const bool enableLogging = true;
  
  // ==================== ENDPOINTS ====================
  // Các endpoint API được sử dụng trong module booking
  
  static const String authEndpoint = '/auth';
  static const String servicesEndpoint = '/services';
  static const String bookingEndpoint = '/booking';
  static const String usersEndpoint = '/users';
  static const String vehiclesEndpoint = '/vehicles';
  
  // Booking specific endpoints
  static const String appointmentsEndpoint = '$bookingEndpoint/appointments';
  static const String checkAvailabilityEndpoint = '$bookingEndpoint/check-availability';
  static const String availableSlotsEndpoint = '$bookingEndpoint/available-slots';
  
  // ==================== STATUS CODES ====================
  /// Các mã trạng thái của lịch hẹn
  static const String statusPending = 'Pending';
  static const String statusConfirmed = 'Confirmed';
  static const String statusInProgress = 'In Progress';
  static const String statusCompleted = 'Completed';
  static const String statusCancelled = 'Cancelled';
  
  // ==================== ERROR MESSAGES ====================
  static const String networkErrorMessage = 'Không có kết nối mạng';
  static const String serverErrorMessage = 'Lỗi máy chủ, vui lòng thử lại sau';
  static const String timeoutErrorMessage = 'Yêu cầu hết thời gian chờ';
  static const String unauthorizedErrorMessage = 'Phiên đăng nhập đã hết hạn';
  
  // ==================== VALIDATION ====================
  /// Số lượng ngày tối đa có thể đặt lịch trước
  static const int maxBookingDaysInAdvance = 90;
  
  /// Giờ làm việc
  static const int workingHourStart = 8; // 8:00 AM
  static const int workingHourEnd = 18; // 6:00 PM
  
  /// Các ngày trong tuần có thể đặt lịch (0 = Sunday, 6 = Saturday)
  static const List<int> workingDays = [1, 2, 3, 4, 5, 6]; // Monday to Saturday
  
  // ==================== HELPER METHODS ====================
  
  /// Lấy full URL cho một endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  /// Kiểm tra xem thời gian có trong giờ làm việc không
  static bool isWorkingHours(DateTime dateTime) {
    final hour = dateTime.hour;
    return hour >= workingHourStart && hour < workingHourEnd;
  }
  
  /// Kiểm tra xem ngày có phải ngày làm việc không
  static bool isWorkingDay(DateTime date) {
    return workingDays.contains(date.weekday);
  }
  
  /// Kiểm tra xem có thể đặt lịch vào thời gian này không
  static bool canBookAtDateTime(DateTime dateTime) {
    // Không được đặt lịch trong quá khứ
    if (dateTime.isBefore(DateTime.now())) {
      return false;
    }
    
    // Không được đặt lịch quá xa
    final maxDate = DateTime.now().add(Duration(days: maxBookingDaysInAdvance));
    if (dateTime.isAfter(maxDate)) {
      return false;
    }
    
    // Phải trong giờ làm việc
    if (!isWorkingHours(dateTime)) {
      return false;
    }
    
    // Phải trong ngày làm việc
    if (!isWorkingDay(dateTime)) {
      return false;
    }
    
    return true;
  }
  
  /// Lấy thông báo lỗi khi không thể đặt lịch
  static String getBookingErrorMessage(DateTime dateTime) {
    if (dateTime.isBefore(DateTime.now())) {
      return 'Không thể đặt lịch trong quá khứ';
    }
    
    final maxDate = DateTime.now().add(Duration(days: maxBookingDaysInAdvance));
    if (dateTime.isAfter(maxDate)) {
      return 'Chỉ có thể đặt lịch trước $maxBookingDaysInAdvance ngày';
    }
    
    if (!isWorkingHours(dateTime)) {
      return 'Giờ làm việc từ ${workingHourStart}h đến ${workingHourEnd}h';
    }
    
    if (!isWorkingDay(dateTime)) {
      return 'Chỉ có thể đặt lịch từ Thứ 2 đến Thứ 7';
    }
    
    return 'Không thể đặt lịch vào thời gian này';
  }
}

// ==================== STORAGE KEYS ====================
/// Các key dùng để lưu trữ local (SharedPreferences, SecureStorage, etc.)
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String refreshToken = 'refresh_token';
  static const String isLoggedIn = 'is_logged_in';
}

// ==================== API RESPONSE WRAPPER ====================
/// Wrapper class cho API response
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : json['data'],
      statusCode: json['statusCode'],
    );
  }
}