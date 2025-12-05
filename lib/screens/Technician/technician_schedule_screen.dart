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

      floatingActionButtonLocation: const _CustomFabLocation(),

      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
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
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 80,
      ),
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
                  onPressed: ()  => _showEditOptionsDialog(schedule),
                ),
                // IconButton(
                //   icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                //   onPressed: () {
                //     // TODO: Delete schedule
                //   },
                // ),
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

  // /// Parse WorkDate từ ISO string
  // DateTime _parseWorkDate(String workDate) {
  //   try {
  //     if (workDate.contains('T')) {
  //       return DateTime.parse(workDate);
  //     }
  //     // Format: YYYY-MM-DD
  //     final parts = workDate.split('-');
  //     return DateTime(
  //       int.parse(parts[0]),
  //       int.parse(parts[1]),
  //       int.parse(parts[2]),
  //     );
  //   } catch (e) {
  //     print('Error parsing date: $e');
  //     return DateTime.now();
  //   }
  // }

  /// Format time (HH:MM:SS hoặc ISO) thành HH:MM
  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    
    try {
      if (time.contains('T')) {
        // ISO format
        final dateTime = DateTime.parse(time);
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        // HH:MM:SS format
        return time.substring(0, 5);
      }
    } catch (e) {
      return time.substring(0, 5);
    }
  }

  // ==========================================
  // DIALOG 1: THÊM LỊCH MỚI
  // ==========================================

  /// Dialog thêm lịch mới (KHÔNG CẦN DUYỆT)
  Future<void> _showAddScheduleDialog() async {
    final _formKey = GlobalKey<FormState>();
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Đăng ký lịch làm việc mới',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== CHỌN NGÀY =====
                      const Text(
                        'Ngày làm việc *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final tomorrow = DateTime.now().add(const Duration(days: 1));
                          final maxDate = DateTime.now().add(const Duration(days: 90));
                          
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tomorrow,
                            firstDate: tomorrow,
                            lastDate: maxDate,
                            locale: const Locale('vi', 'VN'),
                          );
                          
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.redAccent),
                              const SizedBox(width: 12),
                              Text(
                                selectedDate == null
                                    ? 'Chọn ngày'
                                    : DateFormat('dd/MM/yyyy', 'vi_VN').format(selectedDate!),
                                style: TextStyle(
                                  color: selectedDate == null ? Colors.grey : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '⚠️ Chỉ có thể đăng ký trước 24 giờ',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                      const SizedBox(height: 16),
                      
                      // ===== CHỌN GIỜ =====
                      Row(
                        children: [
                          // Giờ bắt đầu
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Giờ bắt đầu *',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: const TimeOfDay(hour: 8, minute: 0),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        startTime = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, color: Colors.redAccent, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          startTime == null
                                              ? 'Chọn'
                                              : startTime!.format(context),
                                          style: TextStyle(
                                            color: startTime == null ? Colors.grey : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Giờ kết thúc
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Giờ kết thúc *',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: const TimeOfDay(hour: 17, minute: 0),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        endTime = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, color: Colors.redAccent, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          endTime == null
                                              ? 'Chọn'
                                              : endTime!.format(context),
                                          style: TextStyle(
                                            color: endTime == null ? Colors.grey : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '⏱️ Thời gian làm việc tối thiểu 4 tiếng',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                      const SizedBox(height: 16),
                      
                      // ===== GHI CHÚ =====
                      const Text(
                        'Ghi chú',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'VD: Ca sáng, ca chiều...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ℹ️ Thông tin thêm về ca làm việc (không bắt buộc)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      
                      // ===== CHÚ THÍCH QUAN TRỌNG =====
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📋 Lưu ý:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• Lịch phải cách nhau tối thiểu 4 tiếng',
                              style: TextStyle(fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• Tối đa 6 kỹ thuật viên/ngày',
                              style: TextStyle(fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• Lịch sẽ hiển thị ngay sau khi lưu',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate
                    if (selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn ngày')),
                      );
                      return;
                    }
                    
                    if (startTime == null || endTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn giờ bắt đầu và kết thúc')),
                      );
                      return;
                    }
                    
                    // Validate 4 hours minimum
                    final startMinutes = startTime!.hour * 60 + startTime!.minute;
                    final endMinutes = endTime!.hour * 60 + endTime!.minute;
                    final diffHours = (endMinutes - startMinutes) / 60;
                    
                    if (diffHours < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thời gian làm việc tối thiểu phải 4 tiếng'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Call API
                    Navigator.pop(context);
                    await _addSchedule(
                      selectedDate!,
                      startTime!,
                      endTime!,
                      notesController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('Lưu lịch', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Call API thêm lịch
  Future<void> _addSchedule(
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
    String notes,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Format data
      final workDate = MechanicApiService.formatDate(date);
      final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      
      // Call API
      final response = await MechanicApiService.createSchedule(
        workDate: workDate,
        startTime: startTimeStr,
        endTime: endTimeStr,
        notes: notes.isNotEmpty ? notes : null,
        type: 'available',
        isAvailable: 1,
      );
      
      // Close loading
      if (mounted) Navigator.pop(context);
      
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký lịch làm việc thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Reload data
          await _loadSchedules();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Có lỗi xảy ra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      
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

  // ==========================================
  // DIALOG 2: CHỌN HÀNH ĐỘNG (XIN NGHỈ / XIN SỬA)
  // ==========================================

  /// Dialog chọn hành động khi click "Sửa"
  Future<void> _showEditOptionsDialog(MechanicScheduleModel schedule) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Chọn hành động',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thông tin lịch
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy', 'vi_VN').format(_parseWorkDate(schedule.workDate)),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Option 1: Xin nghỉ
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveRequestDialog(schedule);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200, width: 2),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.event_busy, color: Colors.orange, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏖️ Xin nghỉ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Có việc bận, không thể làm việc',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Option 2: Xin sửa lịch
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showEditRequestDialog(schedule);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_calendar, color: Colors.blue, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✏️ Xin sửa lịch',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Đổi sang ngày/giờ khác',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.blue),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // DIALOG 3: XIN NGHỈ
  // ==========================================

  /// Dialog xin nghỉ
  Future<void> _showLeaveRequestDialog(MechanicScheduleModel schedule) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_busy, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text(
                  'Đăng ký xin nghỉ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin lịch đang xin nghỉ
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ngày làm việc',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
                                    .format(_parseWorkDate(schedule.workDate)),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ca làm việc',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Alert thông báo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bạn đã đăng ký lịch này rồi.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Nếu có việc bận đột xuất, vui lòng điền lý do bên dưới để xin nghỉ.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Checkbox xác nhận (visual only)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.amber.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Đăng ký nghỉ (có việc bận, không thể làm việc)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '⚠️ Admin sẽ nhận được thông báo về đơn xin nghỉ của bạn',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Lý do xin nghỉ
                const Text(
                  'Lý do xin nghỉ *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'VD: Có việc gia đình, khám bệnh, bận đột xuất...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.orange.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.orange, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '❗ Vui lòng ghi rõ lý do để Admin dễ dàng xét duyệt',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
                const SizedBox(height: 16),
                
                // Trạng thái sau khi gửi
                const Text(
                  'Trạng thái sau khi gửi',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'CHỜ DUYỆT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập lý do xin nghỉ'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                await _submitLeaveRequest(schedule.scheduleId!, reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Gửi đơn xin nghỉ', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Submit leave request
  Future<void> _submitLeaveRequest(int scheduleId, String reason) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final response = await MechanicApiService.requestLeave(
        scheduleId: scheduleId,
        reason: reason,
      );
      
      // Close loading
      if (mounted) Navigator.pop(context);
      
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi đơn xin nghỉ! Chờ Admin duyệt.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Reload
          await _loadSchedules();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Có lỗi xảy ra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      
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

  // ==========================================
  // DIALOG 4: XIN SỬA LỊCH
  // ==========================================

  /// Dialog xin sửa lịch
  Future<void> _showEditRequestDialog(MechanicScheduleModel schedule) async {
    DateTime? newDate;
    TimeOfDay? newStartTime;
    TimeOfDay? newEndTime;
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_calendar, color: Colors.blue, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Xin sửa lịch làm việc',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // So sánh lịch cũ vs mới
                    Row(
                      children: [
                        // Lịch hiện tại
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lịch hiện tại',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('dd/MM/yyyy', 'vi_VN')
                                      .format(_parseWorkDate(schedule.workDate)),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Arrow
                        const Icon(Icons.arrow_forward, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        // Lịch mới
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lịch muốn đổi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _parseWorkDate(schedule.workDate),
                                      firstDate: DateTime.now().add(const Duration(days: 2)),
                                      lastDate: DateTime.now().add(const Duration(days: 90)),
                                      locale: const Locale('vi', 'VN'),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        newDate = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.blue.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Text(
                                          newDate == null
                                              ? 'Chọn ngày'
                                              : DateFormat('dd/MM/yy').format(newDate!),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(hour: 8, minute: 0),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              newStartTime = picked;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.blue.shade300),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            newStartTime?.format(context) ?? '08:00',
                                            style: const TextStyle(fontSize: 11),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('-', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(hour: 17, minute: 0),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              newEndTime = picked;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.blue.shade300),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            newEndTime?.format(context) ?? '17:00',
                                            style: const TextStyle(fontSize: 11),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Alert thông báo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bạn muốn thay đổi lịch làm việc?',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Vui lòng điền thông tin mới và lý do để Admin xét duyệt.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Lưu ý quan trọng
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Lưu ý:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('• Chỉ có thể xin sửa lịch trước 2 ngày', style: TextStyle(fontSize: 12)),
                          SizedBox(height: 4),
                          Text('• Lịch đã có khách đặt không thể sửa', style: TextStyle(fontSize: 12)),
                          SizedBox(height: 4),
                          Text('• Đơn xin sửa cần Admin duyệt', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Lý do xin sửa
                    const Text(
                      'Lý do xin sửa lịch *',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'VD: Đổi ca để đi học, có việc gia đình vào ngày cũ...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ℹ️ Ghi rõ lý do để Admin dễ dàng xét duyệt',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    
                    // Trạng thái sau khi gửi
                    const Text(
                      'Trạng thái sau khi gửi',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'CHỜ DUYỆT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (newDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn ngày mới')),
                      );
                      return;
                    }
                    
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập lý do')),
                      );
                      return;
                    }
                    
                    Navigator.pop(context);
                    await _submitEditRequest(
                      schedule.scheduleId!,
                      newDate!,
                      newStartTime ?? const TimeOfDay(hour: 8, minute: 0),
                      newEndTime ?? const TimeOfDay(hour: 17, minute: 0),
                      reasonController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Gửi đơn xin sửa', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Submit edit request
  Future<void> _submitEditRequest(
    int scheduleId,
    DateTime newDate,
    TimeOfDay newStartTime,
    TimeOfDay newEndTime,
    String reason,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final response = await MechanicApiService.requestEditSchedule(
        scheduleId: scheduleId,
        newWorkDate: DateFormat('yyyy-MM-dd').format(newDate),
        newStartTime: '${newStartTime.hour.toString().padLeft(2, '0')}:${newStartTime.minute.toString().padLeft(2, '0')}',
        newEndTime: '${newEndTime.hour.toString().padLeft(2, '0')}:${newEndTime.minute.toString().padLeft(2, '0')}',
        reason: reason,
      );
      
      if (mounted) Navigator.pop(context);
      
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi đơn xin sửa lịch! Chờ Admin duyệt.'),
              backgroundColor: Colors.green,
            ),
          );
          
          await _loadSchedules();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Có lỗi xảy ra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      
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
}
/// Custom FAB location - Di chuyển lên cao
class _CustomFabLocation extends FloatingActionButtonLocation {
  const _CustomFabLocation();
  
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = scaffoldGeometry.scaffoldSize.width - 72.0;
    final double fabY = scaffoldGeometry.scaffoldSize.height - 150.0;  // ← Điều chỉnh số này
    return Offset(fabX, fabY);
  }
}