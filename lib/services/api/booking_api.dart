// lib/services/api/booking_api.dart

import 'package:dio/dio.dart';
import '../api_service.dart';
import '../../config/api_config.dart';
import '../../models/booking_model.dart';

/// Booking API
class BookingApi {
  final ApiService _apiService;

  BookingApi({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  /// Tạo booking mới
  Future<Response> createBooking({
    required int serviceId,
    required DateTime bookingDate,
    String? notes,
  }) async {
    return await _apiService._dio.post(
      ApiConfig.bookingUrl,
      data: {
        'ServiceId': serviceId,
        'BookingDate': bookingDate.toIso8601String(),
        'Notes': notes,
      },
    );
  }

  /// Lấy danh sách booking của user
  Future<Response> getUserBookings() async {
    return await _apiService._dio.get(
      ApiConfig.userBookingsUrl,
    );
  }

  /// Lấy chi tiết booking
  Future<Response> getBookingDetail(int bookingId) async {
    return await _apiService._dio.get(
      ApiConfig.getBookingDetailUrl(bookingId),
    );
  }

  /// Hủy booking
  Future<Response> cancelBooking(int bookingId) async {
    return await _apiService._dio.put(
      ApiConfig.getBookingDetailUrl(bookingId),
      data: {
        'Status': 'cancelled',
      },
    );
  }

  /// Update booking status (cho mechanic)
  Future<Response> updateBookingStatus(
    int bookingId,
    BookingStatus status,
  ) async {
    return await _apiService._dio.put(
      ApiConfig.getBookingDetailUrl(bookingId),
      data: {
        'Status': status.name,
      },
    );
  }
}