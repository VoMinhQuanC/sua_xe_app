import 'package:flutter/material.dart';
import 'technician_task_detail_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  String _selectedFilter = 'Tất cả'; // Tất cả, Đang chờ, Đang làm, Hoàn thành

  // Dữ liệu mẫu cho danh sách công việc
  final List<Map<String, dynamic>> _tasks = [
    {
      'id': '1',
      'customerName': 'Nguyễn Văn A',
      'phone': '0912345678',
      'service': 'Thay nhớt',
      'vehicle': 'Honda Wave RSX',
      'licensePlate': '30A-12345',
      'status': 'Đang chờ',
      'address': '123 Đường ABC, Quận 1, TP.HCM',
      'time': '14:00 - Hôm nay',
      'notes': 'Khách hàng yêu cầu nhớt Honda chính hãng',
      'priority': 'Cao',
    },
    {
      'id': '2',
      'customerName': 'Trần Thị B',
      'phone': '0923456789',
      'service': 'Bảo dưỡng tổng thể',
      'vehicle': 'Yamaha Sirius',
      'licensePlate': '51B-67890',
      'status': 'Đang làm',
      'address': '456 Đường XYZ, Quận 3, TP.HCM',
      'time': '10:00 - Hôm nay',
      'notes': 'Kiểm tra phanh và lốp xe',
      'priority': 'Trung bình',
    },
    {
      'id': '3',
      'customerName': 'Lê Văn C',
      'phone': '0934567890',
      'service': 'Sửa phanh',
      'vehicle': 'Honda Vision',
      'licensePlate': '29C-11111',
      'status': 'Hoàn thành',
      'address': '789 Đường DEF, Quận 5, TP.HCM',
      'time': '08:00 - Hôm nay',
      'notes': 'Đã hoàn thành, khách hàng đã thanh toán',
      'priority': 'Cao',
    },
    {
      'id': '4',
      'customerName': 'Phạm Thị D',
      'phone': '0945678901',
      'service': 'Rửa xe',
      'vehicle': 'Honda Air Blade',
      'licensePlate': '43D-22222',
      'status': 'Đang chờ',
      'address': '321 Đường GHI, Quận 7, TP.HCM',
      'time': '16:00 - Hôm nay',
      'notes': 'Rửa xe và vệ sinh nội thất',
      'priority': 'Thấp',
    },
  ];

  int get _pendingCount => _tasks.where((t) => t['status'] == 'Đang chờ').length;
  int get _inProgressCount => _tasks.where((t) => t['status'] == 'Đang làm').length;
  int get _completedCount => _tasks.where((t) => t['status'] == 'Hoàn thành').length;

  List<Map<String, dynamic>> get _filteredTasks {
    if (_selectedFilter == 'Tất cả') return _tasks;
    if (_selectedFilter == 'Đang chờ') {
      return _tasks.where((t) => t['status'] == 'Đang chờ').toList();
    }
    if (_selectedFilter == 'Đang làm') {
      return _tasks.where((t) => t['status'] == 'Đang làm').toList();
    }
    if (_selectedFilter == 'Hoàn thành') {
      return _tasks.where((t) => t['status'] == 'Hoàn thành').toList();
    }
    return _tasks;
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Cao':
        return Colors.red;
      case 'Trung bình':
        return Colors.orange;
      case 'Thấp':
        return Colors.green;
      default:
        return Colors.grey;
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
            Image.asset(
              'assets/images/logo1.png',
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              "Kỹ Thuật Viên",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Thống kê nhanh
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Đang chờ', _pendingCount, Colors.orange, Icons.pending),
                _buildStatCard('Đang làm', _inProgressCount, Colors.blue, Icons.build),
                _buildStatCard('Hoàn thành', _completedCount, Colors.green, Icons.check_circle),
              ],
            ),
          ),

          // Bộ lọc
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Tất cả', 'Đang chờ', 'Đang làm', 'Hoàn thành'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      selectedColor: Colors.redAccent.withOpacity(0.2),
                      checkmarkColor: Colors.redAccent,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.redAccent : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Danh sách công việc
          Expanded(
            child: _filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Không có công việc nào',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      // Có thể gọi API để làm mới dữ liệu
                      await Future.delayed(const Duration(seconds: 1));
                      setState(() {});
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return _buildTaskCard(task);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Có thể mở màn hình tìm kiếm hoặc lọc nâng cao
        },
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
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

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TechnicianTaskDetailScreen(task: task),
            ),
          ).then((_) => setState(() {})); // Refresh sau khi quay lại
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['customerName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              task['phone'],
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(task['status']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      task['status'],
                      style: TextStyle(
                        color: _getStatusColor(task['status']),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.build_circle_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task['service'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task['priority']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task['priority'],
                      style: TextStyle(
                        color: _getPriorityColor(task['priority']),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.two_wheeler, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${task['vehicle']} - ${task['licensePlate']}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    task['time'],
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task['address'],
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (task['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task['notes'],
                          style: TextStyle(color: Colors.blue[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
