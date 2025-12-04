// lib/screens/Technician/technician_task_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:suaxe_app/models/booking_model.dart';
import 'package:suaxe_app/services/api/mechanic_api_service.dart';

class TechnicianTaskDetailScreen extends StatefulWidget {
  final int appointmentId;

  const TechnicianTaskDetailScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<TechnicianTaskDetailScreen> createState() => _TechnicianTaskDetailScreenState();
}

class _TechnicianTaskDetailScreenState extends State<TechnicianTaskDetailScreen> {
  bool _isLoading = false;
  BookingModel? _appointment;

  @override
  void initState() {
    super.initState();
    _loadAppointmentDetail();
  }

  /// Tải chi tiết lịch hẹn
  Future<void> _loadAppointmentDetail() async {
    setState(() => _isLoading = true);
    
    try {
      // Lấy tất cả appointments và tìm theo ID
      final appointments = await MechanicApiService.getMyAppointments();
      final appointment = appointments.firstWhere(
        (a) => a.appointmentId == widget.appointmentId,
        orElse: () => throw Exception('Không tìm thấy lịch hẹn'),
      );
      
      setState(() {
        _appointment = appointment;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải chi tiết: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Cập nhật trạng thái công việc
  Future<void> _updateStatus(String newStatus) async {
    // Xác nhận trước khi cập nhật
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn cập nhật trạng thái thành "${_getStatusLabel(newStatus)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    try {
      await MechanicApiService.updateAppointmentStatus(
        appointmentId: widget.appointmentId,
        status: newStatus,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật trạng thái thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Reload
      await _loadAppointmentDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Mở dialog chọn trạng thái mới
  Future<void> _showUpdateStatusDialog() async {
    if (_appointment == null) return;

    final currentStatus = _appointment!.status;
    String? selectedStatus;

    // Xác định các trạng thái có thể chuyển đổi
    List<String> availableStatuses = [];
    if (currentStatus == 'Pending') {
      availableStatuses = ['Confirmed', 'Canceled'];
    } else if (currentStatus == 'Confirmed') {
      availableStatuses = ['Completed', 'Canceled'];
    }

    if (availableStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể thay đổi trạng thái của công việc này'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableStatuses.map((status) {
            return RadioListTile<String>(
              title: Text(_getStatusLabel(status)),
              value: status,
              groupValue: selectedStatus,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  _updateStatus(value);
                }
              },
            );
          }).toList(),
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ xác nhận';
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'Completed':
        return 'Hoàn thành';
      case 'Canceled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  /// Gọi điện cho khách hàng
  Future<void> _callCustomer() async {
    if (_appointment?.phoneNumber == null) return;
    
    final phoneNumber = _appointment!.phoneNumber!;
    final uri = Uri.parse('tel:$phoneNumber');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể thực hiện cuộc gọi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mở bản đồ
  Future<void> _openMap() async {
    // Giả định có địa chỉ trong notes hoặc thông tin khách hàng
    final address = _appointment?.notes ?? 'Địa chỉ khách hàng';
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở bản đồ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAppointmentDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointment == null
              ? const Center(child: Text('Không tìm thấy thông tin'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header với status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor(_appointment!.status),
                              _getStatusColor(_appointment!.status).withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getStatusIcon(_appointment!.status),
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _appointment!.statusInVietnamese,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(_appointment!.appointmentDate),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Thông tin khách hàng
                      _buildSection(
                        icon: Icons.person,
                        title: 'Thông tin khách hàng',
                        children: [
                          _buildInfoRow('Họ tên', _appointment!.fullName ?? 'N/A'),
                          _buildInfoRow('Số điện thoại', _appointment!.phoneNumber ?? 'N/A'),
                          _buildInfoRow('Email', _appointment!.email ?? 'N/A'),
                        ],
                      ),

                      // Thông tin xe
                      _buildSection(
                        icon: Icons.two_wheeler,
                        title: 'Thông tin xe',
                        children: [
                          _buildInfoRow('Biển số', _appointment!.licensePlate ?? 'N/A'),
                          _buildInfoRow('Hãng xe', _appointment!.brand ?? 'N/A'),
                          _buildInfoRow('Model', _appointment!.model ?? 'N/A'),
                          if (_appointment!.year != null)
                            _buildInfoRow('Năm sản xuất', _appointment!.year.toString()),
                        ],
                      ),

                      // Dịch vụ
                      _buildSection(
                        icon: Icons.build_circle,
                        title: 'Dịch vụ yêu cầu',
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _appointment!.services ?? 'Không có dịch vụ',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                      // Ghi chú
                      if (_appointment!.notes != null && _appointment!.notes!.isNotEmpty)
                        _buildSection(
                          icon: Icons.note,
                          title: 'Ghi chú',
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _appointment!.notes!,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
      bottomNavigationBar: _appointment != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Gọi điện
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _callCustomer,
                      icon: const Icon(Icons.phone),
                      label: const Text('Gọi'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mở bản đồ
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openMap,
                      icon: const Icon(Icons.map),
                      label: const Text('Bản đồ'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Cập nhật trạng thái
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showUpdateStatusDialog,
                      icon: const Icon(Icons.update),
                      label: const Text('Cập nhật'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.redAccent),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.access_time;
      case 'Confirmed':
        return Icons.check_circle_outline;
      case 'Completed':
        return Icons.task_alt;
      case 'Canceled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    return '${timeFormat.format(dateTime)} - ${dateFormat.format(dateTime)}';
  }
}