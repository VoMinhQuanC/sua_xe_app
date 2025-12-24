// lib/screens/User/user_help_screen.dart

import 'package:flutter/material.dart';

class UserHelpScreen extends StatefulWidget {
  const UserHelpScreen({super.key});

  @override
  State<UserHelpScreen> createState() => _UserHelpScreenState();
}

class _UserHelpScreenState extends State<UserHelpScreen> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'Làm thế nào để đặt lịch sửa xe?',
      'answer':
          'Bạn có thể đặt lịch sửa xe bằng cách:\n1. Vào trang chủ, nhấn nút "Đặt lịch ngay"\n2. Chọn loại dịch vụ cần sửa chữa\n3. Chọn ngày và giờ phù hợp\n4. Nhập thông tin xe và mô tả vấn đề\n5. Xác nhận thông tin và gửi yêu cầu\n6. Đợi xác nhận từ cửa hàng',
    },
    {
      'question': 'Làm sao để theo dõi tiến độ sửa xe?',
      'answer':
          'Để theo dõi tiến độ sửa xe:\n1. Vào tab "Lịch hẹn" ở bottom navigation\n2. Xem danh sách lịch hẹn với các trạng thái:\n   - Chờ xác nhận (vàng)\n   - Đã xác nhận (xanh lá)\n   - Đang sửa (cam)\n   - Hoàn thành (xanh dương)\n3. Tap vào lịch hẹn để xem chi tiết tiến độ',
    },
    {
      'question': 'Làm thế nào để thanh toán?',
      'answer':
          'Để thanh toán:\n1. Sau khi công việc hoàn thành, bạn sẽ nhận được thông báo\n2. Vào chi tiết lịch hẹn, nhấn "Thanh toán"\n3. Chọn phương thức thanh toán:\n   - Chuyển khoản ngân hàng (quét mã QR)\n   - Tiền mặt tại cửa hàng\n4. Nếu chuyển khoản, quét mã QR và chuyển khoản\n5. Chụp ảnh biên lai và gửi xác nhận\n6. Đợi admin xác nhận thanh toán',
    },
    {
      'question': 'Làm sao để hủy lịch hẹn?',
      'answer':
          'Để hủy lịch hẹn:\n1. Vào tab "Lịch hẹn"\n2. Chọn lịch hẹn cần hủy (chỉ hủy được lịch "Chờ xác nhận")\n3. Nhấn nút "Hủy lịch"\n4. Nhập lý do hủy\n5. Xác nhận hủy\n\nLưu ý: Chỉ có thể hủy trước 2 giờ so với thời gian hẹn',
    },
    {
      'question': 'Làm thế nào để xem lịch sử sửa xe?',
      'answer':
          'Để xem lịch sử sửa xe:\n1. Vào tab "Cá nhân"\n2. Chọn "Lịch sử sửa chữa"\n3. Xem danh sách các lần sửa xe đã hoàn thành\n4. Tap vào để xem chi tiết:\n   - Dịch vụ đã sử dụng\n   - Chi phí\n   - Kỹ thuật viên\n   - Đánh giá (nếu có)',
    },
    {
      'question': 'Làm sao để đánh giá dịch vụ?',
      'answer':
          'Để đánh giá dịch vụ:\n1. Sau khi hoàn thành và thanh toán\n2. Vào chi tiết lịch hẹn\n3. Nhấn nút "Đánh giá"\n4. Chọn số sao (1-5 sao)\n5. Viết nhận xét (tùy chọn)\n6. Gửi đánh giá\n\nĐánh giá của bạn giúp chúng tôi cải thiện chất lượng dịch vụ!',
    },
    {
      'question': 'Tôi quên mật khẩu, làm sao để đặt lại?',
      'answer':
          'Nếu bạn quên mật khẩu:\n1. Trên màn hình đăng nhập, nhấn "Quên mật khẩu?"\n2. Nhập email hoặc số điện thoại đã đăng ký\n3. Bạn sẽ nhận được mã OTP qua SMS/Email\n4. Nhập mã OTP và tạo mật khẩu mới\n5. Đăng nhập lại với mật khẩu mới',
    },
    {
      'question': 'Làm thế nào để cập nhật thông tin xe?',
      'answer':
          'Để cập nhật thông tin xe:\n1. Vào tab "Cá nhân"\n2. Chọn "Quản lý xe"\n3. Chọn xe cần cập nhật hoặc thêm xe mới\n4. Nhập/sửa thông tin:\n   - Biển số xe\n   - Loại xe\n   - Hãng xe\n   - Màu sắc\n5. Lưu thông tin',
    },
  ];

  final List<Map<String, dynamic>> _contactMethods = [
    {
      'icon': Icons.phone,
      'title': 'Hotline hỗ trợ',
      'subtitle': '1900 1234',
      'color': Colors.green,
      'action': 'call',
    },
    {
      'icon': Icons.email,
      'title': 'Email hỗ trợ',
      'subtitle': 'support@suaxenhanh.com',
      'color': Colors.blue,
      'action': 'email',
    },
    {
      'icon': Icons.chat,
      'title': 'Chat trực tuyến',
      'subtitle': 'Hỗ trợ 24/7',
      'color': Colors.orange,
      'action': 'chat',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3), // Blue theme cho user
        title: const Text(
          'Trợ giúp',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 64,
                  color: Color(0xFF2196F3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chúng tôi sẵn sàng hỗ trợ bạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tìm câu trả lời cho các câu hỏi thường gặp hoặc liên hệ với chúng tôi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Liên hệ hỗ trợ
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Liên hệ hỗ trợ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._contactMethods.map((method) => _buildContactCard(method)),
              ],
            ),
          ),

          const Divider(height: 32),

          // Câu hỏi thường gặp
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Câu hỏi thường gặp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._faqs.asMap().entries.map((entry) {
                  return _buildFAQCard(entry.key, entry.value);
                }),
              ],
            ),
          ),

          // Hướng dẫn sử dụng
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hướng dẫn sử dụng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTutorialCard(
                  'Hướng dẫn đặt lịch sửa xe',
                  Icons.event_note,
                  'Xem video hướng dẫn chi tiết cách đặt lịch sửa xe nhanh chóng',
                ),
                const SizedBox(height: 8),
                _buildTutorialCard(
                  'Hướng dẫn thanh toán online',
                  Icons.payment,
                  'Tìm hiểu cách thanh toán qua chuyển khoản ngân hàng',
                ),
                const SizedBox(height: 8),
                _buildTutorialCard(
                  'Hướng dẫn theo dõi tiến độ',
                  Icons.track_changes,
                  'Cách theo dõi tình trạng sửa chữa xe của bạn',
                ),
                const SizedBox(height: 8),
                _buildTutorialCard(
                  'Hướng dẫn quản lý thông tin xe',
                  Icons.directions_car,
                  'Cập nhật và quản lý thông tin các xe của bạn',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: method['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(method['icon'], color: method['color']),
        ),
        title: Text(
          method['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(method['subtitle']),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _handleContactAction(method['action'], method['subtitle']);
        },
      ),
    );
  }

  Widget _buildFAQCard(int index, Map<String, dynamic> faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Color(0xFF2196F3),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          faq['question'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq['answer'],
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(String title, IconData icon, String description) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2196F3)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
        trailing: const Icon(
          Icons.play_circle_outline,
          color: Color(0xFF2196F3),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mở hướng dẫn: $title'),
              action: SnackBarAction(
                label: 'Đóng',
                onPressed: () {},
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleContactAction(String action, String value) {
    switch (action) {
      case 'call':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đang gọi $value...')),
        );
        break;
      case 'email':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mở ứng dụng email để gửi đến $value...')),
        );
        break;
      case 'chat':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Chat trực tuyến'),
            content: const Text(
              'Tính năng chat trực tuyến đang được phát triển. '
              'Vui lòng sử dụng Hotline hoặc Email để liên hệ.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
        break;
    }
  }
}