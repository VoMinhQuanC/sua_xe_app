import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suaxe_app/models/booking_model.dart';
import 'package:suaxe_app/services/api/booking_api.dart';
import 'user_booking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  final int userId;

  const MyBookingsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingModel> _allBookings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await BookingApiService.getAppointments();
      // Lọc chỉ lấy booking của user hiện tại
      setState(() {
        _allBookings = bookings
            .where((b) => b.userId == widget.userId)
            .toList()
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      });
    } catch (e) {
      _showErrorSnackBar('Lỗi khi tải lịch hẹn: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<BookingModel> _filterBookings(String status) {
    if (status == 'all') return _allBookings;
    return _allBookings.where((b) => b.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch hẹn của tôi'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.all_inbox),
                  const SizedBox(width: 8),
                  Text('Tất cả (${_allBookings.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.schedule),
                  const SizedBox(width: 8),
                  Text('Chờ xác nhận (${_filterBookings('Pending').length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  Text('Đã xác nhận (${_filterBookings('Confirmed').length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.verified),
                  const SizedBox(width: 8),
                  Text('Hoàn thành (${_filterBookings('Completed').length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.cancel),
                  const SizedBox(width: 8),
                  Text('Đã hủy (${_filterBookings('Canceled').length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingList(_allBookings),
                  _buildBookingList(_filterBookings('Pending')),
                  _buildBookingList(_filterBookings('Confirmed')),    // Mới thêm
                  _buildBookingList(_filterBookings('Completed')),
                  _buildBookingList(_filterBookings('Canceled')),     // Mới thêm
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateBooking,
        icon: const Icon(Icons.add),
        label: const Text('Đặt lịch mới'),
        backgroundColor: Colors.orange.shade700,
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không có lịch hẹn nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
          onTap: () => _navigateToBookingDetail(booking),
          onCancel: booking.status == 'Pending' || booking.status == 'Confirmed'
              ? () => _cancelBooking(booking)
              : null,
        );
      },
    );
  }

  Future<void> _navigateToCreateBooking() async {
    final result = await Navigator.push<BookingModel>(
      context,
      MaterialPageRoute(
        builder: (context) => UserBookingScreen(userId: widget.userId),
      ),
    );

    if (result != null) {
      // Reload bookings sau khi tạo mới
      _loadBookings();
    }
  }

  void _navigateToBookingDetail(BookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailScreen(
          bookingId: booking.appointmentId!,
          onUpdated: _loadBookings,
        ),
      ),
    );
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy lịch'),
        content: Text(
          'Bạn có chắc muốn hủy lịch hẹn vào ${DateFormat('HH:mm dd/MM/yyyy').format(booking.appointmentDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BookingApiService.cancelAppointment(
          booking.appointmentId!,
          'Khách hàng hủy',
        );
        _showSuccessSnackBar('Đã hủy lịch hẹn thành công');
        _loadBookings();
      } catch (e) {
        _showErrorSnackBar('Lỗi khi hủy lịch: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Widget Card cho mỗi booking
class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const BookingCard({
    Key? key,
    required this.booking,
    required this.onTap,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(
      int.parse(booking.statusColor.replaceFirst('#', '0xFF')),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                      booking.statusInVietnamese,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${booking.appointmentId}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm - dd/MM/yyyy').format(booking.appointmentDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (booking.licensePlate != null) ...[
                Row(
                  children: [
                    Icon(Icons.two_wheeler, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '${booking.brand ?? ''} ${booking.model ?? ''} - ${booking.licensePlate}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (booking.services != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.build, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.services!,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (onCancel != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 20),
                      label: const Text(
                        'HỦY LỊCH',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Màn hình chi tiết booking
class BookingDetailScreen extends StatefulWidget {
  final int bookingId;
  final VoidCallback? onUpdated;

  const BookingDetailScreen({
    Key? key,
    required this.bookingId,
    this.onUpdated,
  }) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingModel? _booking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBookingDetail();
  }

  Future<void> _loadBookingDetail() async {
    setState(() => _isLoading = true);
    try {
      final booking = await BookingApiService.getAppointmentById(widget.bookingId);
      setState(() => _booking = booking);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải chi tiết: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final statusColor = Color(
      int.parse(_booking!.statusColor.replaceFirst('#', '0xFF')),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch hẹn #${_booking!.appointmentId}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card - Nổi bật hơn
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.15),
                    statusColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline, color: statusColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trạng thái',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _booking!.statusInVietnamese,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Thông tin thời gian
            _buildInfoSection(
              'Thông tin lịch hẹn',
              [
                _buildInfoRow(
                  Icons.calendar_today,
                  'Ngày hẹn',
                  DateFormat('dd/MM/yyyy').format(_booking!.appointmentDate),
                ),
                _buildInfoRow(
                  Icons.access_time,
                  'Giờ hẹn',
                  DateFormat('HH:mm').format(_booking!.appointmentDate),
                ),
                if (_booking!.serviceDuration != null)
                  _buildInfoRow(
                    Icons.timer,
                    'Thời gian dự kiến',
                    '${_booking!.serviceDuration} phút',
                  ),
              ],  
            ),

            // Thông tin xe
            _buildInfoSection(
              'Thông tin xe',
              [
                _buildInfoRow(
                  Icons.two_wheeler,
                  'Biển số',
                  _booking!.licensePlate ?? 'N/A',
                ),
                _buildInfoRow(
                  Icons.business,
                  'Hãng xe',
                  '${_booking!.brand ?? ''} ${_booking!.model ?? ''}',
                ),
                if (_booking!.year != null)
                  _buildInfoRow(
                    Icons.calendar_month,
                    'Năm sản xuất',
                    _booking!.year.toString(),
                  ),
              ],
            ),

            // Dịch vụ
            if (_booking!.serviceDetails != null &&
                _booking!.serviceDetails!.isNotEmpty) ...[
              _buildInfoSection(
                'Dịch vụ đã chọn',
                _booking!.serviceDetails!
                    .map((service) => _buildServiceRow(service))
                    .toList(),
              ),
            ] else if (_booking!.services != null) ...[
              _buildInfoSection(
                'Dịch vụ',
                [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _parseServicesText(_booking!.services!),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],

            // Ghi chú
            if (_booking!.notes != null && _booking!.notes!.isNotEmpty)
              _buildInfoSection(
                'Ghi chú',
                [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(_booking!.notes!),
                  ),
                ],
              ),

            // Kỹ thuật viên
            if (_booking!.mechanicName != null)
              _buildInfoSection(
                'Kỹ thuật viên phụ trách',
                [
                  _buildInfoRow(
                    Icons.person,
                    'Tên',
                    _booking!.mechanicName!,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(BookingServiceDetail service) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.serviceName ?? 'Dịch vụ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (service.price != null)
                  Text(
                    service.formattedPrice,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (service.quantity > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'x${service.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _parseServicesText(String servicesText) {
    // Tách các service name từ raw text
    final regex = RegExp(r'ServiceName:\s*([^,}]+)');
    final matches = regex.allMatches(servicesText);
    
    if (matches.isEmpty) {
      return servicesText; // Trả về text gốc nếu không parse được
    }
    
    final serviceNames = matches.map((m) => m.group(1)?.trim()).where((s) => s != null).toList();
    return serviceNames.join(', ');
  }
}

extension on BookingServiceDetail {
  String get formattedPrice {
    return '${totalPrice.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}đ';
  }
}