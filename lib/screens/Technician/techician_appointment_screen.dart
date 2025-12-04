// lib/screens/Technician/technician_appointments_screen.dart
// FIXED: 4 tabs đối xứng + Bottom Nav + Back button

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:suaxe_app/config/api_config.dart';
import 'package:suaxe_app/models/appointment_model.dart';
import 'package:intl/intl.dart';

class TechnicianAppointmentsScreen extends StatefulWidget {
  const TechnicianAppointmentsScreen({super.key});

  @override
  State<TechnicianAppointmentsScreen> createState() => _TechnicianAppointmentsScreenState();
}

class _TechnicianAppointmentsScreenState extends State<TechnicianAppointmentsScreen> 
    with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  late TabController _tabController;
  
  bool _isLoading = true;
  List<AppointmentModel> _allAppointments = [];
  
  List<AppointmentModel> _pendingAppointments = [];
  List<AppointmentModel> _confirmedAppointments = [];
  List<AppointmentModel> _completedAppointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load appointments từ API
  Future<void> _loadAppointments() async {
    try {
      setState(() => _isLoading = true);
      
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        _showError('Phiên đăng nhập đã hết hạn');
        return;
      }

      // Call API lấy appointments
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mechanics/appointments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📋 Appointments response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List appointments = data['appointments'];
          
          setState(() {
            _allAppointments = appointments
                .map((a) => AppointmentModel.fromJson(a))
                .toList();
            
            // Group by status
            _pendingAppointments = _allAppointments
                .where((a) => a.status == 'Pending')
                .toList();
            
            _confirmedAppointments = _allAppointments
                .where((a) => a.status == 'Confirmed')
                .toList();
            
            _completedAppointments = _allAppointments
                .where((a) => a.status == 'Completed')
                .toList();
          });
          
          print('✅ Loaded ${_allAppointments.length} appointments');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Error loading appointments: $e');
      _showError('Lỗi khi tải lịch hẹn: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Xác nhận lịch hẹn
  Future<void> _confirmAppointment(int appointmentId) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/mechanics/appointments/$appointmentId/confirm'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('✅ Confirm response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xác nhận lịch hẹn thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          
          // Reload data
          await _loadAppointments();
        } else {
          _showError(data['message'] ?? 'Lỗi khi xác nhận lịch hẹn');
        }
      } else {
        final data = json.decode(response.body);
        _showError(data['message'] ?? 'HTTP ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Error confirming appointment: $e');
      _showError('Lỗi khi xác nhận: $e');
    }
  }

  /// Hoàn thành công việc
  Future<void> _completeAppointment(int appointmentId) async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/mechanics/appointments/$appointmentId/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('✅ Complete response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã hoàn thành công việc!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          
          // Reload data
          await _loadAppointments();
        } else {
          _showError(data['message'] ?? 'Lỗi khi hoàn thành công việc');
        }
      } else {
        final data = json.decode(response.body);
        _showError(data['message'] ?? 'HTTP ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Error completing appointment: $e');
      _showError('Lỗi khi hoàn thành: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý Lịch hẹn',
          style: TextStyle(color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.redAccent,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              isScrollable: false, // False để 4 tabs fit đều
              labelPadding: EdgeInsets.zero, // Bỏ padding
              tabs: [
                _buildTab('Tất cả', _allAppointments.length, Icons.list_alt),
                _buildTab('Chờ xác nhận', _pendingAppointments.length, Icons.pending),
                _buildTab('Đã xác nhận', _confirmedAppointments.length, Icons.check_circle),
                _buildTab('Hoàn thành', _completedAppointments.length, Icons.done_all),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              color: Colors.redAccent, // Màu đỏ rõ ràng
              backgroundColor: Colors.white,
              strokeWidth: 3.0,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentsList(_allAppointments, 'All'),
                  _buildAppointmentsList(_pendingAppointments, 'Pending'),
                  _buildAppointmentsList(_confirmedAppointments, 'Confirmed'),
                  _buildAppointmentsList(_completedAppointments, 'Completed'),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTab(String text, int count, IconData icon) {
    return Tab(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(
            label: Text(
              count.toString(),
              style: const TextStyle(fontSize: 10),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 1, // Appointments tab
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            // Home - Pop back to home
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            // Appointments (current) - Do nothing
          } else if (index == 2) {
            // Profile - Pop to home first
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Công việc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch làm việc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<AppointmentModel> appointments, String status) {
    if (appointments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(), // Cho phép scroll khi empty
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status == 'All' 
                      ? 'Không có lịch hẹn nào'
                      : 'Không có lịch hẹn ${_getStatusText(status).toLowerCase()}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kéo xuống để làm mới',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(), // Luôn scroll được
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(appointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAppointmentDetail(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: appointment.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: appointment.statusColor),
                    ),
                    child: Text(
                      appointment.statusInVietnamese,
                      style: TextStyle(
                        color: appointment.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '#${appointment.appointmentId}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Customer info
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.customerName ?? 'Khách hàng',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Phone
              if (appointment.customerPhone != null)
                Row(
                  children: [
                    const Icon(Icons.phone, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      appointment.customerPhone!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              
              // Vehicle
              Row(
                children: [
                  const Icon(Icons.motorcycle, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.vehicleInfo,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Date/Time
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    appointment.formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Services
              if (appointment.services != null && appointment.services!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dịch vụ:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...appointment.services!.map((service) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '• ${service.serviceName}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              
              // Actions
              _buildActionButtons(appointment),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppointmentModel appointment) {
    if (appointment.status == 'Pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showConfirmDialog(appointment),
          icon: const Icon(Icons.check),
          label: const Text('Xác nhận lịch hẹn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    } else if (appointment.status == 'Confirmed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showCompleteDialog(appointment),
          icon: const Icon(Icons.done_all),
          label: const Text('Hoàn thành công việc'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  void _showConfirmDialog(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận lịch hẹn'),
        content: Text(
          'Xác nhận lịch hẹn cho khách hàng ${appointment.customerName}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmAppointment(appointment.appointmentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành công việc'),
        content: Text(
          'Đánh dấu công việc với khách hàng ${appointment.customerName} đã hoàn thành?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeAppointment(appointment.appointmentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetail(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AppointmentDetailScreen(appointment: appointment),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'All':
        return Icons.list_alt;
      case 'Pending':
        return Icons.pending;
      case 'Confirmed':
        return Icons.check_circle;
      case 'Completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'All':
        return 'Tất cả';
      case 'Pending':
        return 'Chờ xác nhận';
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'Completed':
        return 'Hoàn thành';
      default:
        return status;
    }
  }
}

// ============================================
// APPOINTMENT DETAIL SCREEN
// ============================================

class _AppointmentDetailScreen extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentDetailScreen({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chi tiết lịch hẹn #${appointment.appointmentId}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với status
            _buildHeader(),
            
            const SizedBox(height: 8),
            
            // Customer info card
            _buildInfoCard(
              title: 'Thông tin khách hàng',
              icon: Icons.person,
              color: Colors.blue,
              children: [
                _buildInfoRow(
                  Icons.person_outline,
                  'Khách hàng',
                  appointment.customerName ?? '-',
                ),
                if (appointment.customerPhone != null)
                  _buildInfoRow(
                    Icons.phone,
                    'Số điện thoại',
                    appointment.customerPhone!,
                  ),
                if (appointment.customerEmail != null)
                  _buildInfoRow(
                    Icons.email,
                    'Email',
                    appointment.customerEmail!,
                  ),
              ],
            ),
            
            // Vehicle info card
            _buildInfoCard(
              title: 'Thông tin xe',
              icon: Icons.motorcycle,
              color: Colors.orange,
              children: [
                _buildInfoRow(
                  Icons.confirmation_number,
                  'Biển số xe',
                  appointment.licensePlate ?? '-',
                ),
                if (appointment.brand != null || appointment.model != null)
                  _buildInfoRow(
                    Icons.directions_bike,
                    'Xe',
                    '${appointment.brand ?? ''} ${appointment.model ?? ''}'.trim(),
                  ),
                if (appointment.year != null)
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Năm',
                    appointment.year.toString(),
                  ),
              ],
            ),
            
            // Appointment info card
            _buildInfoCard(
              title: 'Thông tin lịch hẹn',
              icon: Icons.event_note,
              color: Colors.purple,
              children: [
                _buildInfoRow(
                  Icons.access_time,
                  'Thời gian',
                  appointment.formattedDate,
                ),
                if (appointment.estimatedEndTime != null)
                  _buildInfoRow(
                    Icons.schedule,
                    'Dự kiến kết thúc',
                    DateFormat('HH:mm', 'vi_VN').format(appointment.estimatedEndTime!),
                  ),
                if (appointment.serviceDuration != null)
                  _buildInfoRow(
                    Icons.timer,
                    'Thời gian dịch vụ',
                    '${appointment.serviceDuration} phút',
                  ),
              ],
            ),
            
            // Services card
            if (appointment.services != null && appointment.services!.isNotEmpty)
              _buildServicesCard(),
            
            // Notes card
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              _buildNotesCard(),
            
            // Payment info card
            if (appointment.totalAmount != null || appointment.paymentMethod != null)
              _buildPaymentCard(),
            
            const SizedBox(height: 80), // Padding bottom
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(),
                  color: appointment.statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  appointment.statusInVietnamese,
                  style: TextStyle(
                    color: appointment.statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (appointment.status) {
      case 'Pending':
        return Icons.pending;
      case 'Confirmed':
        return Icons.check_circle;
      case 'Completed':
        return Icons.done_all;
      case 'Canceled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.build, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Text(
                  'Dịch vụ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // Services list
          ...appointment.services!.asMap().entries.map((entry) {
            final index = entry.key;
            final service = entry.value;
            final isLast = index == appointment.services!.length - 1;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: !isLast
                    ? Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.serviceName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              service.formattedPrice,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              ' × ${service.quantity}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.note, color: Colors.amber, size: 24),
                SizedBox(width: 12),
                Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              appointment.notes!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.payment, color: Colors.teal, size: 24),
                SizedBox(width: 12),
                Text(
                  'Thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (appointment.totalAmount != null)
                  _buildInfoRow(
                    Icons.attach_money,
                    'Tổng tiền',
                    NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: 'đ',
                    ).format(appointment.totalAmount),
                  ),
                if (appointment.paymentMethod != null)
                  _buildInfoRow(
                    Icons.credit_card,
                    'Phương thức',
                    appointment.paymentMethod!,
                  ),
                if (appointment.paymentStatus != null)
                  _buildInfoRow(
                    Icons.receipt,
                    'Trạng thái TT',
                    appointment.paymentStatus!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}