// ignore_for_file: prefer_final_fields
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suaxe_app/models/booking_model.dart';
import 'package:suaxe_app/services/api/booking_api.dart';
import 'package:suaxe_app/models/service_model.dart';
import 'package:suaxe_app/models/mechanic_model.dart';
import 'package:suaxe_app/models/time_slot_model.dart';
import 'package:suaxe_app/services/api/schedule_api.dart';

class UserBookingScreen extends StatefulWidget {
  final int userId;

  const UserBookingScreen({super.key, required this.userId});

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

  // Step 3: Chọn ngày giờ + kỹ thuật viên
  DateTime? _selectedDate;
  List<TimeSlotModel> _timeSlots = [];
  String? _selectedTimeSlot;
  List<MechanicModel> _availableMechanics = [];
  MechanicModel? _selectedMechanic;
  final _notesController = TextEditingController();

  // Step 5: Thanh toán
  String _paymentMethod = 'cash';

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

  double get _totalPrice {
    double total = 0;
    for (var serviceId in _selectedServiceIds) {
      final service = _services.firstWhere((s) => s.serviceId == serviceId);
      total += service.price;
    }
    return total;
  }

  int get _totalTime {
    int total = 0;
    for (var serviceId in _selectedServiceIds) {
      final service = _services.firstWhere((s) => s.serviceId == serviceId);
      total += service.estimatedTime;
    }
    return total;
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}đ';
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes phút';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours giờ';
      }
      return '$hours giờ $mins phút';
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
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              onStepTapped: (step) => setState(() => _currentStep = step),
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      if (_currentStep < 4)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Tiếp tục'),
                          ),
                        ),
                      if (_currentStep == 4)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Hoàn tất đặt lịch'),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 12),
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Quay lại'),
                          ),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Chọn xe'),
                  content: _buildVehicleStep(),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Chọn dịch vụ'),
                  content: _buildServiceStep(),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Chọn thời gian'),
                  content: _buildDateTimeStep(),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Xác nhận'),
                  content: _buildConfirmationStep(),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Thanh toán'),
                  content: _buildPaymentStep(),
                  isActive: _currentStep >= 4,
                  state: _currentStep > 4 ? StepState.complete : StepState.indexed,
                ),
              ],
            ),
    );
  }

  // ===== STEP 1: CHỌN XE =====
  Widget _buildVehicleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isAddingNewVehicle && _vehicles.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn xe của bạn:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...(_vehicles.map((vehicle) => RadioListTile<Vehicle>(
                    title: Text(vehicle.licensePlate),
                    subtitle: Text('${vehicle.brand} ${vehicle.model} (${vehicle.year})'),
                    value: vehicle,
                    groupValue: _selectedVehicle,
                    onChanged: (value) {
                      setState(() => _selectedVehicle = value);
                    },
                  ))),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => setState(() => _isAddingNewVehicle = true),
                icon: const Icon(Icons.add),
                label: const Text('Thêm xe mới'),
              ),
            ],
          ),
        if (_isAddingNewVehicle || _vehicles.isEmpty)
          Column(
            children: [
              TextField(
                controller: _licensePlateController,
                decoration: const InputDecoration(
                  labelText: 'Biển số xe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Hãng xe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Dòng xe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Năm sản xuất',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addNewVehicle,
                      child: const Text('Lưu xe'),
                    ),
                  ),
                  if (_vehicles.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isAddingNewVehicle = false),
                        child: const Text('Hủy'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
      ],
    );
  }

  // ===== STEP 2: CHỌN DỊCH VỤ =====
  Widget _buildServiceStep() {
    if (_services.isEmpty) {
      return const Center(child: Text('Không có dịch vụ nào'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn dịch vụ cần sửa chữa:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              children: _services.map((service) => Card(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (service.description != null)
                        Text(
                          service.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            service.formattedPrice,
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '⏱ ${service.formattedTime}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  secondary: service.imageUrl != null && service.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            service.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.build,
                                  color: Colors.grey[400],
                                  size: 30,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.build,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                        ),
                ),
              )).toList(),
            ),
          ),
        ),
        
        if (_selectedServiceIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatPrice(_totalPrice),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thời gian dự kiến:',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      _formatTime(_totalTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===== STEP 3: CHỌN NGÀY GIỜ + KỸ THUẬT VIÊN =====
  Widget _buildDateTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn ngày đặt lịch:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Chọn ngày
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(_selectedDate == null
              ? 'Chọn ngày'
              : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _selectDate,
          tileColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        // Khung giờ
        if (_selectedDate != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Khung giờ có sẵn:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot.time;
              return ChoiceChip(
                label: Text(slot.time),
                selected: isSelected,
                onSelected: slot.isAvailable
                    ? (selected) {
                        if (selected) {
                          _onTimeSlotSelected(slot.time);
                        }
                      }
                    : null,
                selectedColor: Colors.blue,
                backgroundColor: slot.isAvailable ? Colors.white : Colors.grey[300],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
        ],
        
        // Kỹ thuật viên
        if (_selectedTimeSlot != null && _availableMechanics.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Chọn kỹ thuật viên: $_selectedTimeSlot',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              child: Column(
                children: _availableMechanics.map((mechanic) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<int>(
                      value: mechanic.mechanicId,
                      groupValue: _selectedMechanic?.mechanicId,
                      onChanged: (value) {
                        setState(() {
                          _selectedMechanic = mechanic;
                        });
                      },
                      title: Text(
                        mechanic.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mechanic.statusText,
                            style: TextStyle(
                              color: mechanic.isAvailable ? Colors.green : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                          if (mechanic.estimatedEndTime != null)
                            Text(
                              mechanic.estimatedEndTimeText,
                              style: const TextStyle(fontSize: 11),
                            ),
                        ],
                      ),
                      secondary: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          mechanic.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        
        // Ghi chú
        const SizedBox(height: 20),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Ghi chú (không bắt buộc)',
            border: OutlineInputBorder(),
            hintText: 'Nhập ghi chú cho lịch hẹn...',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  // ===== STEP 4: XÁC NHẬN THÔNG TIN =====
  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xác nhận thông tin đặt lịch',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        // Thông tin dịch vụ
        _buildInfoCard(
          title: 'Thông tin dịch vụ',
          children: [
            ..._selectedServiceIds.map((id) {
              final service = _services.firstWhere((s) => s.serviceId == id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(service.serviceName)),
                    Text(service.formattedPrice, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  _formatPrice(_totalPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Thông tin xe
        _buildInfoCard(
          title: 'Thông tin xe',
          children: [
            _buildInfoRow('Biển số', _selectedVehicle?.licensePlate ?? ''),
            _buildInfoRow('Hãng xe', _selectedVehicle?.brand ?? ''),
            _buildInfoRow('Dòng xe', _selectedVehicle?.model ?? ''),
            _buildInfoRow('Năm sản xuất', _selectedVehicle?.year?.toString() ?? ''),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Thời gian đặt lịch
        _buildInfoCard(
          title: 'Thời gian đặt lịch',
          children: [
            _buildInfoRow('Ngày', _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : ''),
            _buildInfoRow('Thời gian bắt đầu', _selectedTimeSlot ?? ''),
            _buildInfoRow('Thời gian dự kiến kết thúc', _getEstimatedEndTime()),
            _buildInfoRow('Tổng thời gian dịch vụ', _formatTime(_totalTime)),
            _buildInfoRow('Kỹ thuật viên', _selectedMechanic?.fullName ?? ''),
          ],
        ),
        
        if (_notesController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoCard(
            title: 'Ghi chú',
            children: [
              Text(_notesController.text),
            ],
          ),
        ],
      ],
    );
  }

  // ===== STEP 5: THANH TOÁN =====
  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn phương thức thanh toán',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        Card(
          child: RadioListTile<String>(
            value: 'cash',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() => _paymentMethod = value!);
            },
            title: const Text('💵 Thanh toán tại tiệm'),
            subtitle: const Text('Thanh toán trực tiếp bằng tiền mặt khi đến cửa hàng'),
            secondary: const Icon(Icons.money, color: Colors.green),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Card(
          child: RadioListTile<String>(
            value: 'transfer',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() => _paymentMethod = value!);
            },
            title: const Text('🏦 Chuyển khoản ngân hàng'),
            subtitle: const Text('Chuyển khoản trước để đảm bảo đặt chỗ'),
            secondary: const Icon(Icons.account_balance, color: Colors.blue),
          ),
        ),
        
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Thông tin:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Thời gian dịch vụ dự kiến là ${_formatTime(_totalTime)}. '
                'Các khung giờ không khả dụng là do kỹ thuật viên đã có lịch hẹn khác trong khoảng thời gian này.',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== HELPER WIDGETS =====
  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _getEstimatedEndTime() {
    if (_selectedDate == null || _selectedTimeSlot == null) return '';
    
    final timeParts = _selectedTimeSlot!.split(':');
    final startHour = int.parse(timeParts[0]);
    final startMinute = int.parse(timeParts[1]);
    
    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      startHour,
      startMinute,
    );
    
    final endDateTime = startDateTime.add(Duration(minutes: _totalTime));
    
    return '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
  }

  // ===== XỬ LÝ NAVIGATION =====
  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_selectedVehicle == null) {
        _showErrorDialog('Vui lòng chọn xe');
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedServiceIds.isEmpty) {
        _showErrorDialog('Vui lòng chọn ít nhất một dịch vụ');
        return;
      }
    } else if (_currentStep == 2) {
      if (_selectedDate == null) {
        _showErrorDialog('Vui lòng chọn ngày');
        return;
      }
      if (_selectedTimeSlot == null) {
        _showErrorDialog('Vui lòng chọn khung giờ');
        return;
      }
      if (_selectedMechanic == null) {
        _showErrorDialog('Vui lòng chọn kỹ thuật viên');
        return;
      }
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // ===== XỬ LÝ CHỌN NGÀY & KHUNG GIỜ =====
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
        _selectedMechanic = null;
        _availableMechanics = [];
      });
      _loadTimeSlots();
    }
  }

  Future<void> _loadTimeSlots() async {
    if (_selectedDate == null) return;
    
    setState(() => _isLoading = true);
    try {
      final slots = await ScheduleApiService.getAvailableTimeSlots(_selectedDate!);
      setState(() {
        _timeSlots = slots;
      });
    } catch (e) {
      _showErrorDialog('Lỗi khi tải khung giờ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onTimeSlotSelected(String timeSlot) async {
    setState(() {
      _selectedTimeSlot = timeSlot;
      _isLoading = true;
    });
    
    try {
      final mechanics = await ScheduleApiService.getAvailableMechanics(
        date: _selectedDate!,
        time: timeSlot,
      );
      
      setState(() {
        _availableMechanics = mechanics;
        _selectedMechanic = mechanics.isNotEmpty ? mechanics.first : null;
      });
    } catch (e) {
      _showErrorDialog('Lỗi khi tải kỹ thuật viên: $e');
      setState(() {
        _availableMechanics = [];
        _selectedMechanic = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===== XỬ LÝ THÊM XE MỚI =====
  Future<void> _addNewVehicle() async {
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
        licensePlate: _licensePlateController.text,
        brand: _brandController.text,
        model: _modelController.text,
        year: _yearController.text.isNotEmpty 
            ? int.tryParse(_yearController.text) 
            : null,
      );

      final addedVehicle = await BookingApiService.addVehicle(newVehicle);
      
      setState(() {
        _vehicles.add(addedVehicle);
        _selectedVehicle = addedVehicle;
        _isAddingNewVehicle = false;
        _licensePlateController.clear();
        _brandController.clear();
        _modelController.clear();
        _yearController.clear();
      });

      _showSuccessDialog('Thêm xe thành công!');
    } catch (e) {
      _showErrorDialog('Lỗi khi thêm xe: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===== SUBMIT BOOKING =====
  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedTimeSlot == null || _selectedMechanic == null) {
      _showErrorDialog('Vui lòng kiểm tra lại thông tin');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final timeParts = _selectedTimeSlot!.split(':');
      final appointmentDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final request = CreateBookingRequest(
        userId: widget.userId,
        vehicleId: _selectedVehicle!.vehicleId,
        appointmentDate: appointmentDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        serviceIds: _selectedServiceIds,
      );

      final result = await BookingApiService.createAppointment(request);
      
      if (!mounted) return;
      
      // Hiển thị dialog thành công
      _showSuccessBookingDialog(result);
      
    } catch (e) {
      _showErrorDialog('Lỗi khi đặt lịch: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===== DIALOGS =====
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thành công'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessBookingDialog(BookingModel booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đặt lịch thành công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cảm ơn bạn đã đặt lịch sửa xe tại chúng tôi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Thông tin đặt lịch của bạn đã được lưu lại.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (booking.appointmentId != null)
                    Text(
                      'Mã đặt lịch: BK${booking.appointmentId}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhân viên của chúng tôi sẽ liên hệ với bạn để xác nhận lịch hẹn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close booking screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Xem lịch sử đặt lịch',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close booking screen
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Về trang chủ',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}