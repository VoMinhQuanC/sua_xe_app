import 'package:flutter/material.dart';

class TechnicianTaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TechnicianTaskDetailScreen({super.key, required this.task});

  @override
  State<TechnicianTaskDetailScreen> createState() => _TechnicianTaskDetailScreenState();
}

class _TechnicianTaskDetailScreenState extends State<TechnicianTaskDetailScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task['status'];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đang chờ':
        return Colors.orange;
      case 'Đang làm':
        return Colors.blue;
      case 'Hoàn thành':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _updateStatus(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });
    
    // Có thể gọi API để cập nhật trạng thái
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật trạng thái: $newStatus'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Cập nhật lại widget.task để truyền về màn hình trước
    widget.task['status'] = newStatus;
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('Đang chờ', Colors.orange),
            _buildStatusOption('Đang làm', Colors.blue),
            _buildStatusOption('Hoàn thành', Colors.green),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String status, Color color) {
    final isSelected = _currentStatus == status;
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
      title: Text(status),
      onTap: () {
        _updateStatus(status);
        Navigator.pop(context);
      },
    );
  }

  void _callCustomer() {
    // Có thể sử dụng url_launcher để gọi điện
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang gọi ${widget.task['phone']}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openMap() {
    // Có thể sử dụng google_maps_flutter để mở bản đồ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang mở bản đồ...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text(
          'Chi tiết công việc',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với trạng thái
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(_currentStatus).withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: _getStatusColor(_currentStatus),
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _currentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(_currentStatus),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mã đơn: #${widget.task['id']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Thông tin khách hàng
            _buildSection(
              title: 'Thông tin khách hàng',
              icon: Icons.person,
              children: [
                _buildInfoRow('Tên khách hàng', widget.task['customerName']),
                _buildInfoRow(
                  'Số điện thoại',
                  widget.task['phone'],
                  trailing: IconButton(
                    icon: const Icon(Icons.phone, color: Colors.redAccent),
                    onPressed: _callCustomer,
                  ),
                ),
              ],
            ),

            // Thông tin dịch vụ
            _buildSection(
              title: 'Dịch vụ',
              icon: Icons.build,
              children: [
                _buildInfoRow('Loại dịch vụ', widget.task['service']),
                _buildInfoRow('Độ ưu tiên', widget.task['priority']),
                _buildInfoRow('Thời gian', widget.task['time']),
              ],
            ),

            // Thông tin xe
            _buildSection(
              title: 'Thông tin xe',
              icon: Icons.two_wheeler,
              children: [
                _buildInfoRow('Loại xe', widget.task['vehicle']),
                _buildInfoRow('Biển số', widget.task['licensePlate']),
              ],
            ),

            // Địa chỉ
            _buildSection(
              title: 'Địa chỉ',
              icon: Icons.location_on,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.task['address'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map, color: Colors.redAccent),
                        onPressed: _openMap,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Ghi chú
            if (widget.task['notes'].toString().isNotEmpty)
              _buildSection(
                title: 'Ghi chú',
                icon: Icons.note,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      widget.task['notes'],
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
            ),

            // Nút hành động
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showStatusDialog,
                      icon: const Icon(Icons.update, color: Colors.white),
                      label: const Text(
                        'Cập nhật trạng thái',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_currentStatus == 'Đang làm')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _updateStatus('Hoàn thành');
                        },
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        label: const Text(
                          'Hoàn thành công việc',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.redAccent, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
