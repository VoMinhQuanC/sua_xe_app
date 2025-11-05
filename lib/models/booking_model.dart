// lib/models/booking_model.dart

/// Booking Status
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Chờ xác nhận';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.inProgress:
        return 'Đang thực hiện';
      case BookingStatus.completed:
        return 'Hoàn thành';
      case BookingStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
      case 'inprogress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }
}

/// Booking Model
class BookingModel {
  final int? bookingId;
  final int userId;
  final int serviceId;
  final int? mechanicId;
  final DateTime bookingDate;
  final String? notes;
  final BookingStatus status;
  final double? totalPrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relations
  final String? userName;
  final String? serviceName;
  final String? mechanicName;

  BookingModel({
    this.bookingId,
    required this.userId,
    required this.serviceId,
    this.mechanicId,
    required this.bookingDate,
    this.notes,
    this.status = BookingStatus.pending,
    this.totalPrice,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.serviceName,
    this.mechanicName,
  });

  /// From JSON
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['BookingId'],
      userId: json['UserId'],
      serviceId: json['ServiceId'],
      mechanicId: json['MechanicId'],
      bookingDate: DateTime.parse(json['BookingDate']),
      notes: json['Notes'],
      status: BookingStatus.fromString(json['Status'] ?? 'pending'),
      totalPrice: json['TotalPrice']?.toDouble(),
      createdAt: json['CreatedAt'] != null 
          ? DateTime.parse(json['CreatedAt']) 
          : null,
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.parse(json['UpdatedAt']) 
          : null,
      userName: json['UserName'],
      serviceName: json['ServiceName'],
      mechanicName: json['MechanicName'],
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'BookingId': bookingId,
      'UserId': userId,
      'ServiceId': serviceId,
      'MechanicId': mechanicId,
      'BookingDate': bookingDate.toIso8601String(),
      'Notes': notes,
      'Status': status.name,
      'TotalPrice': totalPrice,
      'CreatedAt': createdAt?.toIso8601String(),
      'UpdatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Format giá
  String get formattedPrice {
    if (totalPrice == null) return '0 ₫';
    return '${totalPrice!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} ₫';
  }

  /// Format ngày giờ
  String get formattedDate {
    return '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}';
  }

  String get formattedTime {
    return '${bookingDate.hour.toString().padLeft(2, '0')}:${bookingDate.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '$formattedDate - $formattedTime';
  }

  /// Copy with
  BookingModel copyWith({
    int? bookingId,
    int? userId,
    int? serviceId,
    int? mechanicId,
    DateTime? bookingDate,
    String? notes,
    BookingStatus? status,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? serviceName,
    String? mechanicName,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      mechanicId: mechanicId ?? this.mechanicId,
      bookingDate: bookingDate ?? this.bookingDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      serviceName: serviceName ?? this.serviceName,
      mechanicName: mechanicName ?? this.mechanicName,
    );
  }

  @override
  String toString() {
    return 'BookingModel(id: $bookingId, service: $serviceName, date: $formattedDateTime, status: ${status.displayName})';
  }
}