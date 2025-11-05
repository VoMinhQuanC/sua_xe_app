import 'package:flutter/material.dart';

class TechnicianHelpScreen extends StatefulWidget {
  const TechnicianHelpScreen({super.key});

  @override
  State<TechnicianHelpScreen> createState() => _TechnicianHelpScreenState();
}

class _TechnicianHelpScreenState extends State<TechnicianHelpScreen> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'Làm thế nào để cập nhật trạng thái công việc?',
      'answer':
          'Bạn có thể cập nhật trạng thái công việc bằng cách:\n1. Mở danh sách công việc\n2. Chọn công việc cần cập nhật\n3. Nhấn nút "Cập nhật trạng thái"\n4. Chọn trạng thái mới và xác nhận',
    },
    {
      'question': 'Làm sao để xem lịch làm việc?',
      'answer':
          'Để xem lịch làm việc:\n1. Vào tab "Lịch làm việc" ở bottom navigation\n2. Chọn chế độ xem: Ngày, Tuần hoặc Tháng\n3. Sử dụng nút mũi tên để chuyển ngày/tuần/tháng\n4. Tap vào ngày trên lịch để xem công việc trong ngày đó',
    },
    {
      'question': 'Làm thế nào để liên hệ với khách hàng?',
      'answer':
          'Để liên hệ với khách hàng:\n1. Mở chi tiết công việc\n2. Nhấn nút "Gọi khách hàng" (icon điện thoại)\n3. Ứng dụng sẽ mở ứng dụng gọi điện với số điện thoại của khách hàng',
    },
    {
      'question': 'Làm sao để xem địa chỉ trên bản đồ?',
      'answer':
          'Để xem địa chỉ trên bản đồ:\n1. Mở chi tiết công việc\n2. Nhấn nút "Mở bản đồ" (icon vị trí)\n3. Ứng dụng sẽ mở ứng dụng bản đồ với địa chỉ của khách hàng',
    },
    {
      'question': 'Tôi quên mật khẩu, làm sao để đặt lại?',
      'answer':
          'Nếu bạn quên mật khẩu:\n1. Trên màn hình đăng nhập, nhấn "Quên mật khẩu?"\n2. Nhập email hoặc số điện thoại đã đăng ký\n3. Bạn sẽ nhận được mã OTP qua SMS/Email\n4. Nhập mã OTP và tạo mật khẩu mới',
    },
    {
      'question': 'Làm thế nào để xem lịch sử công việc?',
      'answer':
          'Để xem lịch sử công việc:\n1. Vào tab "Cá nhân"\n2. Chọn "Lịch sử công việc"\n3. Sử dụng bộ lọc để xem theo thời gian\n4. Tap vào công việc để xem chi tiết',
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
      'subtitle': 'support@sua_xe_app.com',
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
        backgroundColor: Colors.redAccent,
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
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.help_outline, size: 64, color: Colors.redAccent),
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
                  'Hướng dẫn cập nhật trạng thái công việc',
                  Icons.work_outline,
                  'Xem video hướng dẫn chi tiết cách cập nhật trạng thái công việc',
                ),
                const SizedBox(height: 8),
                _buildTutorialCard(
                  'Hướng dẫn sử dụng lịch làm việc',
                  Icons.calendar_today,
                  'Tìm hiểu cách sử dụng tính năng lịch làm việc hiệu quả',
                ),
                const SizedBox(height: 8),
                _buildTutorialCard(
                  'Hướng dẫn quản lý hồ sơ',
                  Icons.person_outline,
                  'Cập nhật thông tin cá nhân và xem thống kê công việc',
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
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.redAccent,
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
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.play_circle_outline, color: Colors.redAccent),
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
            content: const Text('Tính năng chat trực tuyến đang được phát triển. Vui lòng sử dụng Hotline hoặc Email để liên hệ.'),
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
