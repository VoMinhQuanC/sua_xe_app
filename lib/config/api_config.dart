// lib/config/api_config.dart
// API Configuration for SuaXe App

import 'package:flutter/foundation.dart';

class ApiConfig {
  // ✅ Railway Production URL
  static const String productionUrl = 'https://suaxeweb-production.up.railway.app/api';
  
  // Local development URL (for emulator)
  static const String localUrl = 'http://10.0.2.2:3001/api';
  
  // ✅ Sử dụng production URL
  // Nếu muốn switch giữa local và production, uncomment dòng dưới:
  // static const String baseUrl = kDebugMode ? localUrl : productionUrl;
  
  static const String baseUrl = productionUrl;  // ← Luôn dùng Railway
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String servicesEndpoint = '/services';
  static const String bookingEndpoint = '/booking';
  
  // Mechanic endpoints
  static const String mechanicSchedulesEndpoint = '/mechanics/schedules';
  static const String mechanicTeamSchedulesEndpoint = '/mechanics/schedules/team';
  
  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Debug: Print current config
  static void printConfig() {
    if (kDebugMode) {
      print('========================================');
      print('📡 API Configuration');
      print('========================================');
      print('Base URL: $baseUrl');
      print('Environment: ${kDebugMode ? 'Development' : 'Production'}');
      print('========================================');
    }
  }
}