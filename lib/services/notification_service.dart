import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Background handler - Phải ở top level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();
  
  static const String baseUrl = 'https://suaxeweb-production.up.railway.app';
  
  // ==================== INITIALIZATION ====================
  
  /// Khởi tạo FCM và local notifications
  Future<void> initialize() async {
    print('🔔 Initializing notification service...');
    
    // 1. Request permission
    await _requestPermission();
    
    // 2. Initialize local notifications
    await _initLocalNotifications();
    
    // 3. Setup FCM handlers
    _setupFCMHandlers();
    
    // 4. Get FCM token
    await _getFCMToken();
    
    print('✅ Notification service initialized');
  }
  
  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    print('📱 Permission status: ${settings.authorizationStatus}');
  }
  
  /// Initialize local notifications
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    print('✅ Local notifications initialized');
  }
  
  /// Setup FCM message handlers
  void _setupFCMHandlers() {
    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Foreground handler (khi app đang mở)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      
      // Hiển thị notification local
      _showLocalNotification(
        title: message.notification?.title ?? 'Thông báo',
        body: message.notification?.body ?? '',
        payload: json.encode(message.data),
      );
    });
    
    // Notification opened handler (khi user tap vào notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification opened: ${message.data}');
      _handleNotificationOpen(message.data);
    });
  }
  
  /// Get FCM token và gửi lên server
  Future<String?> _getFCMToken() async {
    try {
      final token = await _fcm.getToken();
      
      if (token != null) {
        print('📱 FCM Token: ${token.substring(0, 20)}...');
        
        // Lưu token
        await _storage.write(key: 'fcm_token', value: token);
        
        // Gửi token lên server
        await _sendTokenToServer(token);
      }
      
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }
  
  /// Gửi FCM token lên server
  Future<void> _sendTokenToServer(String token) async {
    try {
      final authToken = await _storage.read(key: 'token');
      
      if (authToken == null) {
        print('⚠️ No auth token, skip sending FCM token');
        return;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/fcm/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'fcmToken': token}),
      );
      
      if (response.statusCode == 200) {
        print('✅ FCM token sent to server');
      } else {
        print('⚠️ Failed to send FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending FCM token: $e');
    }
  }
  
  // ==================== LOCAL NOTIFICATIONS ====================
  
  /// Hiển thị local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'vqt_bike_channel',
      'VQT Bike Notifications',
      channelDescription: 'Thông báo từ VQT Bike Service',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF5252), // Red accent
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  /// Xử lý khi user tap vào notification
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationOpen(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }
  
  /// Xử lý mở notification
  void _handleNotificationOpen(Map<String, dynamic> data) {
    print('📂 Handle notification open: $data');
    
    // TODO: Navigate to appropriate screen based on notification type
    final type = data['type'];
    final referenceId = data['referenceId'];
    
    switch (type) {
      case 'appointment':
        // Navigate to appointment detail
        print('→ Navigate to appointment $referenceId');
        break;
      case 'payment':
        // Navigate to payment
        print('→ Navigate to payment');
        break;
      default:
        print('→ Unknown notification type: $type');
    }
  }
  
  // ==================== IN-APP NOTIFICATIONS ====================
  
  /// Lấy danh sách thông báo in-app
  /// Lấy danh sách thông báo in-app
  Future<List<Map<String, dynamic>>> getInAppNotifications() async {
    try {
      print('');
      print('=================================');
      print('🔔 [NOTIF] Getting notifications...');
      print('=================================');
      
      // Check ALL keys in storage
      final allKeys = await _storage.readAll();
      print('📦 [NOTIF] All keys: ${allKeys.keys.toList()}');
      
      // Try DIFFERENT token key names
      final token1 = await _storage.read(key: 'token');
      final token2 = await _storage.read(key: 'auth_token');
      final token3 = await _storage.read(key: 'access_token');
      final token4 = await _storage.read(key: 'authToken');
      
      print('🔑 [NOTIF] Checking tokens:');
      if (token1 != null) print('   ✅ token: ${token1.substring(0, min(20, token1.length))}...');
      if (token2 != null) print('   ✅ auth_token: ${token2.substring(0, min(20, token2.length))}...');
      if (token3 != null) print('   ✅ access_token: ${token3.substring(0, min(20, token3.length))}...');
      if (token4 != null) print('   ✅ authToken: ${token4.substring(0, min(20, token4.length))}...');
      
      // Use WHICHEVER token exists
      final authToken = token1 ?? token2 ?? token3 ?? token4;
      
      if (authToken == null) {
        print('❌ [NOTIF] No token found!');
        print('   Available keys: ${allKeys.keys.toList()}');
        print('=================================');
        return [];
      }
      
      print('✅ [NOTIF] Using token');
      
      final url = '$baseUrl/api/notifications?limit=20';
      print('🌐 [NOTIF] API: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      
      print('📡 [NOTIF] Status: ${response.statusCode}');
      print('📦 [NOTIF] Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [NOTIF] Parsed - success: ${data['success']}');
        
        if (data['success'] == true) {
          final List notifications = data['data'] ?? [];
          print('📋 [NOTIF] Count: ${notifications.length}');
          
          if (notifications.isNotEmpty) {
            print('📌 [NOTIF] First notification:');
            print('   - ID: ${notifications[0]['NotificationID']}');
            print('   - Title: ${notifications[0]['Title']}');
            print('   - UserID: ${notifications[0]['UserID']}');
          } else {
            print('⚠️ [NOTIF] Notifications array is empty!');
          }
          
          print('=================================');
          return notifications.cast<Map<String, dynamic>>();
        } else {
          print('⚠️ [NOTIF] success=false');
          print('   Message: ${data['message']}');
        }
      } else {
        print('❌ [NOTIF] Error ${response.statusCode}');
        print('   Body: ${response.body}');
      }
      
      print('=================================');
      return [];
    } catch (e, stack) {
      print('❌ [NOTIF] Exception: $e');
      print('   Stack: $stack');
      print('=================================');
      return [];
    }
  }
  
  /// Lấy số thông báo chưa đọc
  Future<int> getUnreadCount() async {
    try {
      final authToken = await _storage.read(key: 'token');
      
      if (authToken == null) {
        return 0;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }
  
  /// Đánh dấu thông báo đã đọc
  Future<bool> markAsRead(int notificationId) async {
    try {
      print('📖 [NOTIF] Marking as read: $notificationId');
      
      final authToken = await _storage.read(key: 'token');
      
      if (authToken == null) {
        print('❌ [NOTIF] No auth token');
        return false;
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      
      print('📡 [NOTIF] Mark as read status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ [NOTIF] Marked as read successfully');
        return true;
      } else {
        print('❌ [NOTIF] Failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ [NOTIF] Error marking as read: $e');
      return false;
    }
  }
  
  /// Đánh dấu tất cả đã đọc
  Future<bool> markAllAsRead() async {
    try {
      print('📖 [NOTIF] Marking all as read...');
      
      final authToken = await _storage.read(key: 'token');
      
      if (authToken == null) {
        print('❌ [NOTIF] No auth token');
        return false;
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      
      print('📡 [NOTIF] Mark all as read status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ [NOTIF] All marked as read successfully');
        return true;
      } else {
        print('❌ [NOTIF] Failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ [NOTIF] Error marking all as read: $e');
      return false;
    }
  }

  /// Gửi FCM token với auth token cụ thể (dùng sau khi login)
Future<void> sendFCMTokenWithAuth(String authToken) async {
  try {
    final fcmToken = await _fcm.getToken();
    
    if (fcmToken == null) {
      print('❌ No FCM token available');
      return;
    }
    
    print('📤 Sending FCM token with provided auth token...');
    print('📱 FCM Token: ${fcmToken.substring(0, min(20, fcmToken.length))}...');
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/fcm/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',  // ← Token truyền vào trực tiếp!
      },
      body: json.encode({'fcmToken': fcmToken}),
    );
    
    if (response.statusCode == 200) {
      print('✅ FCM token sent to server successfully!');
    } else {
      print('⚠️ Failed to send FCM token: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Error sending FCM token with auth: $e');
  }
}
  
  // ==================== TEST ====================
  
  /// Test notification (dùng để debug)
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from VQT Bike',
      payload: json.encode({'type': 'test', 'message': 'Hello'}),
    );
  }
}