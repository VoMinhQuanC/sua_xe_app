import 'package:flutter/material.dart';
import 'technician_task_detail_screen.dart';

class TechnicianWorkHistoryScreen extends StatefulWidget {
  const TechnicianWorkHistoryScreen({super.key});

  @override
  State<TechnicianWorkHistoryScreen> createState() => _TechnicianWorkHistoryScreenState();
}

class _TechnicianWorkHistoryScreenState extends State<TechnicianWorkHistoryScreen> {
  String _selectedFilter = 'Tất cả'; // Tất cả, Tháng này, Tháng trước, 3 tháng

  // Dữ liệu mẫu lịch sử công việc
  final List<Map<String, dynamic>> _workHistory = [
    {
      'id': '1',
      'customerName': 'Nguyễn Văn A',
      'phone': '0912345678',
      'service': 'Thay nhớt',
      'vehicle': 'Honda Wave RSX',
      'licensePlate': '30A-12345',
      'status': 'Hoàn thành',
      'address': '123 Đường ABC, Quận 1, TP.HCM',
      'date': '2024-12-15',
      'time': '14:00',
      'completedDate': '2024-12-15',
      'completedTime': '15:30',
      'rating': 5,
      'notes': 'Khách hàng hài lòng với dịch vụ',
    },
    {
      'id': '2',
      'customerName': 'Trần Thị B',
      'phone': '0923456789',
      'service': 'Bảo dưỡng tổng thể',
      'vehicle': 'Yamaha Sirius',
      'licensePlate': '51B-67890',
      'status': 'Hoàn thành',
      'address': '456 Đường XYZ, Quận 3, TP.HCM',
      'date': '2024-12-14',
      'time': '10:00',
      'completedDate': '2024-12-14',
      'completedTime': '11:30',
      'rating': 4,
      'notes': 'Đã kiểm tra và bảo dưỡng đầy đủ',
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
      'date': '2024-12-13',
      'time': '08:00',
      'completedDate': '2024-12-13',
      'completedTime': '09:15',
      'rating': 5,
      'notes': 'Phanh hoạt động tốt sau khi sửa',
    },
    {
      'id': '4',
      'customerName': 'Phạm Thị D',
      'phone': '0945678901',
      'service': 'Rửa xe',
      'vehicle': 'Honda Air Blade',
      'licensePlate': '43D-22222',
      'status': 'Hoàn thành',
      'address': '321 Đường GHI, Quận 7, TP.HCM',
      'date': '2024-12-12',
      'time': '16:00',
      'completedDate': '2024-12-12',
      'completedTime': '17:00',
      'rating': 4,
      'notes': 'Xe sạch đẹp như mới',
    },
    {
      'id': '5',
      'customerName': 'Hoàng Văn E',
      'phone': '0956789012',
      'service': 'Thay lốp',
      'vehicle': 'Yamaha Exciter',
      'licensePlate': '29E-33333',
      'status': 'Hoàn thành',
      'address': '555 Đường JKL, Quận 2, TP.HCM',
      'date': '2024-12-10',
      'time': '09:00',
      'completedDate': '2024-12-10',
      'completedTime': '10:30',
      'rating': 5,
      'notes': 'Lốp mới chất lượng tốt',
    },
  ];

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedFilter == 'Tất cả') return _workHistory;
    
    final now = DateTime.now();
    DateTime startDate;
    
    if (_selectedFilter == 'Tháng này') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (_selectedFilter == 'Tháng trước') {
      startDate = DateTime(now.year, now.month - 1, 1);
    } else if (_selectedFilter == '3 tháng') {
      startDate = DateTime(now.year, now.month - 3, 1);
    } else {
      return _workHistory;
    }
    
    return _workHistory.where((work) {
      final workDate = DateTime.parse(work['completedDate']);
      return workDate.isAfter(startDate.subtract(const Duration(days: 1)));
    }).toList();
  }

  double get _averageRating {
    if (_filteredHistory.isEmpty) return 0;
    final total = _filteredHistory.fold<double>(0, (sum, work) => sum + (work['rating'] as int).toDouble());
    return total / _filteredHistory.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text(
          'Lịch sử công việc',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Thống kê
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Tổng công việc', _filteredHistory.length.toString(), Icons.work, Colors.blue),
                _buildStatCard('Đánh giá TB', _averageRating.toStringAsFixed(1), Icons.star, Colors.orange),
              ],
            ),
          ),

          // Bộ lọc
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Tất cả', 'Tháng này', 'Tháng trước', '3 tháng'].map((filter) {
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

          // Danh sách lịch sử
          Expanded(
            child: _filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có lịch sử công việc',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final work = _filteredHistory[index];
                      return _buildHistoryCard(work);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
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
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> work) {
    final completedDate = DateTime.parse(work['completedDate']);
    final rating = work['rating'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TechnicianTaskDetailScreen(task: work),
            ),
          );
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
                          work['customerName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${completedDate.day}/${completedDate.month}/${completedDate.year} - ${work['completedTime']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: const Text(
                      'Hoàn thành',
                      style: TextStyle(
                        color: Colors.green,
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
                      work['service'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
                      '${work['vehicle']} - ${work['licensePlate']}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Đánh giá: ',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  ...List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.orange,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '$rating/5',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (work['notes'] != null && work['notes'].toString().isNotEmpty) ...[
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
                          work['notes'],
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
