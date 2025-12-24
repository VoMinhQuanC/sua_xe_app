/// Helper class để tạo VietQR string theo chuẩn EMVCo
class VietQRHelper {
  /// Generate VietQR string để hiển thị QR code
  /// 
  /// Chuẩn: EMVCo QR Code Specification for Payment Systems
  /// 
  /// Parameters:
  /// - [bankCode]: Mã BIN ngân hàng (VD: 970422 = MB Bank)
  /// - [accountNo]: Số tài khoản
  /// - [accountName]: Tên chủ tài khoản
  /// - [amount]: Số tiền (VNĐ)
  /// - [description]: Nội dung chuyển khoản
  static String generateQRString({
    required String bankCode,
    required String accountNo,
    required String accountName,
    required double amount,
    required String description,
  }) {
    // Format amount (remove decimals for VND)
    final amountStr = amount.toStringAsFixed(0);
    
    // Build consumer account information (Tag 38)
    final beneficiaryId = _buildTag('00', bankCode);
    final consumerId = _buildTag('01', accountNo);
    final serviceCode = _buildTag('02', 'QRIBFTTA'); // VietQR service code
    
    final consumerAccountInfo = _buildTag(
      '38',
      beneficiaryId + consumerId + serviceCode,
    );
    
    // Build additional data (Tag 62)
    final billNumber = _buildTag('08', description);
    final additionalData = _buildTag('62', billNumber);
    
    // Build complete QR string
    final qrString = 
      '00020101021' + // Payload Format Indicator (Tag 00) + Point of Initiation (Tag 01)
      consumerAccountInfo + // Consumer Account Info (Tag 38)
      '5303704' + // Transaction Currency (Tag 53) - 704 = VND
      '54${amountStr.length.toString().padLeft(2, '0')}$amountStr' + // Amount (Tag 54)
      '5802VN' + // Country Code (Tag 58)
      additionalData + // Additional Data (Tag 62)
      '6304'; // CRC (Tag 63) - Will be calculated as checksum
    
    // Calculate CRC16-CCITT checksum
    final crc = _calculateCRC16(qrString);
    
    return qrString + crc;
  }
  
  /// Build EMV tag-length-value format
  static String _buildTag(String tag, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return tag + length + value;
  }
  
  /// Calculate CRC16-CCITT checksum
  static String _calculateCRC16(String data) {
    const polynomial = 0x1021;
    int crc = 0xFFFF;
    
    final bytes = data.codeUnits;
    
    for (final byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ polynomial) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
  
  /// Get bank name from bank code
  static String getBankName(String bankCode) {
    const banks = {
      '970422': 'MB Bank',
      '970415': 'Vietinbank',
      '970436': 'Vietcombank',
      '970418': 'BIDV',
      '970405': 'Agribank',
      '970407': 'Techcombank',
      '970423': 'TPBank',
      '970403': 'Sacombank',
      '970416': 'ACB',
      '970432': 'VPBank',
    };
    return banks[bankCode] ?? 'Ngân hàng';
  }
}