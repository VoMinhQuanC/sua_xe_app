// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/api/api_service.dart';


class UserServiceScreen extends StatefulWidget {
  const UserServiceScreen({super.key});

  @override
  State<UserServiceScreen> createState() => _UserServiceScreenState();
}

class _UserServiceScreenState extends State<UserServiceScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> services = [];
  List<dynamic> filteredServices = [];
  bool isLoading = true;
  String errorMessage = '';
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Lấy danh sách dịch vụ từ API
  Future<void> fetchServices() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await _apiService.getServices();
      
      if (mounted) {
        if (response.statusCode == 200) {
          final data = response.data;
          setState(() {
            services = data['services'] ?? [];
            filteredServices = services;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Không thể tải dịch vụ. Mã lỗi: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = _handleDioError(e);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Lỗi không xác định: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  /// Xử lý lỗi Dio
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Kết nối quá lâu. Vui lòng thử lại.';
      case DioExceptionType.sendTimeout:
        return 'Gửi dữ liệu quá lâu. Vui lòng thử lại.';
      case DioExceptionType.receiveTimeout:
        return 'Nhận dữ liệu quá lâu. Vui lòng thử lại.';
      case DioExceptionType.badResponse:
        return 'Lỗi từ server: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';
      case DioExceptionType.connectionError:
        return 'Không có kết nối internet. Vui lòng kiểm tra lại.';
      default:
        return 'Lỗi kết nối: ${e.message}';
    }
  }

  /// Tìm kiếm dịch vụ
  void searchServices(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredServices = services;
      } else {
        filteredServices = services.where((service) {
          final serviceName = (service['ServiceName'] ?? '').toString().toLowerCase();
          return serviceName.contains(keyword.toLowerCase());
        }).toList();
      }
    });
  }

  /// Format giá tiền
  String formatPrice(dynamic price) {
    if (price == null) return '0 ₫';
    return '${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} ₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dịch vụ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchServices,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: searchServices,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm dịch vụ...',
          prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    searchServices('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (filteredServices.isEmpty) {
      return _buildEmptyState();
    }

    return _buildServiceList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.redAccent),
          SizedBox(height: 16),
          Text(
            'Đang tải dịch vụ...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchServices,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isNotEmpty 
                ? Icons.search_off 
                : Icons.inbox_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'Không tìm thấy dịch vụ phù hợp'
                : 'Chưa có dịch vụ nào',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Thử tìm với từ khóa khác'
                : 'Vui lòng quay lại sau',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList() {
    return RefreshIndicator(
      color: Colors.redAccent,
      onRefresh: fetchServices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredServices.length,
        itemBuilder: (context, index) {
          final service = filteredServices[index];
          return _ServiceCard(
            service: service,
            formatPrice: formatPrice,
          );
        },
      ),
    );
  }
}

/// Widget Card hiển thị dịch vụ
class _ServiceCard extends StatelessWidget {
  final dynamic service;
  final String Function(dynamic) formatPrice;

  const _ServiceCard({
    required this.service,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = service['ServiceImage'] ?? '';
    final String serviceName = service['ServiceName'] ?? 'Dịch vụ';
    final dynamic price = service['Price'];
    final int serviceId = service['ServiceId'] ?? 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceImage(imageUrl),
            _buildServiceInfo(context, serviceName, price),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImageError(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildImageLoading(loadingProgress);
              },
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey[300],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Không thể tải hình', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildImageLoading(ImageChunkEvent loadingProgress) {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[200]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.car_repair, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text('Dịch vụ sửa xe', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildServiceInfo(BuildContext context, String serviceName, dynamic price) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            serviceName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.attach_money,
                  size: 20,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  formatPrice(price),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _navigateToDetail(context),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Xem chi tiết'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ServiceDetailScreen(service: service),
      ),
    );
  }
}

/// Màn hình chi tiết dịch vụ
class _ServiceDetailScreen extends StatelessWidget {
  final dynamic service;

  const _ServiceDetailScreen({required this.service});

  String formatPrice(dynamic price) {
    if (price == null) return '0 ₫';
    return '${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = service['ServiceImage'] ?? '';
    final String serviceName = service['ServiceName'] ?? 'Dịch vụ';
    final dynamic price = service['Price'];
    final String description =
        service['Description'] ?? 'Chưa có mô tả chi tiết cho dịch vụ này.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, imageUrl, serviceName),
          _buildContent(context, serviceName, price, description),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String imageUrl, String serviceName) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.redAccent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrl.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildImageError(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[300],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text('Không thể tải hình ảnh', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.car_repair, size: 80, color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Dịch vụ sửa xe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String serviceName,
    dynamic price,
    String description,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service name
            Text(
              serviceName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            // Price box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent.withOpacity(0.1),
                    Colors.redAccent.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giá dịch vụ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatPrice(price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            // Description section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Mô tả dịch vụ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Booking button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _handleBooking(context),
                icon: const Icon(Icons.calendar_today, size: 20),
                label: const Text(
                  'Đặt lịch ngay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Colors.redAccent.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBooking(BuildContext context) {
    // TODO: Navigate to booking screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => UserBookingScreen(service: service),
    //   ),
    // );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Chức năng đặt lịch đang được phát triển'),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}