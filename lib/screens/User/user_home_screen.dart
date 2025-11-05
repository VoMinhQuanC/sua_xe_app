import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/service_card.dart';

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

  @override
  void initState() {
    super.initState();
    // Tự động chuyển ảnh banner sau mỗi 3 giây
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(
  backgroundColor: Colors.redAccent,
  automaticallyImplyLeading: false, // bỏ nút back mặc định nếu có
  title: Row(
    children: [
      Image.asset(
        'assets/images/logo1.png',
        height: 40, // chỉnh kích thước logo
      ),
      const SizedBox(width: 10),
      const Text(
        "VQT Bike Service",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    ],
  ),
  centerTitle: false, // để tiêu đề nằm bên trái
),


      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 Banner chuyển động
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _bannerImages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return Image.asset(
                        _bannerImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                Container(
                  height: 220,
                  color: Colors.black45,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "UY TÍN - CHẤT LƯỢNG - MINH BẠCH",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Cam kết không phát sinh chi phí ngoài dự kiến",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                // Dấu chấm tròn báo vị trí banner
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
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.redAccent
                              : Colors.white70,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Dịch vụ
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "DỊCH VỤ CỦA CHÚNG TÔI",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: const [
                ServiceCard(
                  title: "Thay nhớt",
                  image: "assets/images/h4.jpg",
                  desc: "Giúp động cơ vận hành êm ái hơn.",
                ),
                ServiceCard(
                  title: "Bảo dưỡng tổng thể",
                  image: "assets/images/h2.jpg",
                  desc: "Tăng tuổi thọ và hiệu suất xe.",
                ),
                ServiceCard(
                  title: "Sửa phanh",
                  image: "assets/images/h3.jpg",
                  desc: "Đảm bảo an toàn khi di chuyển.",
                ),
                ServiceCard(
                  title: "Rửa xe",
                  image: "assets/images/h7.jpg",
                  desc: "Xe sạch bóng như mới.",
                ),
              ],
            ),

            // Quy trình sửa xe
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "QUY TRÌNH SỬA XE",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildStep(
                    step: "1",
                    icon: Icons.phone_in_talk,
                    title: "TIẾP NHẬN",
                    desc: "Nhận thông tin và xác nhận đặt lịch. (≈ 5 phút)",
                  ),
                  _buildStep(
                    step: "2",
                    icon: Icons.inventory_2,
                    title: "CHUẨN BỊ",
                    desc: "Chuẩn bị vật tư và nhân sự. (≈ 10 phút)",
                  ),
                  _buildStep(
                    step: "3",
                    icon: Icons.task,
                    title: "PHÂN CÔNG",
                    desc: "Phân công công việc cho kỹ thuật viên. (≈ 15 phút)",
                  ),
                  _buildStep(
                    step: "4",
                    icon: Icons.build,
                    title: "TRIỂN KHAI",
                    desc: "Sửa chữa theo nhu cầu của khách hàng. (≈ 30–60 phút)",
                  ),
                  _buildStep(
                    step: "5",
                    icon: Icons.fact_check,
                    title: "KIỂM TRA",
                    desc: "Kiểm tra tổng thể lần cuối, khắc phục lỗi nhỏ. (≈ 15 phút)",
                  ),
                  _buildStep(
                    step: "6",
                    icon: Icons.receipt_long,
                    title: "BÀN GIAO",
                    desc: "Xuất phiếu dịch vụ và thanh toán minh bạch. (≈ 10 phút)",
                  ),
                  _buildStep(
                    step: "7",
                    icon: Icons.support_agent,
                    title: "HẬU MÃI",
                    desc: "Gọi điện chăm sóc khách hàng và nhận góp ý. (≈ 5 phút)",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
        
          ],
        ),
      ),
    );
  }

  // Widget hiển thị từng bước quy trình
  Widget _buildStep({
    required String step,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bước $step: $title",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
