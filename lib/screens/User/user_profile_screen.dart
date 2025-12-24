import 'package:flutter/material.dart';
import 'package:suaxe_app/screens/User/booking/my_booking_screen.dart';
import 'package:suaxe_app/screens/User/booking/user_booking_screen.dart';
import 'package:suaxe_app/screens/User/profile/edit_profile_screen.dart';
import 'package:suaxe_app/services/auth_service.dart';
import 'package:suaxe_app/screens/User/vehicles/my_vehicle_screen.dart';
import '../../widgets/notification_bell.dart';
// ✅ THÊM IMPORT HELP SCREEN
import 'package:suaxe_app/screens/User/user_help_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cá nhân',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        automaticallyImplyLeading: false,
        actions: [
          const NotificationBell(),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService.getUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final userInfo = snapshot.data;
          final userName = userInfo?['name'] ?? 'Người dùng';
          final userEmail = userInfo?['email'] ?? '';
          final userId = userInfo?['userId'];
          final avatarUrl = userInfo?['avatarUrl'];
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
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
                       CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage('https://suaxeweb-production.up.railway.app/$avatarUrl')
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.redAccent,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Menu items
                if (userId != null) ...[
                  _buildMenuTile(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Lịch hẹn của tôi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyBookingsScreen(userId: userId),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.add_circle_outline,
                    title: 'Đặt lịch mới',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserBookingScreen(userId: userId),
                        ),
                      );
                    },
                  ),
                ],
                
                _buildMenuTile(
                  context,
                  icon: Icons.person_outline,
                  title: 'Thông tin cá nhân',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                
                if (userId != null)
                  _buildMenuTile(
                    context,
                    icon: Icons.two_wheeler,
                    title: 'Xe của tôi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyVehiclesScreen(userId: userId),
                        ),
                      );
                    },
                  ),

                _buildMenuTile(
                  context,
                  icon: Icons.settings,
                  title: 'Cài đặt',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng đang phát triển'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                
                // ✅ THAY ĐỔI: Navigate đến UserHelpScreen thay vì snackbar
                _buildMenuTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Trợ giúp',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserHelpScreen(),
                      ),
                    );
                  },
                ),
                
                _buildMenuTile(
                  context,
                  icon: Icons.logout,
                  title: 'Đăng xuất',
                  isDestructive: true,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận'),
                        content: const Text('Bạn có chắc muốn đăng xuất?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true && context.mounted) {
                      await AuthService.logout();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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