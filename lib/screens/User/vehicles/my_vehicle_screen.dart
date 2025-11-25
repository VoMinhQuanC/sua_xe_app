import 'package:flutter/material.dart';
import 'package:suaxe_app/models/vehicle_model.dart';
import 'package:suaxe_app/services/api/vehicle_api_service.dart';
import '../vehicles/add_edit_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
  final int userId;

  const MyVehiclesScreen({super.key, required this.userId});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  bool _isLoading = true;
  List<VehicleModel> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await VehicleApiService.getUserVehicles(widget.userId);
      setState(() {
        _vehicles = vehicles;
      });
    } catch (e) {
      print('Lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVehicle(VehicleModel vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa xe ${vehicle.licensePlate}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await VehicleApiService.deleteVehicle(vehicle.vehicleId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa xe thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadVehicles();
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xe của tôi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.two_wheeler,
                        size: 100,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có xe nào',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditVehicleScreen(
                                userId: widget.userId,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadVehicles();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm xe mới'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.two_wheeler,
                            color: Colors.redAccent,
                            size: 32,
                          ),
                        ),
                        title: Text(
                          vehicle.licensePlate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (vehicle.brand != null ||
                                vehicle.model != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                vehicle.displayName,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            if (vehicle.year != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Năm: ${vehicle.year}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddEditVehicleScreen(
                                      userId: widget.userId,
                                      vehicle: vehicle,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadVehicles();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _deleteVehicle(vehicle),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _vehicles.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditVehicleScreen(
                      userId: widget.userId,
                    ),
                  ),
                );
                if (result == true) {
                  _loadVehicles();
                }
              },
              backgroundColor: Colors.redAccent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Thêm xe',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}