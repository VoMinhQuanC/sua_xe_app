import 'package:flutter/material.dart';
import 'package:suaxe_app/models/vehicle_model.dart';
import 'package:suaxe_app/services/api/vehicle_api_service.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final int userId;
  final VehicleModel? vehicle;

  const AddEditVehicleScreen({
    super.key,
    required this.userId,
    this.vehicle,
  });

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();

  bool _isLoading = false;
  bool get _isEdit => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _licensePlateController.text = widget.vehicle!.licensePlate;
      _brandController.text = widget.vehicle!.brand ?? '';
      _modelController.text = widget.vehicle!.model ?? '';
      _yearController.text = widget.vehicle!.year?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vehicle = VehicleModel(
        vehicleId: widget.vehicle?.vehicleId,
        userId: widget.userId,
        licensePlate: _licensePlateController.text.trim().toUpperCase(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        year: _yearController.text.trim().isEmpty
            ? null
            : int.tryParse(_yearController.text.trim()),
      );

      if (_isEdit) {
        await VehicleApiService.updateVehicle(
          widget.vehicle!.vehicleId!,
          vehicle,
        );
      } else {
        await VehicleApiService.createVehicle(vehicle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Cập nhật xe thành công' : 'Thêm xe thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Chỉnh sửa xe' : 'Thêm xe mới',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon xe
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.two_wheeler,
                    size: 60,
                    color: Colors.redAccent,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Biển số xe
              const Text(
                'Biển số xe *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _licensePlateController,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: 59A12345',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập biển số xe';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Hãng xe
              const Text(
                'Hãng xe',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Honda, Yamaha, SYM...',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 20),

              // Mẫu xe
              const Text(
                'Mẫu xe',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: SH Mode, Wave, Vision...',
                  prefixIcon: const Icon(Icons.two_wheeler),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 20),

              // Năm sản xuất
              const Text(
                'Năm sản xuất',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: 2020',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final year = int.tryParse(value.trim());
                    if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                      return 'Năm không hợp lệ';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Nút lưu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Cập nhật' : 'Thêm xe',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}