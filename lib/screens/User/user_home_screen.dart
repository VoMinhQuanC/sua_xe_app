import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/service_card.dart';
import '../../widgets/notification_bell.dart';
import 'package:suaxe_app/screens/User/booking/user_booking_screen.dart';
import 'package:suaxe_app/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _bannerImages = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];

  Timer? _timer;
  
  // ✅ SỐ HOTLINE KHẨN CẤP
  static const String emergencyPhone = '1900123456';
  
  // ✅ ĐỊA CHỈ CỬA HÀNG
  static const String shopAddress = '396 Xa lộ Hà Nội, Phường Tân Phú, Thủ Đức, Hồ Chí Minh, Việt Nam';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < _bannerImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ✅ HÀM GỌI ĐIỆN KHẨN CẤP
  Future<void> _makeEmergencyCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: emergencyPhone);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        print('✅ Calling emergency: $emergencyPhone');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở ứng dụng gọi điện'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error launching phone: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ HÀM MỞ GOOGLE MAPS - FIXED VERSION
  Future<void> _openMaps() async {
    // Dùng geo: URI (Android/iOS native Maps)
    final Uri mapsUri = Uri.parse('geo:0,0?q=$shopAddress');
    
    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
        print('✅ Opening Maps: $shopAddress');
      } else {
        // Fallback: Mở bằng browser nếu không có Maps app
        final encodedAddress = Uri.encodeComponent(shopAddress);
        final Uri browserUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
        
        if (await canLaunchUrl(browserUri)) {
          await launchUrl(browserUri, mode: LaunchMode.externalApplication);
          print('✅ Opening Maps via browser');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể mở Google Maps'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error opening Maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/images/logo1.png', height: 40),
            const SizedBox(width: 10),
            const Text("VQT Bike Service", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        centerTitle: false,
        actions: const [NotificationBell()],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _bannerImages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) => Image.asset(_bannerImages[index], fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                Container(
                  height: 220,
                  color: Colors.black45,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("UY TÍN - CHẤT LƯỢNG - MINH BẠCH", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1), textAlign: TextAlign.center),
                        SizedBox(height: 10),
                        Text("Cam kết không phát sinh chi phí ngoài dự kiến", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _bannerImages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 20 : 8,
                        decoration: BoxDecoration(color: _currentPage == index ? Colors.redAccent : Colors.white70, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.all(16), child: Text("DỊCH VỤ CỦA CHÚNG TÔI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: const [
                ServiceCard(title: "Thay nhớt", image: "assets/images/h4.jpg", desc: "Giúp động cơ vận hành êm ái hơn."),
                ServiceCard(title: "Bảo dưỡng tổng thể", image: "assets/images/h2.jpg", desc: "Tăng tuổi thọ và hiệu suất xe."),
                ServiceCard(title: "Sửa phanh", image: "assets/images/h3.jpg", desc: "Đảm bảo an toàn khi di chuyển."),
                ServiceCard(title: "Rửa xe", image: "assets/images/h7.jpg", desc: "Xe sạch bóng như mới."),
              ],
            ),
            const Padding(padding: EdgeInsets.all(16), child: Text("QUY TRÌNH SỬA XE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildStep(step: "1", icon: Icons.phone_in_talk, title: "TIẾP NHẬN", desc: "Nhận thông tin và xác nhận đặt lịch. (≈ 5 phút)"),
                  _buildStep(step: "2", icon: Icons.inventory_2, title: "CHUẨN BỊ", desc: "Chuẩn bị vật tư và nhân sự. (≈ 10 phút)"),
                  _buildStep(step: "3", icon: Icons.task, title: "PHÂN CÔNG", desc: "Phân công công việc cho kỹ thuật viên. (≈ 15 phút)"),
                  _buildStep(step: "4", icon: Icons.build, title: "TRIỂN KHAI", desc: "Sửa chữa theo nhu cầu của khách hàng. (≈ 30–60 phút)"),
                  _buildStep(step: "5", icon: Icons.fact_check, title: "KIỂM TRA", desc: "Kiểm tra tổng thể lần cuối, khắc phục lỗi nhỏ. (≈ 15 phút)"),
                  _buildStep(step: "6", icon: Icons.receipt_long, title: "BÀN GIAO", desc: "Xuất phiếu dịch vụ và thanh toán minh bạch. (≈ 10 phút)"),
                  _buildStep(step: "7", icon: Icons.support_agent, title: "HẬU MÃI", desc: "Gọi điện chăm sóc khách hàng và nhận góp ý. (≈ 5 phút)"),
                ],
              ),
            ),
            
            // ✅ ĐỊA CHỈ FOOTER
            _buildAddressFooter(),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _makeEmergencyCall,
            heroTag: 'emergency_call',
            icon: const Icon(Icons.phone, size: 24),
            label: const Text('Gọi khẩn cấp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            backgroundColor: Colors.orange,
            elevation: 6,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () async {
              final isLoggedIn = await AuthService.isLoggedIn();
              if (!isLoggedIn) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để đặt lịch'), backgroundColor: Colors.orange));
                return;
              }
              final userId = await AuthService.getUserId();
              if (userId == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại'), backgroundColor: Colors.red));
                return;
              }
              if (!context.mounted) return;
              Navigator.push(context, MaterialPageRoute(builder: (context) => UserBookingScreen(userId: userId)));
            },
            heroTag: 'book_now',
            icon: const Icon(Icons.calendar_today),
            label: const Text('Đặt lịch ngay', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            elevation: 6,
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET ĐỊA CHỈ FOOTER
  Widget _buildAddressFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openMaps,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('LIÊN HỆ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Địa chỉ:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(shopAddress, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, color: Colors.redAccent, size: 14),
                      SizedBox(width: 6),
                      Text('Nhấn để xem bản đồ', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep({required String step, required IconData icon, required String title, required String desc}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: Colors.white, size: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bước $step: $title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}