import 'package:cloud_firestore/cloud_firestore.dart';

class Mustahik {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String status; // 'Pending', 'Verified', 'Rejected'
  final String category; // 'Fakir', 'Miskin', 'Amil', 'Muallaf', 'Riqab', 'Gharimin', 'Fisabilillah', 'Ibnu Sabil'
  final String? description; // Family size, details of hardship
  final double monthlyIncome;
  final DateTime registeredAt;
  final String aidType; // 'emergency', 'sustainable' - Type of aid needed
  final String supportStatus; // 'temporary', 'approved' - Lifecycle status

  Mustahik({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.status = 'Pending',
    required this.category,
    this.description,
    required this.monthlyIncome,
    required this.registeredAt,
    this.aidType = 'sustainable',
    this.supportStatus = 'temporary',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'status': status,
      'category': category,
      'description': description,
      'monthlyIncome': monthlyIncome,
      'registeredAt': registeredAt.toIso8601String(),
      'aidType': aidType,
      'supportStatus': supportStatus,
    };
  }

  factory Mustahik.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return Mustahik(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      status: map['status'] ?? 'Pending',
      category: map['category'] ?? 'Miskin',
      description: map['description'],
      monthlyIncome: parseDouble(map['monthlyIncome']),
      registeredAt: parseDateTime(map['registeredAt']),
      aidType: map['aidType'] ?? 'sustainable',
      supportStatus: map['supportStatus'] ?? 'temporary',
    );
  }

  Mustahik copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? status,
    String? category,
    String? description,
    double? monthlyIncome,
    DateTime? registeredAt,
    String? aidType,
    String? supportStatus,
  }) {
    return Mustahik(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      category: category ?? this.category,
      description: description ?? this.description,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      registeredAt: registeredAt ?? this.registeredAt,
      aidType: aidType ?? this.aidType,
      supportStatus: supportStatus ?? this.supportStatus,
    );
  }
}
