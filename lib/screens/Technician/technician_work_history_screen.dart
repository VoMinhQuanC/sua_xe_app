// lib/screens/Technician/technician_work_history_screen.dart
// ✅ FIXED: Format services, add pull-to-refresh, better UI

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:suaxe_app/models/booking_model.dart';
import 'package:suaxe_app/services/api/mechanic_api_service.dart';
import 'technician_task_detail_screen.dart';

class TechnicianWorkHistoryScreen extends StatefulWidget {
  const TechnicianWorkHistoryScreen({super.key});

  @override
  State<TechnicianWorkHistoryScreen> createState() => _TechnicianWorkHistoryScreenState();
}

class _TechnicianWorkHistoryScreenState extends State<TechnicianWorkHistoryScreen> {
  bool _isLoading = false;
  List<BookingModel> _completedWorks = [];
  String _selectedFilter = 'Tất cả'; // Tất cả, Tuần này, Tháng này

  @override
  void initState() {
    super.initState();
    _loadWorkHistory();
  }

  /// Tải lịch sử công việc (chỉ lấy Completed)
  Future<void> _loadWorkHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // Lấy tất cả lịch hẹn đã hoàn thành
      final appointments = await MechanicApiService.getMyAppointments(
        status: 'Completed',
      );
      
      setState(() {
        _completedWorks = appointments;
        _applyFilter();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải lịch sử: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Áp dụng filter theo thời gian
  void _applyFilter() {
    final now = DateTime.now();
    
    if (_selectedFilter == 'Tuần này') {
      final weekStart = now.subtract(Duration(days: now.weekday % 7));
      _completedWorks = _completedWorks.where((work) {
        return work.appointmentDate.isAfter(weekStart);
      }).toList();
    } else if (_selectedFilter == 'Tháng này') {
      _completedWorks = _completedWorks.where((work) {
        return work.appointmentDate.month == now.month &&
               work.appointmentDate.year == now.year;
      }).toList();
    }
    // 'Tất cả' không cần filter
  }

  /// ✅ NEW: Parse services JSON string
  List<Map<String, dynamic>> _parseServices(String? servicesJson) {
    if (servicesJson == null || servicesJson.isEmpty) {
      return [];
    }

    try {
      // Try to parse as JSON array
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

  /// ✅ NEW: Format price to VND
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
          'Lịch sử công việc',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWorkHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Thống kê
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                _buildStatCard(
                  'Tổng số',
                  _completedWorks.length,
                  Colors.blue,
                  Icons.assignment_turned_in,
                ),
                _buildStatCard(
                  'Đánh giá TB',
                  '4.8',
                  Colors.amber,
                  Icons.star,
                ),
              ],
            ),
          ),

          // Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['Tất cả', 'Tuần này', 'Tháng này'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                        _loadWorkHistory(); // Reload với filter mới
                      });
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

          // Danh sách lịch sử
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _completedWorks.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadWorkHistory,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 400,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có lịch sử công việc',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '👆 Kéo xuống để tải lại',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadWorkHistory,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _completedWorks.length,
                          itemBuilder: (context, index) {
                            final work = _completedWorks[index];
                            return _buildHistoryCard(work);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
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
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BookingModel work) {
    // ✅ Parse services
    final services = _parseServices(work.services);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TechnicianTaskDetailScreen(
                appointmentId: work.appointmentId!,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tên khách + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work.fullName ?? 'Khách hàng',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(work.appointmentDate),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Hoàn thành',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 20),
              
              // ✅ FIXED: Services list formatted
              if (services.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.build_circle_outlined, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dịch vụ đã thực hiện:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...services.map((service) {
                            final name = service['ServiceName'] ?? 'Không rõ';
                            final price = service['Price'];
                            final quantity = service['Quantity'] ?? 1;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$name${quantity > 1 ? " x$quantity" : ""}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    _formatPrice(price),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Vehicle info
              Row(
                children: [
                  Icon(Icons.two_wheeler, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${work.brand ?? ''} ${work.model ?? ''} - ${work.licensePlate ?? ''}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
              
              // Rating
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '5.0',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '• Khách hàng hài lòng',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hôm nay - ${DateFormat('HH:mm').format(date)}';
    } else if (dateOnly == yesterday) {
      return 'Hôm qua - ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy - HH:mm').format(date);
    }
  }
}