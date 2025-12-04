import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:suaxe_app/services/api/profile_api_service.dart';
import 'package:suaxe_app/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  bool _isEditing = false; // Trạng thái chỉnh sửa

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Dùng AuthService thay vì đọc trực tiếp từ SharedPreferences
      final userInfo = await AuthService.getUserInfo();
      
      print('🔍 User info từ AuthService: $userInfo');
      
      if (userInfo != null) {
        setState(() {
          _userData = userInfo;
          _fullNameController.text = userInfo['name'] ?? '';
          _phoneController.text = userInfo['phone'] ?? '';
          _emailController.text = userInfo['email'] ?? '';
        });
        
        print('✅ Loaded: Name=${_fullNameController.text}, Phone=${_phoneController.text}, Email=${_emailController.text}');
      } else {
        print('❌ Không tìm thấy user info');
      }
    } catch (e) {
      print('❌ Lỗi khi tải thông tin: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gọi API update profile (không có address nữa)
      await ProfileApiService.updateProfile(
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        address: null, // Bỏ địa chỉ
      );

      // ✅ Cập nhật lại vào AuthService
      if (_userData != null) {
        await AuthService.saveUserInfo(
          userId: _userData!['userId'],
          email: _userData!['email'],
          name: _fullNameController.text, // Tên mới
          roleId: _userData!['roleId'],
          phoneNumber: _phoneController.text, // Số điện thoại mới
        );
        
        // ✅ Lưu số điện thoại (vì AuthService chưa có field này)
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setString('user_phone', _phoneController.text);
        
        print('✅ Đã cập nhật: Name=${_fullNameController.text}, Phone=${_phoneController.text}');
      }

      if (mounted) {
        setState(() {
          _isEditing = false; // Tắt chế độ edit sau khi lưu thành công
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công'),
            backgroundColor: Colors.green,
          ),
        );
        // Bỏ Navigator.pop - giữ lại màn hình này
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'Thông tin cá nhân',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Nút Chỉnh sửa / Hủy
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                tooltip: 'Chỉnh sửa',
              )
            else
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _loadUserData(); // Load lại data ban đầu
                  });
                },
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              border: Border.all(
                                color: Colors.redAccent,
                                width: 3,
                              ),
                              // ← THÊM avatar background
                              image: _userData?['avatarUrl'] != null && _userData!['avatarUrl'].toString().isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage('https://suaxeweb-production.up.railway.app/${_userData!['avatarUrl']}'),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _userData?['avatarUrl'] == null || _userData!['avatarUrl'].toString().isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.redAccent,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Họ và tên
                    const Text(
                      'Họ và tên *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      enabled: _isEditing, // Khóa khi không edit
                      decoration: InputDecoration(
                        hintText: 'Nhập họ và tên',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _isEditing ? Colors.grey.shade50 : Colors.grey.shade200, // Đổi màu khi khóa
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Số điện thoại
                    const Text(
                      'Số điện thoại *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      enabled: _isEditing, // Khóa khi không edit
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Nhập số điện thoại',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _isEditing ? Colors.grey.shade50 : Colors.grey.shade200, // Đổi màu khi khóa
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                          return 'Số điện thoại không hợp lệ';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Email
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        helperText: 'Email không thể thay đổi',
                        helperStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nút lưu - chỉ hiện khi đang edit
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Lưu thông tin',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}