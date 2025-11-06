// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suaxe_app/models/booking_model.dart';
import 'package:suaxe_app/services/api/booking_api.dart';
import 'package:suaxe_app/models/service_model.dart';

class UserBookingScreen extends StatefulWidget {
  final int userId;

  const UserBookingScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserBookingScreen> createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Chọn xe
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _isAddingNewVehicle = false;
  final _licensePlateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();

  // Step 2: Chọn dịch vụ
  List<ServiceModel> _services = [];
  List<int> _selectedServiceIds = [];

  // Step 3: Chọn ngày giờ
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load vehicles và services song song
      final results = await Future.wait([
        BookingApiService.getUserVehicles(widget.userId),
        BookingApiService.getAllServices(),
      ]);

      setState(() {
        _vehicles = results[0] as List<Vehicle>;
        _services = results[1] as List<ServiceModel>;
        if (_vehicles.isNotEmpty) {
          _selectedVehicle = _vehicles.first;
        }
      });
    } catch (e) {
      _showErrorDialog('Lỗi khi tải dữ liệu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch sửa xe'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.orange.shade700,
                ),
              ),
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        if (_currentStep < 2)
                          ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Tiếp tục'),
                          ),
                        if (_currentStep == 2)
                          ElevatedButton(
                            onPressed: _submitBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Xác nhận đặt lịch'),
                          ),
                        const SizedBox(width: 12),
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Quay lại'),
                          ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Chọn xe'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    content: _buildVehicleSelection(),
                  ),
                  Step(
                    title: const Text('Chọn dịch vụ'),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    content: _buildServiceSelection(),
                  ),
                  Step(
                    title: const Text('Chọn thời gian'),
                    isActive: _currentStep >= 2,
                    content: _buildDateTimeSelection(),
                  ),
                ],
              ),
            ),
    );
  }

  // ============ STEP 1: VEHICLE SELECTION ============
  Widget _buildVehicleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_vehicles.isEmpty && !_isAddingNewVehicle)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.directions_car, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Bạn chưa có xe nào'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isAddingNewVehicle = true),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm xe mới'),
                  ),
                ],
              ),
            ),
          ),
        if (_vehicles.isNotEmpty && !_isAddingNewVehicle) ...[
          const Text(
            'Chọn xe của bạn:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...(_vehicles.map((vehicle) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<Vehicle>(
                  value: vehicle,
                  groupValue: _selectedVehicle,
                  onChanged: (value) => setState(() => _selectedVehicle = value),
                  title: Text(
                    vehicle.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Biển số: ${vehicle.licensePlate}'),
                  secondary: const Icon(Icons.directions_car),
                ),
              ))),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _isAddingNewVehicle = true),
            icon: const Icon(Icons.add),
            label: const Text('Thêm xe mới'),
          ),
        ],
        if (_isAddingNewVehicle) _buildAddVehicleForm(),
      ],
    );
  }

  Widget _buildAddVehicleForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thêm xe mới',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _licensePlateController,
              decoration: const InputDecoration(
                labelText: 'Biển số xe *',
                hintText: 'VD: 51A-12345',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Hãng xe *',
                hintText: 'VD: Honda, Yamaha...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Dòng xe *',
                hintText: 'VD: Vision, Wave...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.motorcycle),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Năm sản xuất',
                hintText: 'VD: 2023',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveNewVehicle,
                  child: const Text('Lưu xe'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isAddingNewVehicle = false;
                      _clearVehicleForm();
                    });
                  },
                  child: const Text('Hủy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNewVehicle() async {
    if (_licensePlateController.text.isEmpty ||
        _brandController.text.isEmpty ||
        _modelController.text.isEmpty) {
      _showErrorDialog('Vui lòng điền đầy đủ thông tin xe');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newVehicle = Vehicle(
        userId: widget.userId,
        licensePlate: _licensePlateController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: _yearController.text.isNotEmpty 
            ? int.tryParse(_yearController.text) 
            : null,
      );

      final savedVehicle = await BookingApiService.addVehicle(newVehicle);
      
      setState(() {
        _vehicles.add(savedVehicle);
        _selectedVehicle = savedVehicle;
        _isAddingNewVehicle = false;
        _clearVehicleForm();
      });

      _showSuccessDialog('Đã thêm xe thành công');
    } catch (e) {
      _showErrorDialog('Lỗi khi thêm xe: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearVehicleForm() {
    _licensePlateController.clear();
    _brandController.clear();
    _modelController.clear();
    _yearController.clear();
  }

  // ============ STEP 2: SERVICE SELECTION ============
  Widget _buildServiceSelection() {
    if (_services.isEmpty) {
      return const Center(
        child: Text('Không có dịch vụ nào'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn dịch vụ cần sửa chữa:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...(_services.map((service) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: _selectedServiceIds.contains(service.serviceId),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedServiceIds.add(service.serviceId);
                    } else {
                      _selectedServiceIds.remove(service.serviceId);
                    }
                  });
                },
                title: Text(
                  service.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (service.description != null)
                      Text(
                        service.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          service.formattedPrice,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '⏱ ${service.formattedTime}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                secondary: service.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          service.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.build, size: 40),
                        ),
                      )
                    : const Icon(Icons.build, size: 40),
              ),
            ))),
        if (_selectedServiceIds.isNotEmpty) ...[
          const Divider(height: 32),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng kết:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Số dịch vụ đã chọn: ${_selectedServiceIds.length}'),
                  Text(
                    'Tổng tiền ước tính: ${_calculateTotalPrice()}',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('Thời gian ước tính: ${_calculateTotalTime()}'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _calculateTotalPrice() {
    double total = 0;
    for (var serviceId in _selectedServiceIds) {
      final service = _services.firstWhere((s) => s.serviceId == serviceId);
      total += service.price;
    }
    return total.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        ) +
        'đ';
  }

  String _calculateTotalTime() {
    int totalMinutes = 0;
    for (var serviceId in _selectedServiceIds) {
      final service = _services.firstWhere((s) => s.serviceId == serviceId);
      totalMinutes += service.estimatedTime;
    }
    
    if (totalMinutes < 60) {
      return '$totalMinutes phút';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) {
        return '$hours giờ';
      }
      return '$hours giờ $minutes phút';
    }
  }

  // ============ STEP 3: DATE TIME SELECTION ============
  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn ngày và giờ hẹn:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Ngày hẹn'),
            subtitle: Text(
              _selectedDate != null
                  ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                  : 'Chưa chọn',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _selectDate,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Giờ hẹn'),
            subtitle: Text(
              _selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'Chưa chọn',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _selectTime,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Ghi chú (tùy chọn)',
            hintText: 'Nhập thông tin bổ sung về tình trạng xe...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Tóm tắt đặt lịch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  '🚗 Xe:',
                  _selectedVehicle?.displayName ?? 'Chưa chọn',
                ),
                _buildSummaryRow(
                  '🔧 Dịch vụ:',
                  '${_selectedServiceIds.length} dịch vụ',
                ),
                _buildSummaryRow(
                  '💰 Giá ước tính:',
                  _calculateTotalPrice(),
                ),
                _buildSummaryRow(
                  '📅 Ngày:',
                  _selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                      : 'Chưa chọn',
                ),
                _buildSummaryRow(
                  '🕐 Giờ:',
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Chưa chọn',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade700,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade700,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  // ============ NAVIGATION ============
  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_selectedVehicle == null) {
        _showErrorDialog('Vui lòng chọn hoặc thêm xe');
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedServiceIds.isEmpty) {
        _showErrorDialog('Vui lòng chọn ít nhất một dịch vụ');
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // ============ SUBMIT BOOKING ============
  Future<void> _submitBooking() async {
    // Validate
    if (_selectedVehicle == null) {
      _showErrorDialog('Vui lòng chọn xe');
      return;
    }
    if (_selectedServiceIds.isEmpty) {
      _showErrorDialog('Vui lòng chọn dịch vụ');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showErrorDialog('Vui lòng chọn ngày và giờ hẹn');
      return;
    }

    // Tạo DateTime từ date và time
    final appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Kiểm tra thời gian hợp lệ (không được trong quá khứ)
    if (appointmentDateTime.isBefore(DateTime.now())) {
      _showErrorDialog('Thời gian hẹn không được trong quá khứ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = CreateBookingRequest(
        userId: widget.userId,
        vehicleId: _selectedVehicle!.vehicleId,
        appointmentDate: appointmentDateTime,
        notes: _notesController.text.trim(),
        serviceIds: _selectedServiceIds,
      );

      final booking = await BookingApiService.createAppointment(request);

      if (mounted) {
        // Show success dialog và quay về màn hình trước
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Đặt lịch thành công!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mã lịch hẹn: #${booking.appointmentId}'),
                const SizedBox(height: 8),
                Text(
                  'Thời gian: ${DateFormat('HH:mm dd/MM/yyyy').format(appointmentDateTime)}',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chúng tôi sẽ liên hệ với bạn để xác nhận lịch hẹn.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(booking); // Return to previous screen
                },
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Lỗi khi đặt lịch: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============ DIALOGS ============
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 12),
            Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
