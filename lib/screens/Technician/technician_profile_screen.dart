// lib/screens/Technician/technician_profile_screen.dart
// Profile screen động - Load từ API

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:suaxe_app/config/api_config.dart';
import '../login_screen.dart';
import 'techician_profile/technician_edit_profile_screen.dart';
import 'technician_work_history_screen.dart';
import 'technician_settings_screen.dart';
import 'technician_help_screen.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  State<TechnicianProfileScreen> createState() => _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  final storage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  String _fullName = '';
  String _employeeId = '';
  String _phoneNumber = '';
  String? _avatarUrl;
  
  // Stats
  int _totalJobs = 0;
  int _completedJobs = 0;
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Load profile data từ API
  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        _showError('Phiên đăng nhập đã hết hạn');
        _logout();
        return;
      }

      // Call API lấy profile
      await _fetchProfile(token);
      
      // Call API lấy stats
      await _fetchStats(token);
      
    } catch (e) {
      print('❌ Error loading profile: $e');
      _showError('Lỗi khi tải thông tin: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Fetch profile info
  Future<void> _fetchProfile(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📋 Profile response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        final user = data['user'];
        
        setState(() {
          _fullName = user['fullName'] ?? 'Kỹ Thuật Viên';
          _employeeId = 'TECH${user['userId'].toString().padLeft(3, '0')}';
          _phoneNumber = user['phoneNumber'] ?? '';
          _avatarUrl = user['avatarUrl'];
        });
        
        print('✅ Profile loaded: $_fullName');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  /// Fetch stats
  Future<void> _fetchStats(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/stats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📊 Stats response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        final stats = data['stats'];
        
        setState(() {
          _totalJobs = stats['totalJobs'] ?? 0;
          _completedJobs = stats['completedJobs'] ?? 0;
          _rating = (stats['rating'] ?? 0.0).toDouble();
        });
        
        print('✅ Stats loaded: Total=$_totalJobs, Completed=$_completedJobs');
      }
    } else if (response.statusCode == 403) {
      // Không phải mechanic, dùng mock data
      setState(() {
        _totalJobs = 0;
        _completedJobs = 0;
        _rating = 0.0;
      });
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _logout() async {
    await storage.deleteAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        automaticallyImplyLeading: false,
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header với thông tin kỹ thuật viên
                    _buildHeader(),

                    // Thống kê
                    _buildStats(),

                    // Menu
                    _buildMenu(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          _avatarUrl != null && _avatarUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_avatarUrl!),
                  backgroundColor: Colors.white,
                )
              : const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.redAccent,
                  ),
                ),
          const SizedBox(height: 16),
          
          // Tên
          Text(
            _fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          
          // Mã NV
          Text(
            'Mã NV: $_employeeId',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Tổng công việc',
            _totalJobs.toString(),
            Icons.work,
            Colors.blue,
          ),
          _buildStatItem(
            'Đã hoàn thành',
            _completedJobs.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatItem(
            'Đánh giá',
            _rating.toStringAsFixed(1),
            Icons.star,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.edit,
            title: 'Chỉnh sửa thông tin',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TechnicianEditProfileScreen(),
                ),
              );
              
              // Reload profile nếu có update
              if (result == true) {
                _loadProfile();
              }
            },
          ),
          _buildMenuTile(
            icon: Icons.history,
            title: 'Lịch sử công việc',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TechnicianWorkHistoryScreen(),
                ),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.settings,
            title: 'Cài đặt',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TechnicianSettingsScreen(),
                ),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.help_outline,
            title: 'Trợ giúp',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TechnicianHelpScreen(),
                ),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.logout,
            title: 'Đăng xuất',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.redAccent,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}