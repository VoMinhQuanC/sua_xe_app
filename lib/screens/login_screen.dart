import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';
import 'Technician/technician_main_page.dart';
import 'register_screen.dart';
import '../services/api/api_service.dart';
import '../services/google_sign_in_service.dart';
import '../services/auth_service.dart';

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

            
            // ✅ LƯU TOKEN VÀO FLUTTER_SECURE_STORAGE
            const storage = FlutterSecureStorage();
            await storage.write(key: 'auth_token', value: token.toString());
            print('✅ Đã lưu token vào SecureStorage (Google)');
          }
          
          // ✅ FIX: Lưu userId và user info - Lấy từ user.id
          final userId = res.data['user']?['id'] ??     // ← FIX: Thêm user.id
                         res.data['userId'] ??
                         res.data['UserID'] ??
                         res.data['user_id'] ??
                         res.data['id'];
          
          if (userId != null) {
            // ✅ QUAN TRỌNG: Lưu userId riêng trước
            await AuthService.saveUserId(userId is int ? userId : int.parse(userId.toString()));
            
            await AuthService.saveUserInfo(
              userId: userId is int ? userId : int.parse(userId.toString()),
              email: res.data['user']?['email'] ??      // ← FIX: Lấy từ user.email
                     res.data['email'] ?? 
                     userCredential.user!.email ?? 
                     '',
              name: res.data['user']?['fullName'] ??    // ← FIX: Lấy từ user.fullName
                    res.data['fullName'] ?? 
                    res.data['name'] ?? 
                    res.data['FullName'] ??
                    res.data['data']?['fullName'] ?? 
                    res.data['data']?['FullName'] ??
                    userCredential.user!.displayName ?? 
                    'Khách hàng',
              roleId: res.data['user']?['role'] ??      // ← FIX: Lấy từ user.role
                      res.data['roleId'] ?? 
                      res.data['role'],
            );
            
            // ✅ Debug: In ra thông tin đã lưu
            print('🔍 Debug sau khi đăng nhập Google:');
            await AuthService.debugPrintUserInfo();
          }
          
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
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
          // ✅ LƯU TOKEN VÀO FLUTTER_SECURE_STORAGE
          const storage = FlutterSecureStorage();
          await storage.write(key: 'auth_token', value: token.toString());
          print('✅ Đã lưu token vào SecureStorage');
        }
        
        // ✅ FIX: LẤY userId - ƯU TIÊN từ user.id
        final userId = res.data['user']?['id'] ??        // ← FIX: THÊM DÒNG NÀY Ở ĐẦU
                       res.data['userId'] ?? 
                       res.data['UserID'] ?? 
                       res.data['user_id'] ??
                       res.data['id'] ??
                       res.data['data']?['userId'] ??
                       res.data['data']?['UserID'];
        
        print('🔍 userId từ API: $userId');
        
        if (userId != null) {
          print('⏳ Đang lưu userId: $userId');
          
          // ✅ QUAN TRỌNG: Lưu userId và đợi hoàn tất
          await AuthService.saveUserId(userId is int ? userId : int.parse(userId.toString()));
          
          // ✅ Đợi một chút để đảm bảo dữ liệu được lưu
          await Future.delayed(const Duration(milliseconds: 100));
          
          // ✅ FIX: Lưu thông tin user đầy đủ - ƯU TIÊN từ user.*
          await AuthService.saveUserInfo(
            userId: userId is int ? userId : int.parse(userId.toString()),
            email: res.data['user']?['email'] ??        // ← FIX: Thêm user.email
                   res.data['email'] ?? 
                   res.data['Email'] ??
                   res.data['data']?['email'] ?? 
                   '',
            name: res.data['user']?['fullName'] ??      // ← FIX: Thêm user.fullName
                  res.data['fullName'] ?? 
                  res.data['FullName'] ??
                  res.data['name'] ?? 
                  res.data['data']?['fullName'] ?? 
                  res.data['data']?['FullName'] ?? 
                  'Khách hàng',
            roleId: res.data['user']?['role'] ??        // ← FIX: Thêm user.role
                    res.data['roleId'] ?? 
                    res.data['RoleID'] ??
                    res.data['role'] ?? 
                    res.data['data']?['roleId'],
          );
          
          // ✅ Debug: Kiểm tra lại thông tin đã lưu
          print('🔍 Debug sau khi lưu thông tin:');
          await AuthService.debugPrintUserInfo();
          
          // ✅ Kiểm tra lại userId trước khi navigate
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
        
        // ✅ Hiển thị thông báo thành công trước khi navigate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // ✅ Đợi một chút trước khi navigate
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate về trang chủ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
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
      
      // Fallback local cho testing
      if (username == "admin" && password == "123") {
        print('📌 Sử dụng admin local');
        await AuthService.saveUserId(1);
        await Future.delayed(const Duration(milliseconds: 100));
        await AuthService.saveUserInfo(
          userId: 1,
          email: 'admin@localhost',
          name: 'Admin',
          roleId: 1,
        );
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
        return;
      }
      
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
                ),
              ),
              const SizedBox(height: 24),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "Đăng nhập",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Divider with "hoặc" text
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("hoặc"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Google Sign In button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: _googleLoading ? null : _handleGoogleSignIn,
                  icon: _googleLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const FaIcon(
                          FontAwesomeIcons.google,
                          color: Colors.red,
                        ),
                  label: const Text(
                    "Đăng nhập bằng Google",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text("Quên mật khẩu?"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Đăng ký",
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