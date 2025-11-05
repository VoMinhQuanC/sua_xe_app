import 'package:flutter/material.dart';

class TechnicianSettingsScreen extends StatefulWidget {
  const TechnicianSettingsScreen({super.key});

  @override
  State<TechnicianSettingsScreen> createState() => _TechnicianSettingsScreenState();
}

class _TechnicianSettingsScreenState extends State<TechnicianSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _locationTrackingEnabled = true;
  String _language = 'Tiếng Việt';
  String _theme = 'Sáng';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text(
          'Cài đặt',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // Thông báo
          _buildSectionTitle('Thông báo'),
          SwitchListTile(
            title: const Text('Bật thông báo'),
            subtitle: const Text('Nhận thông báo về công việc mới'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
            activeColor: Colors.redAccent,
          ),
          SwitchListTile(
            title: const Text('Âm thanh'),
            subtitle: const Text('Phát âm thanh khi có thông báo'),
            value: _soundEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() => _soundEnabled = value);
                  }
                : null,
            activeColor: Colors.redAccent,
          ),
          SwitchListTile(
            title: const Text('Rung'),
            subtitle: const Text('Rung khi có thông báo'),
            value: _vibrationEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() => _vibrationEnabled = value);
                  }
                : null,
            activeColor: Colors.redAccent,
          ),

          const Divider(height: 32),

          // Ứng dụng
          _buildSectionTitle('Ứng dụng'),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.redAccent),
            title: const Text('Ngôn ngữ'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showLanguageDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette, color: Colors.redAccent),
            title: const Text('Giao diện'),
            subtitle: Text(_theme),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThemeDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.redAccent),
            title: const Text('Theo dõi vị trí'),
            subtitle: const Text('Cho phép ứng dụng theo dõi vị trí của bạn'),
            trailing: Switch(
              value: _locationTrackingEnabled,
              onChanged: (value) {
                setState(() => _locationTrackingEnabled = value);
              },
              activeColor: Colors.redAccent,
            ),
          ),

          const Divider(height: 32),

          // Bộ nhớ & Dữ liệu
          _buildSectionTitle('Bộ nhớ & Dữ liệu'),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.redAccent),
            title: const Text('Xóa bộ nhớ đệm'),
            subtitle: const Text('Xóa dữ liệu tạm thời để giải phóng dung lượng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearCacheDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.redAccent),
            title: const Text('Tải dữ liệu ngoại tuyến'),
            subtitle: const Text('Tải dữ liệu để sử dụng khi không có internet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),

          const Divider(height: 32),

          // Thông tin
          _buildSectionTitle('Thông tin'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.redAccent),
            title: const Text('Phiên bản ứng dụng'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.policy, color: Colors.redAccent),
            title: const Text('Chính sách bảo mật'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showPrivacyPolicy();
            },
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.redAccent),
            title: const Text('Điều khoản sử dụng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showTermsOfService();
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'Tiếng Việt',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn giao diện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Sáng'),
              value: 'Sáng',
              groupValue: _theme,
              onChanged: (value) {
                setState(() => _theme = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Tối'),
              value: 'Tối',
              groupValue: _theme,
              onChanged: (value) {
                setState(() => _theme = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Tự động'),
              value: 'Tự động',
              groupValue: _theme,
              onChanged: (value) {
                setState(() => _theme = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bộ nhớ đệm'),
        content: const Text('Bạn có chắc chắn muốn xóa bộ nhớ đệm? Hành động này sẽ giải phóng dung lượng lưu trữ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa bộ nhớ đệm thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chính sách bảo mật'),
        content: SingleChildScrollView(
          child: Text(
            '''Chính sách bảo mật của chúng tôi:

1. Thu thập thông tin:
- Thông tin cá nhân của bạn được bảo mật tuyệt đối
- Chúng tôi chỉ thu thập thông tin cần thiết để cung cấp dịch vụ

2. Sử dụng thông tin:
- Thông tin được sử dụng để quản lý và cải thiện dịch vụ
- Chúng tôi không chia sẻ thông tin với bên thứ ba

3. Bảo mật:
- Dữ liệu được mã hóa và bảo vệ an toàn
- Chúng tôi tuân thủ các tiêu chuẩn bảo mật quốc tế''',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điều khoản sử dụng'),
        content: SingleChildScrollView(
          child: Text(
            '''Điều khoản sử dụng ứng dụng:

1. Quyền và trách nhiệm:
- Bạn có trách nhiệm bảo mật tài khoản của mình
- Sử dụng ứng dụng đúng mục đích và tuân thủ pháp luật

2. Dịch vụ:
- Ứng dụng cung cấp dịch vụ sửa chữa xe máy
- Chúng tôi có quyền thay đổi hoặc ngừng dịch vụ khi cần thiết

3. Giới hạn trách nhiệm:
- Ứng dụng chỉ là công cụ kết nối
- Chúng tôi không chịu trách nhiệm về chất lượng dịch vụ của bên thứ ba''',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
