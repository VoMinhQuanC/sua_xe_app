// lib/models/appointment_model.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class AppointmentModel {
  final int appointmentId;
  final int userId;
  final int? vehicleId;
  final int? mechanicId;
  final DateTime appointmentDate;
  final DateTime? estimatedEndTime;
  final int? serviceDuration;
  final String status; // Pending, Confirmed, Completed, Canceled
  final String? paymentStatus;
  final double? totalAmount;
  final String? paymentMethod;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Customer info
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  
  // Vehicle info
  final String? licensePlate;
  final String? brand;
  final String? model;
  final int? year;
  
  // Services
  final List<ServiceItem>? services;

  AppointmentModel({
    required this.appointmentId,
    required this.userId,
    this.vehicleId,
    this.mechanicId,
    required this.appointmentDate,
    this.estimatedEndTime,
    this.serviceDuration,
    required this.status,
    this.paymentStatus,
    this.totalAmount,
    this.paymentMethod,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.licensePlate,
    this.brand,
    this.model,
    this.year,
    this.services,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['AppointmentID'] ?? json['appointmentId'],
      userId: json['UserID'] ?? json['userId'],
      vehicleId: json['VehicleID'] ?? json['vehicleId'],
      mechanicId: json['MechanicID'] ?? json['mechanicId'],
      appointmentDate: DateTime.parse(json['AppointmentDate'] ?? json['appointmentDate']),
      estimatedEndTime: json['EstimatedEndTime'] != null 
          ? DateTime.parse(json['EstimatedEndTime'])
          : null,
      serviceDuration: json['ServiceDuration'] ?? json['serviceDuration'],
      status: json['Status'] ?? json['status'] ?? 'Pending',
      paymentStatus: json['PaymentStatus'] ?? json['paymentStatus'],
      totalAmount: json['TotalAmount'] != null 
          ? double.parse(json['TotalAmount'].toString())
          : null,
      paymentMethod: json['PaymentMethod'] ?? json['paymentMethod'],
      notes: json['Notes'] ?? json['notes'],
      createdAt: json['CreatedAt'] != null 
          ? DateTime.parse(json['CreatedAt'])
          : null,
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.parse(json['UpdatedAt'])
          : null,
      customerName: json['CustomerName'] ?? json['customerName'],
      customerPhone: json['CustomerPhone'] ?? json['customerPhone'],
      customerEmail: json['CustomerEmail'] ?? json['customerEmail'],
      licensePlate: json['LicensePlate'] ?? json['licensePlate'],
      brand: json['Brand'] ?? json['brand'],
      model: json['Model'] ?? json['model'],
      year: json['Year'] ?? json['year'],
      services: _parseServices(json['Services']),
    );
  }

  /// Parse Services từ String JSON hoặc List
  static List<ServiceItem>? _parseServices(dynamic servicesData) {
    if (servicesData == null) return null;
    
    try {
      // Nếu là String JSON → parse nó
      if (servicesData is String) {
        if (servicesData.isEmpty) return null;
        
        final List parsed = json.decode(servicesData);
        return parsed.map((s) => ServiceItem.fromJson(s)).toList();
      }
      
      // Nếu đã là List → dùng trực tiếp
      if (servicesData is List) {
        return servicesData.map((s) => ServiceItem.fromJson(s)).toList();
      }
      
      print('⚠️ Unknown Services data type: ${servicesData.runtimeType}');
      return null;
    } catch (e) {
      print('❌ Error parsing services: $e');
      print('   Services data: $servicesData');
      return null;
    }
  }

  String get statusInVietnamese {
    switch (status) {
      case 'Pending':
        return 'Chờ xác nhận';
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'Completed':
        return 'Hoàn thành';
      case 'Canceled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get vehicleInfo {
    if (licensePlate == null) return 'Chưa có thông tin xe';
    String info = licensePlate!;
    if (brand != null && model != null) {
      info += ' ($brand $model)';
    }
    return info;
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(appointmentDate);
  }

  String get formattedTime {
    return DateFormat('HH:mm', 'vi_VN').format(appointmentDate);
  }
}

class ServiceItem {
  final int serviceId;
  final String serviceName;
  final String? description;
  final double price;
  final int? estimatedTime;
  final int quantity;

  ServiceItem({
    required this.serviceId,
    required this.serviceName,
    this.description,
    required this.price,
    this.estimatedTime,
    required this.quantity,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      serviceId: json['ServiceID'] ?? json['serviceId'],
      serviceName: json['ServiceName'] ?? json['serviceName'],
      description: json['Description'] ?? json['description'],
      price: double.parse(json['Price'].toString()),
      estimatedTime: json['EstimatedTime'] ?? json['estimatedTime'],
      quantity: json['Quantity'] ?? json['quantity'] ?? 1,
    );
  }

  String get formattedPrice {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(price);
  }
}