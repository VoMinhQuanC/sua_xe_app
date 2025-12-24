// lib/screens/Technician/technician_task_detail_screen.dart
// ✅ WORKAROUND: Dùng getMyAppointments() để tránh 403

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
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

  /// ✅ WORKAROUND: Tải chi tiết từ list appointments
  Future<void> _loadAppointmentDetail() async {
    setState(() => _isLoading = true);
    
    try {
      print('📋 Loading appointment ${widget.appointmentId} from list...');
      
      // Lấy tất cả appointments (không filter status để có đầy đủ)
      final appointments = await MechanicApiService.getMyAppointments();
      
      print('📋 Total appointments: ${appointments.length}');
      
      // Tìm appointment theo ID
      final appointment = appointments.firstWhere(
        (a) => a.appointmentId == widget.appointmentId,
        orElse: () => throw Exception('Không tìm thấy lịch hẹn #${widget.appointmentId}'),
      );
      
      setState(() {
        _appointment = appointment;
      });
      
      print('✅ Loaded appointment: ${appointment.appointmentId}');
      print('   Status: ${appointment.status}');
      print('   Customer: ${appointment.fullName ?? "N/A"}');
      
    } catch (e) {
      print('❌ Error loading appointment detail: $e');
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
        
        // Reload để lấy dữ liệu mới
        await _loadAppointmentDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getStatusLabel(String status) {
    final statusMap = {
      'Pending': 'Chờ xác nhận',
      'Confirmed': 'Đã xác nhận',
      'InProgress': 'Đang thực hiện',
      'Completed': 'Hoàn thành',
      'Canceled': 'Đã hủy',
    };
    return statusMap[status] ?? status;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'InProgress':
        return Colors.purple;
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
        return Icons.schedule;
      case 'Confirmed':
        return Icons.check_circle;
      case 'InProgress':
        return Icons.build;
      case 'Completed':
        return Icons.done_all;
      case 'Canceled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  /// Gọi điện thoại
  Future<void> _makePhoneCall() async {
    final phoneNumber = _appointment?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty || phoneNumber == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có số điện thoại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

  /// Parse services JSON
  List<Map<String, dynamic>> _parseServices(String? servicesJson) {
    if (servicesJson == null || servicesJson.isEmpty) {
      return [];
    }

    try {
      final parsed = json.decode(servicesJson);
      if (parsed is List) {
        return parsed.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('❌ Error parsing services: $e');
      return [];
    }
  }

  /// Format price
  String _formatPrice(dynamic price) {
    if (price == null) return '0đ';
    
    final priceValue = price is String ? double.tryParse(price) ?? 0 : price.toDouble();
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(priceValue)}đ';
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
              : RefreshIndicator(
                  onRefresh: _loadAppointmentDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        _buildServicesSection(),

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
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 100),
                      ],
                    ),
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
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _makePhoneCall,
                      icon: const Icon(Icons.phone, size: 20),
                      label: const Text('Gọi'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.green),
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openMap,
                      icon: const Icon(Icons.map, size: 20),
                      label: const Text('Bản đồ'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.blue),
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showStatusUpdateDialog(),
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Cập nhật'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.redAccent, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
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
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = _parseServices(_appointment!.services);
    
    if (services.isEmpty) {
      return _buildSection(
        icon: Icons.build_circle_outlined,
        title: 'Dịch vụ',
        children: [
          Text(
            'Không có dịch vụ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      );
    }

    return _buildSection(
      icon: Icons.build_circle_outlined,
      title: 'Dịch vụ',
      children: services.map((service) {
        final name = service['ServiceName'] ?? 'Không rõ';
        final price = service['Price'];
        final quantity = service['Quantity'] ?? 1;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (quantity > 1)
                      Text(
                        'Số lượng: x$quantity',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                _formatPrice(price),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Đã xác nhận'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('Confirmed');
              },
            ),
            ListTile(
              title: const Text('Đang thực hiện'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('InProgress');
              },
            ),
            ListTile(
              title: const Text('Hoàn thành'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('Completed');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm - dd/MM/yyyy', 'vi_VN').format(dateTime);
  }
}