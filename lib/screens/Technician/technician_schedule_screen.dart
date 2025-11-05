import 'package:flutter/material.dart';
import 'technician_task_detail_screen.dart';

class TechnicianScheduleScreen extends StatefulWidget {
  const TechnicianScheduleScreen({super.key});

  @override
  State<TechnicianScheduleScreen> createState() => _TechnicianScheduleScreenState();
}

class _TechnicianScheduleScreenState extends State<TechnicianScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'Tháng'; // Ngày, Tuần, Tháng

  // Dữ liệu mẫu cho lịch làm việc
  final Map<String, List<Map<String, dynamic>>> _scheduleData = {
    // Hôm nay
    '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}': [
      {
        'id': '1',
        'customerName': 'Nguyễn Văn A',
        'phone': '0912345678',
        'service': 'Thay nhớt',
        'vehicle': 'Honda Wave RSX',
        'licensePlate': '30A-12345',
        'status': 'Đang chờ',
        'address': '123 Đường ABC, Quận 1, TP.HCM',
        'time': '14:00',
        'notes': 'Khách hàng yêu cầu nhớt Honda chính hãng',
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
        'time': '16:00',
        'notes': 'Rửa xe và vệ sinh nội thất',
        'priority': 'Thấp',
      },
    ],
    // Ngày mai
    '${DateTime.now().add(const Duration(days: 1)).year}-${DateTime.now().add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${DateTime.now().add(const Duration(days: 1)).day.toString().padLeft(2, '0')}': [
      {
        'id': '5',
        'customerName': 'Lê Văn E',
        'phone': '0956789012',
        'service': 'Bảo dưỡng tổng thể',
        'vehicle': 'Yamaha Exciter',
        'licensePlate': '29E-33333',
        'status': 'Đang chờ',
        'address': '555 Đường JKL, Quận 2, TP.HCM',
        'time': '09:00',
        'notes': 'Kiểm tra toàn bộ hệ thống',
        'priority': 'Cao',
      },
      {
        'id': '6',
        'customerName': 'Trần Thị F',
        'phone': '0967890123',
        'service': 'Sửa phanh',
        'vehicle': 'Honda SH',
        'licensePlate': '51F-44444',
        'status': 'Đang chờ',
        'address': '777 Đường MNO, Quận 10, TP.HCM',
        'time': '13:30',
        'notes': 'Phanh kêu và yếu',
        'priority': 'Trung bình',
      },
    ],
  };

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

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _getTasksForDate(DateTime date) {
    final dateKey = _formatDateKey(date);
    return _scheduleData[dateKey] ?? [];
  }

  int _getTaskCountForDate(DateTime date) {
    return _getTasksForDate(date).length;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSelectedDate(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text(
          'Lịch làm việc',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header với chế độ xem và ngày được chọn
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Chế độ xem (Ngày/Tuần/Tháng)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildViewModeChip('Ngày'),
                    const SizedBox(width: 8),
                    _buildViewModeChip('Tuần'),
                    const SizedBox(width: 8),
                    _buildViewModeChip('Tháng'),
                  ],
                ),
                const SizedBox(height: 16),
                // Hiển thị ngày được chọn và nút chọn ngày
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          if (_viewMode == 'Ngày') {
                            _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          } else if (_viewMode == 'Tuần') {
                            _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                          } else {
                            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
                          }
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text(
                              _viewMode == 'Ngày'
                                  ? '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'
                                  : _viewMode == 'Tuần'
                                      ? 'Tuần ${_getWeekNumber(_selectedDate)} - ${_selectedDate.year}'
                                      : 'Tháng ${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          if (_viewMode == 'Ngày') {
                            _selectedDate = _selectedDate.add(const Duration(days: 1));
                          } else if (_viewMode == 'Tuần') {
                            _selectedDate = _selectedDate.add(const Duration(days: 7));
                          } else {
                            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calendar view (chỉ hiển thị khi chế độ Tháng)
          if (_viewMode == 'Tháng') _buildMonthCalendar(),

          // Danh sách công việc
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeChip(String mode) {
    final isSelected = _viewMode == mode;
    return FilterChip(
      label: Text(mode),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _viewMode = mode);
      },
      selectedColor: Colors.redAccent.withOpacity(0.2),
      checkmarkColor: Colors.redAccent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.redAccent : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMonthCalendar() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Tên các ngày trong tuần
          Row(
            children: ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Lịch ngày
          ...List.generate(
            (firstDayOfWeek + daysInMonth + 6) ~/ 7,
            (weekIndex) {
              return Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - firstDayOfWeek + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox());
                  }
                  final dayDate = DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
                  final taskCount = _getTaskCountForDate(dayDate);
                  final isToday = _isToday(dayDate);
                  final isSelected = _isSelectedDate(dayDate);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = dayDate);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.redAccent
                              : isToday
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              dayNumber.toString(),
                              style: TextStyle(
                                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? Colors.blue
                                        : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            if (taskCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  taskCount.toString(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.redAccent : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    List<Map<String, dynamic>> tasks = [];

    if (_viewMode == 'Ngày') {
      tasks = _getTasksForDate(_selectedDate);
    } else if (_viewMode == 'Tuần') {
      final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
      for (int i = 0; i < 7; i++) {
        final dayDate = weekStart.add(Duration(days: i));
        tasks.addAll(_getTasksForDate(dayDate));
      }
      // Sắp xếp theo thời gian
      tasks.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));
    } else {
      // Tháng - hiển thị công việc của ngày được chọn
      tasks = _getTasksForDate(_selectedDate);
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có công việc nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _viewMode == 'Ngày'
                  ? 'Ngày ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'
                  : _viewMode == 'Tuần'
                      ? 'Trong tuần này'
                      : 'Tháng ${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task);
      },
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
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mốc thời gian
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task['time'] ?? '00:00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Thông tin công việc
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task['customerName'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(task['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(task['status']),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            task['status'] ?? '',
                            style: TextStyle(
                              color: _getStatusColor(task['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.build_circle_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task['service'] ?? '',
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(task['priority']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task['priority'] ?? '',
                            style: TextStyle(
                              color: _getPriorityColor(task['priority']),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.two_wheeler, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${task['vehicle'] ?? ''} - ${task['licensePlate'] ?? ''}',
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task['address'] ?? '',
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
  }
}
