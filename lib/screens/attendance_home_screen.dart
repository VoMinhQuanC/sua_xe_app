import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../models/attendance_model.dart';
import 'attendance_history_screen.dart';

class AttendanceHomeScreen extends StatefulWidget {
  const AttendanceHomeScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHomeScreen> createState() => _AttendanceHomeScreenState();
}

class _AttendanceHomeScreenState extends State<AttendanceHomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  
  MobileScannerController? controller;
  bool _isProcessing = false;
  bool _hasCheckedIn = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  String? _todaySchedule;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    _loadTodayStatus();
    _requestLocationPermission();
  }
  
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
  
  // Load trạng thái check-in hôm nay
  Future<void> _loadTodayStatus() async {
    print('🔄 Loading today status...');
    setState(() => _isLoading = true);
    
    try {
      final today = await _attendanceService.getTodayAttendance();
      
      if (today != null) {
        print('✅ Today attendance found');
        setState(() {
          _hasCheckedIn = today.checkInTime != null;
          _checkInTime = today.checkInTime;
          _checkOutTime = today.checkOutTime;
          
          if (today.scheduledStartTime != null && today.scheduledEndTime != null) {
            _todaySchedule = '${today.scheduledStartTime!.substring(0, 5)}-${today.scheduledEndTime!.substring(0, 5)}';
          }
          _isLoading = false;
        });
      } else {
        print('✅ No attendance today');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading today status: $e');
      setState(() => _isLoading = false);
    }
  }
  
  // Request GPS permission
  Future<void> _requestLocationPermission() async {
    print('🔍 Checking location permission...');
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      print('⚠️ Permission denied, requesting...');
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('❌ Permission denied forever');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng cấp quyền GPS trong Cài đặt'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      print('✅ Location permission granted');
    }
  }
  
  // Xử lý QR code
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? qrCode = barcodes.first.rawValue;
    if (qrCode == null || qrCode.isEmpty) return;
    
    print('📱 QR Code detected: $qrCode');
    
    setState(() => _isProcessing = true);
    controller?.stop();
    
    try {
      print('🔍 Getting GPS location...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      print('✅ Location: ${position.latitude}, ${position.longitude}');
      
      // Check-in hoặc check-out
      AttendanceModel? result;
      if (!_hasCheckedIn) {
        print('➡️ Calling check-in API...');
        result = await _attendanceService.checkIn(
          qrToken: qrCode,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        
        if (result != null) {
          print('✅ Check-in success');
          setState(() {
            _hasCheckedIn = true;
            _checkInTime = result!.checkInTime;
            if (result.scheduledStartTime != null && result.scheduledEndTime != null) {
              _todaySchedule = '${result.scheduledStartTime!.substring(0, 5)}-${result.scheduledEndTime!.substring(0, 5)}';
            }
          });
          
          _showSuccessDialog(
            'Check-in thành công!',
            'Giờ vào: ${_formatTime(_checkInTime!)}\n'
            '${_todaySchedule != null ? 'Ca làm việc: $_todaySchedule' : ''}',
          );
        }
      } else {
        print('➡️ Calling check-out API...');
        result = await _attendanceService.checkOut(
          qrToken: qrCode,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        
        if (result != null) {
          print('✅ Check-out success');
          setState(() {
            _checkOutTime = result!.checkOutTime;
          });
          
          String message = 'Giờ ra: ${_formatTime(_checkOutTime!)}\n';
          if (result.actualWorkHours != null) {
            message += 'Giờ làm: ${result.actualWorkHours}h\n';
          }
          if (result.overtimeHours != null && result.overtimeHours! > 0) {
            message += 'Tăng ca: +${result.overtimeHours}h';
          }
          
          _showSuccessDialog('Check-out thành công!', message);
        }
      }
    } on Exception catch (e) {
      print('❌ Exception: $e');
      
      // ✅ FIX: Nếu backend báo "đã check-in rồi", reload lại trạng thái
      String errorMessage = e.toString();
      if (errorMessage.contains('Đã chấm công vào rồi') || 
          errorMessage.contains('đã check-in')) {
        print('⚠️ Backend says already checked in, reloading status...');
        
        // Reload trạng thái từ backend
        await _loadTodayStatus();
        
        _showErrorDialog('Bạn đã chấm công vào rồi!\n\nĐã cập nhật trạng thái mới.');
      } else {
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      print('❌ Error: $e');
      _showErrorDialog('Lỗi không xác định: $e');
    } finally {
      setState(() => _isProcessing = false);
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          controller?.start();
        }
      });
    }
  }
  
  // Format time từ DateTime
  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  // Success dialog
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // Error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Thông báo'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chấm công'),
        backgroundColor: Color(0xFFE53935),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceHistoryScreen(),
                ),
              );
            },
          ),
          // ✅ THÊM REFRESH BUTTON
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadTodayStatus();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE53935)),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu...'),
                ],
              ),
            )
          : Column(
              children: [
                // Status Card
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _hasCheckedIn && _checkOutTime == null
                          ? [Colors.green[400]!, Colors.green[600]!]
                          : _checkOutTime != null
                              ? [Colors.blue[400]!, Colors.blue[600]!]
                              : [Colors.orange[400]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Ngày hôm nay
                      Text(
                        DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasCheckedIn && _checkOutTime == null
                                ? Icons.check_circle
                                : _checkOutTime != null
                                    ? Icons.done_all
                                    : Icons.pending,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Text(
                            _hasCheckedIn && _checkOutTime == null
                                ? 'Đã check-in'
                                : _checkOutTime != null
                                    ? 'Đã hoàn thành'
                                    : 'Chưa check-in',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      // Check-in/out times
                      if (_checkInTime != null) ...[
                        SizedBox(height: 20),
                        Divider(color: Colors.white54),
                        SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.login, color: Colors.white70),
                                SizedBox(height: 8),
                                Text(
                                  'Check-in',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _formatTime(_checkInTime!),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            
                            if (_checkOutTime != null)
                              Column(
                                children: [
                                  Icon(Icons.logout, color: Colors.white70),
                                  SizedBox(height: 8),
                                  Text(
                                    'Check-out',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _formatTime(_checkOutTime!),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        
                        // Ca làm việc
                        if (_todaySchedule != null) ...[
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Ca: $_todaySchedule',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                
                // Instruction
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _hasCheckedIn && _checkOutTime == null
                              ? 'Quét mã QR để check-out'
                              : _checkOutTime != null
                                  ? 'Đã hoàn thành chấm công hôm nay'
                                  : 'Quét mã QR để check-in',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // QR Scanner
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: controller,
                          onDetect: _onDetect,
                        ),
                        
                        // Overlay frame
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        
                        if (_isProcessing)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(height: 16),
                                  Text(
                                    'Đang xử lý...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
              ],
            ),
    );
  }
}