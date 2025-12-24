import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:suaxe_app/models/payment_model.dart';

class PaymentApiService {
  static const String baseUrl = 'https://suaxeweb-production.up.railway.app';
  static const _secureStorage = FlutterSecureStorage();
  
  /// Lấy QR code cho appointment
  static Future<PaymentQRModel> getPaymentQR(int appointmentId) async {
    try {
      print('🔍 Đang lấy QR code cho appointment $appointmentId...');
      
      final token = await _secureStorage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('$baseUrl/api/payment/qr/$appointmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📩 QR Response: ${response.statusCode}');
      print('📩 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
          print('🔍 Backend bankCode: ${data['data']['bankInfo']['bankCode']}');
        if (data['success'] == true) {
          print('✅ Lấy QR code thành công');
          return PaymentQRModel.fromJson(data);
        }
      }
      
      throw Exception('Không thể lấy QR code thanh toán');
    } catch (e) {
      print('❌ Lỗi khi lấy QR: $e');
      throw Exception('Lỗi khi lấy QR code: $e');
    }
  }

  /// Upload ảnh chứng từ thanh toán
  static Future<PaymentProofUploadResponse> uploadPaymentProof({
    required int appointmentId,
    required File imageFile,
  }) async {
    try {
      print('🔍 Đang upload chứng từ cho appointment $appointmentId...');
      
      final token = await _secureStorage.read(key: 'auth_token');
      
      // Sử dụng Dio để upload multipart
      final dio = Dio();
      
      // Tạo FormData
      final formData = FormData.fromMap({
        'appointmentId': appointmentId.toString(),
        'proofImage': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'payment_proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await dio.post(
        '$baseUrl/api/payment-proof/upload',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      print('📩 Upload response: ${response.statusCode}');
      print('📩 Body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Upload chứng từ thành công');
        return PaymentProofUploadResponse.fromJson(response.data);
      }
      
      throw Exception('Không thể upload chứng từ');
    } catch (e) {
      print('❌ Lỗi khi upload: $e');
      throw Exception('Lỗi khi upload chứng từ: $e');
    }
  }

  /// Kiểm tra trạng thái thanh toán
  static Future<String> checkPaymentStatus(int appointmentId) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('$baseUrl/api/booking/appointments/$appointmentId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final appointment = data['appointment'] ?? data['data'];
          return appointment['Status'] ?? 'Pending';
        }
      }
      
      return 'Unknown';
    } catch (e) {
      print('❌ Lỗi khi kiểm tra status: $e');
      return 'Unknown';
    }
  }
}