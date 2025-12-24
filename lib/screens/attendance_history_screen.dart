import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../models/attendance_model.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  
  List<AttendanceModel> _attendanceList = [];
  bool _isLoading = true;
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final history = await _attendanceService.getHistory(
        month: _selectedMonth,
        year: _selectedYear,
      );
      
      setState(() {
        _attendanceList = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  Future<void> _showMonthPicker() async {
    final DateTime now = DateTime.now();
    int? selectedMonth = _selectedMonth;
    int? selectedYear = _selectedYear;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn tháng/năm'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (index) {
                    final month = index + 1;
                    return DropdownMenuItem(
                      value: month,
                      child: Text('Tháng $month'),
                    );
                  }),
                  onChanged: (value) {
                    setDialogState(() => selectedMonth = value);
                  },
                ),
                SizedBox(height: 16),
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(5, (index) {
                    final year = now.year - index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text('Năm $year'),
                    );
                  }),
                  onChanged: (value) {
                    setDialogState(() => selectedYear = value);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedMonth = selectedMonth!;
                _selectedYear = selectedYear!;
              });
              Navigator.pop(context);
              _loadHistory();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy (E)', 'vi_VN').format(date);
  }
  
  Map<String, dynamic> _calculateSummary() {
    int totalDays = _attendanceList.length;
    int lateDays = _attendanceList.where((a) => a.isLate).length;
    double totalHours = _attendanceList
        .where((a) => a.actualWorkHours != null)
        .fold(0.0, (sum, a) => sum + a.actualWorkHours!);
    double totalOvertime = _attendanceList
        .where((a) => a.overtimeHours != null)
        .fold(0.0, (sum, a) => sum + a.overtimeHours!);
    
    return {
      'totalDays': totalDays,
      'lateDays': lateDays,
      'totalHours': totalHours,
      'totalOvertime': totalOvertime,
    };
  }
  
  @override
  Widget build(BuildContext context) {
    final summary = _calculateSummary();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử chấm công'),
        backgroundColor: Color(0xFFE53935),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showMonthPicker,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Selected month/year
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      color: Color(0xFFE53935),
                      child: Text(
                        'Tháng $_selectedMonth/$_selectedYear',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    // Summary cards
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.calendar_month,
                              label: 'Tổng ngày',
                              value: '${summary['totalDays']}',
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.access_time,
                              label: 'Tổng giờ',
                              value: '${summary['totalHours'].toStringAsFixed(1)}h',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.trending_up,
                              label: 'Tăng ca',
                              value: '${summary['totalOvertime'].toStringAsFixed(1)}h',
                              color: Colors.purple,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.warning,
                              label: 'Đi muộn',
                              value: '${summary['lateDays']}',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Attendance list
                    _attendanceList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _attendanceList.length,
                            itemBuilder: (context, index) {
                              return _AttendanceRichCard(
                                attendance: _attendanceList[index],
                                formatDate: _formatDate,
                              );
                            },
                          ),
                    
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu chấm công',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Summary card widget
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ REDESIGNED: Rich information card
class _AttendanceRichCard extends StatelessWidget {
  final AttendanceModel attendance;
  final String Function(DateTime?) formatDate;
  
  const _AttendanceRichCard({
    required this.attendance,
    required this.formatDate,
  });
  
  @override
  Widget build(BuildContext context) {
    final hasSchedule = attendance.scheduledStartTime != null && attendance.scheduledEndTime != null;
    final hasActualHours = attendance.actualWorkHours != null;
    final hasOvertime = attendance.hasOvertime;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ HEADER: Date + Status
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: attendance.isLate ? Colors.orange[50] : Colors.green[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: attendance.isLate ? Colors.orange[700] : Colors.green[700],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formatDate(attendance.attendanceDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: attendance.isLate ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    attendance.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ BODY: Detailed info
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // ✅ Check-in/out times - LARGE & PROMINENT
                Row(
                  children: [
                    Expanded(
                      child: _TimeBlock(
                        icon: Icons.login,
                        iconColor: Colors.green,
                        label: 'Giờ vào',
                        time: attendance.checkInTime,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _TimeBlock(
                        icon: Icons.logout,
                        iconColor: Colors.red,
                        label: 'Giờ ra',
                        time: attendance.checkOutTime,
                      ),
                    ),
                  ],
                ),
                
                // ✅ Ca làm việc (if available)
                if (hasSchedule) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue[700], size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Ca làm việc: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${attendance.scheduledStartTime!.substring(0, 5)} - ${attendance.scheduledEndTime!.substring(0, 5)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        if (attendance.scheduledWorkHours != null) ...[
                          Text(' • ', style: TextStyle(color: Colors.grey)),
                          Text(
                            '${attendance.scheduledWorkHours}h',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                // ✅ Giờ thực tế + Tăng ca
                if (hasActualHours || hasOvertime) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      if (hasActualHours)
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.timelapse,
                            label: 'Làm thực tế',
                            value: '${attendance.actualWorkHours}h',
                            color: Colors.teal,
                          ),
                        ),
                      if (hasActualHours && hasOvertime) SizedBox(width: 12),
                      if (hasOvertime)
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.trending_up,
                            label: 'Tăng ca',
                            value: '+${attendance.overtimeHours}h',
                            color: Colors.purple,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Time block widget - Large & prominent
class _TimeBlock extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final DateTime? time;
  
  const _TimeBlock({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            time != null ? DateFormat('HH:mm').format(time!) : '--:--',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: time != null ? Colors.black87 : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Info chip widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
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