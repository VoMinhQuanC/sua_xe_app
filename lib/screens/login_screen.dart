// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';
import 'Technician/technician_main_page.dart';
import 'register_screen.dart';
import '../services/api/api_service.dart';
import '../services/google_sign_in_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  bool _loading = false;
  bool _googleLoading = false;
  final storage = const FlutterSecureStorage();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// Load thông tin đăng nhập đã lưu
  Future<void> _loadSavedCredentials() async {
    try {
      final savedUsername = await storage.read(key: 'saved_username');
      final savedPassword = await storage.read(key: 'saved_password');
      final rememberMe = await storage.read(key: 'remember_me');
      
      if (savedUsername != null && savedPassword != null && rememberMe == 'true') {
        setState(() {
          _usernameController.text = savedUsername;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
        print('✅ Đã load thông tin đăng nhập đã lưu');
      }
    } catch (e) {
      print('❌ Lỗi load credentials: $e');
    }
  }

  /// Lưu thông tin đăng nhập
  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await storage.write(key: 'saved_username', value: _usernameController.text.trim());
      await storage.write(key: 'saved_password', value: _passwordController.text.trim());
      await storage.write(key: 'remember_me', value: 'true');
      print('✅ Đã lưu thông tin đăng nhập');
    } else {
      await storage.delete(key: 'saved_username');
      await storage.delete(key: 'saved_password');
      await storage.delete(key: 'remember_me');
      print('🗑️ Đã xóa thông tin đăng nhập đã lưu');
    }
  }

  /// ✅ THÊM: Helper navigate dựa theo role
  Future<void> _navigateBasedOnRole() async {
    // Lấy roleId từ AuthService
    final userInfo = await AuthService.getUserInfo();
    final roleId = userInfo?['roleId'];
    
    print('🔍 RoleID: $roleId');
    
    if (!mounted) return;
    
    // RoleID = 3 → Mechanic/Technician
    if (roleId == 3) {
      print('✅ Navigate đến TechnicianMainPage (Mechanic)');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TechnicianMainPage()),
      );
    } else {
      // RoleID khác → User
      print('✅ Navigate đến MainPage (User)');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final userCredential = await _googleSignInService.signInWithGoogle();
      if (userCredential != null && userCredential.user != null) {
        final api = ApiService();
        final idToken = await userCredential.user!.getIdToken();
        if (idToken == null) throw Exception('Failed to get ID token');
        final res = await api.firebaseAuth(idToken);
        
        if (res.statusCode == 200 && res.data != null) {
          final token = res.data['token'] ?? res.data['accessToken'] ?? res.data['data']?['token'];
          if (token != null) {
            // Lưu token vào SecureStorage
            const storage = FlutterSecureStorage();
            await storage.write(key: 'auth_token', value: token.toString());
            print('✅ Đã lưu token vào SecureStorage (Google)');
          }
          
          // Lưu userId và user info
          final userId = res.data['user']?['id'] ??
                         res.data['userId'] ??
                         res.data['UserID'] ??
                         res.data['user_id'] ??
                         res.data['id'];
          
          if (userId != null) {
            await AuthService.saveUserId(userId is int ? userId : int.parse(userId.toString()));
            
            await AuthService.saveUserInfo(
              userId: userId is int ? userId : int.parse(userId.toString()),
              email: res.data['user']?['email'] ??
                    res.data['email'] ?? 
                    userCredential.user!.email ?? 
                    '',
              name: res.data['user']?['fullName'] ??
                    res.data['fullName'] ?? 
                    res.data['name'] ?? 
                    res.data['FullName'] ??
                    res.data['data']?['fullName'] ?? 
                    res.data['data']?['FullName'] ??
                    userCredential.user!.displayName ?? 
                    'Khách hàng',
              roleId: res.data['user']?['role'] ??
                      res.data['roleId'] ?? 
                      res.data['role'],
              phoneNumber: res.data['user']?['phoneNumber'] ??
                          res.data['phoneNumber'],
              avatarUrl: res.data['user']?['avatarUrl'] ??
                        res.data['user']?['ProfilePicture'] ??
                        res.data['avatarUrl'] ??
                        res.data['ProfilePicture'],
            );
            
            print('🔍 Debug sau khi đăng nhập Google:');
            await AuthService.debugPrintUserInfo();
          }
          
          // Gửi FCM token lên server sau khi login
          await NotificationService().sendFCMTokenWithAuth(token.toString());
          
          // ✅ FIX: Navigate dựa theo role
          if (!mounted) return;
          await _navigateBasedOnRole();
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập Google không thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập Google: $e')),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _login() async {
    print('======================================');
    print('🚀 _login() được gọi');
    print('======================================');
    
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    
    print('📧 Username: $username');

    if (username.isEmpty || password.isEmpty) {
      print('❌ Username hoặc password trống');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên đăng nhập và mật khẩu")),
      );
      return;
    }

    setState(() => _loading = true);
    print('⏳ Đang gọi API login...');
    
    final api = ApiService();
    try {
      final res = await api.login(username, password);
      print('📩 Response status: ${res.statusCode}');
      print('📩 Response từ API login: ${res.data}');
      
      if (res.statusCode == 200 && res.data != null) {
        final token = res.data['token'] ?? res.data['accessToken'] ?? res.data['data']?['token'];
        if (token != null) {
          await api.saveToken(token.toString());
          const storage = FlutterSecureStorage();
          await storage.write(key: 'auth_token', value: token.toString());
          print('✅ Đã lưu token vào SecureStorage');
        }
        
        // Lấy userId
        final userId = res.data['user']?['id'] ??
                       res.data['userId'] ?? 
                       res.data['UserID'] ?? 
                       res.data['user_id'] ??
                       res.data['id'] ??
                       res.data['data']?['userId'] ??
                       res.data['data']?['UserID'];
        
        print('🔍 userId từ API: $userId');
        
        if (userId != null) {
          print('⏳ Đang lưu userId: $userId');
          
          await AuthService.saveUserId(userId is int ? userId : int.parse(userId.toString()));
          await Future.delayed(const Duration(milliseconds: 100));
          
          // ✅ QUAN TRỌNG: Lưu roleId từ response
          final roleId = res.data['user']?['role'] ??
                        res.data['user']?['roleId'] ??
                        res.data['user']?['RoleID'] ??
                        res.data['roleId'] ?? 
                        res.data['RoleID'] ??
                        res.data['role'] ?? 
                        res.data['data']?['roleId'];
          
          print('🔍 roleId từ API: $roleId');
          
          await AuthService.saveUserInfo(
            userId: userId is int ? userId : int.parse(userId.toString()),
            email: res.data['user']?['email'] ??
                  res.data['email'] ?? 
                  res.data['Email'] ??
                  res.data['data']?['email'] ?? 
                  '',
            name: res.data['user']?['fullName'] ??
                  res.data['fullName'] ?? 
                  res.data['FullName'] ??
                  res.data['name'] ?? 
                  res.data['data']?['fullName'] ?? 
                  res.data['data']?['FullName'] ?? 
                  'Khách hàng',
            roleId: roleId,
            phoneNumber: res.data['user']?['phoneNumber'] ??
                        res.data['phoneNumber'] ??
                        res.data['PhoneNumber'],
            avatarUrl: res.data['user']?['avatarUrl'] ??
                      res.data['user']?['ProfilePicture'] ??
                      res.data['avatarUrl'] ??
                      res.data['ProfilePicture'],
          );
          
          // Debug: Kiểm tra lại thông tin đã lưu
          print('🔍 Debug sau khi lưu thông tin:');
          await AuthService.debugPrintUserInfo();
          
          final savedUserId = await AuthService.getUserId();
          print('🔍 userId sau khi lưu: $savedUserId');
          
          if (savedUserId == null) {
            throw Exception('Lưu userId thất bại');
          }
          
          print('✅ Lưu thông tin thành công!');
        } else {
          print('❌ Không tìm thấy userId trong response');
          throw Exception('Không tìm thấy userId trong response từ server');
        }
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        
        // Lưu thông tin đăng nhập nếu checkbox được chọn
        await _saveCredentials();
        await Future.delayed(const Duration(milliseconds: 500));

        // THÊM DELAY để đảm bảo token đã lưu
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Gửi FCM token lên server sau khi login
        await NotificationService().sendFCMTokenWithAuth(token.toString());
        // ✅ FIX: Navigate dựa theo role
        await _navigateBasedOnRole();
        return;
      }
      
      final message = res.data != null && res.data['message'] != null 
          ? res.data['message'].toString() 
          : 'Đăng nhập không thành công';
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      print('❌ Lỗi khi đăng nhập: $e');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/images/logo1.png', height: 120),
              const SizedBox(height: 20),

              const Text(
                "Đăng nhập VQTBike",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 30),

              // Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Tên đăng nhập",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Remember Me Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    activeColor: Colors.redAccent,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _rememberMe = !_rememberMe;
                      });
                    },
                    child: const Text(
                      'Ghi nhớ đăng nhập',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Đăng nhập",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Hoặc"),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 16),

              // Google Sign In
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _googleLoading ? null : _handleGoogleSignIn,
                  icon: _googleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const FaIcon(FontAwesomeIcons.google, size: 20),
                  label: const Text("Đăng nhập với Google"),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có tài khoản? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      "Đăng ký ngay",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}