import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:suaxe_app/models/payment_model.dart';
import 'package:suaxe_app/services/api/payment_api_service.dart';
import 'package:suaxe_app/utils/vietqr_helper.dart';

class PaymentScreen extends StatefulWidget {
  final int appointmentId;
  final String bookingCode;

  const PaymentScreen({
    Key? key,
    required this.appointmentId,
    required this.bookingCode,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentQRModel? _paymentData;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Countdown timer
  Timer? _countdownTimer;
  Duration _remainingTime = Duration(minutes: 15);
  
  // Upload
  File? _selectedProofImage;
  bool _isUploading = false;
  bool _uploadSuccess = false;
  
  // QR Screenshot
  final GlobalKey _qrKey = GlobalKey();

  // ✅ Cache QR image để không bị giật khi countdown update
  Uint8List? _cachedQRImage;
  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await PaymentApiService.getPaymentQR(widget.appointmentId);
      
      setState(() {
        _paymentData = data;
        _isLoading = false;
        
        // ✅ Cache QR image ngay khi load
        if (data.qrString.startsWith('data:image')) {
          final base64String = data.qrString.split(',')[1];
          _cachedQRImage = base64Decode(base64String);
        }
      });

      // Bắt đầu countdown
      _startCountdown();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _startCountdown() {
    if (_paymentData == null) return;

    _remainingTime = _paymentData!.expiryTime.difference(DateTime.now());
    
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = _paymentData!.expiryTime.difference(DateTime.now());
        
        if (_remainingTime.isNegative) {
          timer.cancel();
          _showTimeoutDialog();
        }
      });
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('⏰ Hết thời gian thanh toán'),
        content: Text('Thời gian thanh toán đã hết. Vui lòng đặt lịch lại.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to previous screen
            },
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _downloadQRCode() async {
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/QR_${widget.bookingCode}_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(file.path);

      _showSnackBar('✅ Đã lưu QR code vào thư viện');
    } catch (e) {
      print('Error downloading QR: $e');
      _showSnackBar('Lỗi khi lưu QR code: $e', isError: true);
    }
  }

  Future<void> _pickProofImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Chọn ảnh chứng từ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Chụp ảnh'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Chọn từ thư viện'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (pickedFile == null) return;

      final image = await picker.pickImage(source: pickedFile);
      
      if (image != null) {
        setState(() {
          _selectedProofImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Lỗi khi chọn ảnh: $e', isError: true);
    }
  }

  Future<void> _uploadProofImage() async {
    if (_selectedProofImage == null) {
      _showSnackBar('Vui lòng chọn ảnh chứng từ', isError: true);
      return;
    }

    try {
      setState(() => _isUploading = true);

      final response = await PaymentApiService.uploadPaymentProof(
        appointmentId: widget.appointmentId,
        imageFile: _selectedProofImage!,
      );

      setState(() {
        _isUploading = false;
        _uploadSuccess = response.success;
      });

      if (response.success) {
        _showSuccessDialog();
      } else {
        _showSnackBar('Upload thất bại: ${response.message}', isError: true);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnackBar('Lỗi khi upload: $e', isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Thành công!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đã gửi chứng từ thanh toán thành công!'),
            SizedBox(height: 12),
            Text(
              'Chứng từ của bạn đang chờ admin xác nhận. Bạn sẽ nhận được thông báo khi thanh toán được duyệt.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to bookings list
            },
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Đã copy $label');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thanh toán'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildPaymentView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Không thể tải thông tin thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPaymentData,
              child: Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentView() {
    if (_paymentData == null) return SizedBox();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Countdown Timer
          _buildCountdownCard(),
          SizedBox(height: 16),
          
          // QR Code
          _buildQRCodeCard(),
          SizedBox(height: 16),
          
          // Bank Info
          _buildBankInfoCard(),
          SizedBox(height: 16),
          
          // Upload Proof
          _buildUploadSection(),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    final isWarning = _remainingTime.inMinutes < 5;
    final isUrgent = _remainingTime.inMinutes < 2;
    
    return Card(
      color: isUrgent ? Colors.red[50] : isWarning ? Colors.orange[50] : Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.timer,
              size: 48,
              color: isUrgent ? Colors.red : isWarning ? Colors.orange : Colors.blue,
            ),
            SizedBox(height: 8),
            Text(
              'Thời gian còn lại',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            Text(
              _formatDuration(_remainingTime),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: isUrgent ? Colors.red : isWarning ? Colors.orange : Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              isUrgent 
                  ? '⚠️ Sắp hết thời gian! Vui lòng chuyển khoản ngay'
                  : 'Vui lòng hoàn tất thanh toán trong thời gian trên',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Quét mã QR để thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // QR Code with RepaintBoundary for screenshot
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Builder(
                  builder: (context) {
                    // ✅ Dùng cached image - không decode lại mỗi lần rebuild
                    if (_cachedQRImage != null) {
                      return Container(
                        width: 250,
                        height: 250,
                        color: Colors.white,
                        padding: EdgeInsets.all(8),
                        child: Image.memory(
                          _cachedQRImage!,
                          fit: BoxFit.contain,
                        ),
                      );
                    } else {
                      // Fallback - QR text string
                      return QrImageView(
                        data: _paymentData!.qrString,
                        version: QrVersions.auto,
                        size: 250,
                        backgroundColor: Colors.white,
                      );
                    }
                  },
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Download button
            OutlinedButton.icon(
              onPressed: _downloadQRCode,
              icon: Icon(Icons.download),
              label: Text('Lưu QR code'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            
            SizedBox(height: 8),
            Text(
              'Mã đơn: ${_paymentData!.bookingCode}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankInfoCard() {
    final bankInfo = _paymentData!.bankInfo;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin chuyển khoản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(height: 24),
            
            _buildInfoRow(
              'Ngân hàng',
              bankInfo.bankName,
              onTap: () => _copyToClipboard(bankInfo.bankName, 'tên ngân hàng'),
            ),
            _buildInfoRow(
              'Số tài khoản',
              bankInfo.accountNumber,
              onTap: () => _copyToClipboard(bankInfo.accountNumber, 'số tài khoản'),
            ),
            _buildInfoRow(
              'Chủ tài khoản',
              bankInfo.accountName,
              onTap: () => _copyToClipboard(bankInfo.accountName, 'chủ tài khoản'),
            ),
            _buildInfoRow(
              'Số tiền',
              '${_paymentData!.totalAmount.toStringAsFixed(0)} VNĐ',
              onTap: () => _copyToClipboard(_paymentData!.totalAmount.toStringAsFixed(0), 'số tiền'),
              valueColor: Colors.red,
              valueBold: true,
            ),
            _buildInfoRow(
              'Nội dung',
              bankInfo.transferContent,
              onTap: () => _copyToClipboard(bankInfo.transferContent, 'nội dung'),
              valueColor: Colors.orange,
              valueBold: true,
            ),
            
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vui lòng chuyển khoản ĐÚNG nội dung để hệ thống xác nhận tự động',
                      style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    VoidCallback? onTap,
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                        color: valueColor ?? Colors.black87,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.copy, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    if (_uploadSuccess) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 12),
              Text(
                'Đã gửi chứng từ thành công!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Chứng từ của bạn đang chờ admin xác nhận',
                style: TextStyle(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upload chứng từ chuyển khoản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Sau khi chuyển khoản, vui lòng chụp màn hình và upload để xác nhận',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            
            // Selected image preview
            if (_selectedProofImage != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedProofImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            SizedBox(height: 16),
            
            // Pick image button
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickProofImage,
              icon: Icon(Icons.image),
              label: Text(_selectedProofImage == null ? 'Chọn ảnh chứng từ' : 'Chọn ảnh khác'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            SizedBox(height: 12),
            
            // Upload button
            ElevatedButton.icon(
              onPressed: (_isUploading || _selectedProofImage == null) ? null : _uploadProofImage,
              icon: _isUploading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.upload),
              label: Text(_isUploading ? 'Đang upload...' : 'Gửi chứng từ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}