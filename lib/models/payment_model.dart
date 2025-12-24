// lib/models/payment_model.dart

class PaymentQRModel {
  final String qrUrl;        // Giữ lại cho compatibility
  final String qrString;     // ✅ QR STRING từ VietQR API
  final String bookingCode;
  final double totalAmount;
  final BankInfo bankInfo;
  final DateTime expiryTime;

  PaymentQRModel({
    required this.qrUrl,
    required this.qrString,  // ✅ THÊM
    required this.bookingCode,
    required this.totalAmount,
    required this.bankInfo,
    required this.expiryTime,
  });

  factory PaymentQRModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return PaymentQRModel(
      qrUrl: data['qrUrl'] ?? '',
      qrString: data['qrString'] ?? data['qrUrl'] ?? '',  // ✅ Ưu tiên qrString
      bookingCode: data['bookingCode'] ?? '',
      totalAmount: double.parse((data['totalAmount'] ?? '0').toString()),
      bankInfo: BankInfo.fromJson(data['bankInfo'] ?? {}),
      expiryTime: data['expiryTime'] != null 
          ? DateTime.parse(data['expiryTime'])
          : DateTime.now().add(Duration(minutes: 15)),
    );
  }
}

class BankInfo {
  final String accountNumber;
  final String accountName;
  final String bankName;
  final String bankCode;
  final String transferContent;

  BankInfo({
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
    required this.bankCode,
    required this.transferContent,
  });

  factory BankInfo.fromJson(Map<String, dynamic> json) {
    return BankInfo(
      accountNumber: json['accountNumber'] ?? json['accountNo'] ?? '',
      accountName: json['accountName'] ?? '',
      bankName: json['bankName'] ?? '',
      bankCode: json['bankCode'] ?? json['bankId'] ?? '970422',
      transferContent: json['transferContent'] ?? '',
    );
  }
}

class PaymentProofUploadResponse {
  final bool success;
  final String message;
  final int? proofId;
  final String status;

  PaymentProofUploadResponse({
    required this.success,
    required this.message,
    this.proofId,
    this.status = 'WaitingReview',
  });

  factory PaymentProofUploadResponse.fromJson(Map<String, dynamic> json) {
    return PaymentProofUploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      proofId: json['proofId'] ?? json['paymentProofId'],
      status: json['status'] ?? 'WaitingReview',
    );
  }
}