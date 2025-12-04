// lib/screens/Technician/technician_schedule_screen.dart
// Lịch làm việc với 2 tabs: Lịch cá nhân + Lịch nhóm
// SỬ DỤNG MechanicApiService

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:suaxe_app/models/mechanic_schedule_model.dart';
import 'package:suaxe_app/services/api/mechanic_api_service.dart';
import 'package:suaxe_app/config/api_config.dart';

class TechnicianScheduleScreen extends StatefulWidget {
  const TechnicianScheduleScreen({super.key});

  @override
  State<TechnicianScheduleScreen> createState() => _TechnicianScheduleScreenState();
}

class _TechnicianScheduleScreenState extends State<TechnicianScheduleScreen> with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  late TabController _tabController;
  
  DateTime _selectedDate = DateTime.now();
  bool _isCalendarView = true; // true = Calendar, false = List
  bool _isLoading = true;
  
  // Lịch cá nhân
  List<MechanicScheduleModel> _mySchedules = [];
  
  // Lịch nhóm
  List<MechanicScheduleModel> _teamSchedules = [];
  Map<String, List<MechanicScheduleModel>> _teamSchedulesByDate = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadSchedules();
      }
    });
    _loadSchedules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load lịch theo tab hiện tại
  Future<void> _loadSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (_tabController.index == 0) {
        // Tab "Lịch cá nhân" - Dùng MechanicApiService
        await _loadMySchedules();
      } else {
        // Tab "Lịch nhóm" - Call API mới
        await _loadTeamSchedules();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Load lịch cá nhân - Dùng MechanicApiService
  Future<void> _loadMySchedules() async {
    try {
      // Load lịch cả tháng
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
      
      final startDateStr = MechanicApiService.formatDate(startDate);
      final endDateStr = MechanicApiService.formatDate(endDate);
      
      print('📅 Loading personal schedules: $startDateStr → $endDateStr');
      
      final schedulesList = await MechanicApiService.getMySchedules(
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      if (mounted) {
        setState(() {
          _mySchedules = schedulesList
              .map((json) => MechanicScheduleModel.fromJson(json))
              .toList();
        });
      }
      
      print('✅ Loaded ${_mySchedules.length} personal schedules');
    } catch (e) {
      print('❌ Lỗi load lịch cá nhân: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải lịch cá nhân: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load lịch nhóm (tất cả mechanics) - API mới
  Future<void> _loadTeamSchedules() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Không tìm thấy token');
      }

      // Tính tuần hiện tại (T2 → CN)
      final weekStart = _getWeekStart(_selectedDate);
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      final startDateStr = MechanicApiService.formatDate(weekStart);
      final endDateStr = MechanicApiService.formatDate(weekEnd);
      
      print('📅 Loading team schedules: $startDateStr → $endDateStr');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mechanics/schedules/team/by-date-range/$startDateStr/$endDateStr'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final schedules = (data['schedules'] as List)
              .map((s) => MechanicScheduleModel.fromJson(s))
              .toList();

          // Group theo ngày
          final Map<String, List<MechanicScheduleModel>> groupedByDate = {};
          for (var schedule in schedules) {
            final dateKey = schedule.workDate; // Đã là String YYYY-MM-DD
            if (!groupedByDate.containsKey(dateKey)) {
              groupedByDate[dateKey] = [];
            }
            groupedByDate[dateKey]!.add(schedule);
          }

          if (mounted) {
            setState(() {
              _teamSchedules = schedules;
              _teamSchedulesByDate = groupedByDate;
            });
          }
          
          print('✅ Loaded ${_teamSchedules.length} team schedules');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi load lịch nhóm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải lịch nhóm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Lấy ngày đầu tuần (Thứ 2)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1)); // 1 = Monday
  }

  /// Parse workDate string thành DateTime
  DateTime _parseWorkDate(String workDate) {
    try {
      return DateTime.parse(workDate);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Kiểm tra có phải hôm nay không
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Kiểm tra ngày được chọn
  bool _isSelectedDate(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  /// Lấy số lượng lịch cho một ngày (lịch cá nhân)
  int _getScheduleCountForDate(DateTime date) {
    return _mySchedules.where((schedule) {
      final scheduleDate = _parseWorkDate(schedule.workDate);
      return scheduleDate.year == date.year &&
          scheduleDate.month == date.month &&
          scheduleDate.day == date.day;
    }).length;
  }

  /// Format notes để hiển thị đẹp hơn (parse JSON)
  String _formatScheduleNotes(MechanicScheduleModel schedule) {
    if (schedule.notes == null || schedule.notes!.isEmpty) {
      return '';
    }

    // ✅ Check if it starts with plain text markers
    if (schedule.notes!.startsWith('[XIN NGHỈ]') || 
        schedule.notes!.startsWith('[')) {
      // Plain text note, return as is
      return schedule.notes!;
    }

    try {
      // Thử parse JSON
      final notesData = json.decode(schedule.notes!);
      
      // ✅ Check editRequest trực tiếp (không cần check type)
      if (notesData['editRequest'] != null) {
        final edit = notesData['editRequest'];
        final newDate = edit['newWorkDate'] ?? '';
        final newStart = (edit['newStartTime'] ?? '').toString();
        final newEnd = (edit['newEndTime'] ?? '').toString();
        final reason = edit['reason'] ?? '';
        
        String result = '📝 Đơn xin sửa lịch';
        
        if (newDate.isNotEmpty) {
          try {
            final date = DateTime.parse(newDate);
            result += '\n→ Ngày mới: ${DateFormat('dd/MM/yyyy', 'vi_VN').format(date)}';
          } catch (e) {
            result += '\n→ Ngày mới: $newDate';
          }
        }
        
        if (newStart.isNotEmpty && newEnd.isNotEmpty) {
          // Extract HH:mm from time string
          final startTime = newStart.length >= 5 ? newStart.substring(0, 5) : newStart;
          final endTime = newEnd.length >= 5 ? newEnd.substring(0, 5) : newEnd;
          result += '\n→ Giờ mới: $startTime - $endTime';
        }
        
        if (reason.isNotEmpty) {
          result += '\n→ Lý do: $reason';
        }
        
        // ✅ Thêm trạng thái duyệt
        if (notesData['approved'] == true) {
          result += '\n✅ Đã được duyệt';
        } else if (notesData['approved'] == false) {
          result += '\n❌ Đã bị từ chối';
        }
        
        return result;
      }
      
      // Nếu là đơn xin nghỉ (có reason nhưng không có editRequest)
      if (notesData['reason'] != null && notesData['editRequest'] == null) {
        final reason = notesData['reason'] ?? 'Xin nghỉ';
        return '🏖️ Lý do nghỉ: $reason';
      }
      
      // JSON khác thì trả về notes gốc
      return schedule.notes!;
    } catch (e) {
      // ✅ Không phải JSON, trả về text gốc (không log error nữa)
      return schedule.notes!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch làm việc',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Toggle Calendar/List view (chỉ hiện ở tab Lịch cá nhân)
          if (_tabController.index == 0)
            IconButton(
              icon: Icon(
                _isCalendarView ? Icons.view_list : Icons.calendar_month,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isCalendarView = !_isCalendarView;
                });
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Lịch cá nhân'),
            Tab(text: 'Lịch nhóm'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchedules,
        color: Colors.redAccent,
        backgroundColor: Colors.white,
        strokeWidth: 3.0,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPersonalScheduleTab(),
            _buildTeamScheduleTab(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to add schedule screen
                _showAddScheduleDialog();
              },
              backgroundColor: const Color(0xFFE53935),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  /// Tab 1: Lịch cá nhân
  Widget _buildPersonalScheduleTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Calendar view (có thể toggle)
        if (_isCalendarView) _buildMonthCalendar(),
        
        // Danh sách lịch
        Expanded(
          child: _buildPersonalScheduleList(),
        ),
      ],
    );
  }

  /// Tab 2: Lịch nhóm
  Widget _buildTeamScheduleTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header tuần
        _buildWeekHeader(),
        
        // Weekly timeline list
        Expanded(
          child: _buildWeeklyTimelineList(),
        ),
      ],
    );
  }

  /// Calendar tháng
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
          // Header tháng/năm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                      1,
                    );
                  });
                  _loadSchedules();
                },
              ),
              Text(
                'Tháng ${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                      1,
                    );
                  });
                  _loadSchedules();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  final scheduleCount = _getScheduleCountForDate(dayDate);
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
                              ? const Color(0xFFE53935)
                              : isToday
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(color: Colors.blue, width: 1)
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayNumber.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? Colors.blue
                                        : Colors.black87,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (scheduleCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  scheduleCount.toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFFE53935)
                                        : Colors.white,
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

  /// Danh sách lịch cá nhân
  Widget _buildPersonalScheduleList() {
    final schedules = _mySchedules.where((schedule) {
      final scheduleDate = _parseWorkDate(schedule.workDate);
      return scheduleDate.year == _selectedDate.year &&
          scheduleDate.month == _selectedDate.month &&
          scheduleDate.day == _selectedDate.day;
    }).toList();

    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có lịch làm việc',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(_selectedDate),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        return _buildScheduleCard(schedules[index]);
      },
    );
  }

  /// Card lịch cá nhân
  Widget _buildScheduleCard(MechanicScheduleModel schedule) {
    final statusColor = Color(int.parse(schedule.statusColor.replaceFirst('#', '0xFF')));
    final isLeaveRequest = schedule.isLeaveRequest;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ngày + Type
            Row(
              children: [
                Expanded(
                  child: Text(
                    schedule.displayDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLeaveRequest
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLeaveRequest ? Colors.orange : Colors.green,
                    ),
                  ),
                  child: Text(
                    schedule.typeInVietnamese,
                    style: TextStyle(
                      color: isLeaveRequest ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Thời gian
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  schedule.displayTime,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatScheduleNotes(schedule),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Status badge
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                schedule.statusInVietnamese,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    // TODO: Edit schedule
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () {
                    // TODO: Delete schedule
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Header tuần (lịch nhóm)
  Widget _buildWeekHeader() {
    final weekStart = _getWeekStart(_selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
              });
              _loadSchedules();
            },
          ),
          Text(
            '${DateFormat('dd/MM', 'vi_VN').format(weekStart)} - ${DateFormat('dd/MM/yyyy', 'vi_VN').format(weekEnd)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 7));
              });
              _loadSchedules();
            },
          ),
        ],
      ),
    );
  }

  /// Weekly timeline list (lịch nhóm)
  Widget _buildWeeklyTimelineList() {
    if (_teamSchedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có lịch nhóm trong tuần này',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final weekStart = _getWeekStart(_selectedDate);
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: weekDays.length,
      itemBuilder: (context, index) {
        final date = weekDays[index];
        final dateKey = MechanicApiService.formatDate(date);
        final schedulesForDay = _teamSchedulesByDate[dateKey] ?? [];

        return _buildDayTimelineSection(date, schedulesForDay);
      },
    );
  }

  /// Section cho mỗi ngày trong tuần
  Widget _buildDayTimelineSection(DateTime date, List<MechanicScheduleModel> schedules) {
    final isToday = _isToday(date);
    final dayName = DateFormat('EEEE', 'vi_VN').format(date);
    final dayDate = DateFormat('dd/MM', 'vi_VN').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFE53935) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dayDate,
                style: TextStyle(
                  fontSize: 14,
                  color: isToday ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${schedules.length} người',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isToday ? const Color(0xFFE53935) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Schedules
        if (schedules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Không có lịch',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
          )
        else
          ...schedules.map((schedule) => _buildTeamScheduleCard(schedule)),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Card lịch nhóm
  Widget _buildTeamScheduleCard(MechanicScheduleModel schedule) {
    final isLeaveRequest = schedule.isLeaveRequest;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE53935),
              child: Text(
                schedule.mechanicName?.substring(0, 1).toUpperCase() ?? 'M',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.mechanicName ?? 'Kỹ thuật viên',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isLeaveRequest ? Icons.event_busy : Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule.displayTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLeaveRequest
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLeaveRequest ? Colors.orange : Colors.green,
                ),
              ),
              child: Text(
                isLeaveRequest ? 'Nghỉ' : 'Làm việc',
                style: TextStyle(
                  color: isLeaveRequest ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog thêm lịch
  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm lịch làm việc'),
        content: const Text('Chức năng đang phát triển...'),
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