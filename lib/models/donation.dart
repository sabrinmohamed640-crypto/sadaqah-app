import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class Donation {
  final String id;
  final String donorId; // Reference to Muzakki ID
  final String donorName;
  final String? recipientId; // Reference to Mustahik ID (null for General Zakat/Sadaqah Fund)
  final double amount;
  final String type; // 'Zakat', 'Sadaqah'
  final String paymentMethod; // 'Bank Transfer', 'Mobile Money', 'Card', etc.
  final String status; // 'Pending', 'Completed', 'Failed'
  final DateTime timestamp;
  final String? notes;

  Donation({
    required this.id,
    required this.donorId,
    required this.donorName,
    this.recipientId,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    this.status = 'Pending',
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'recipientId': recipientId,
      'amount': amount,
      'type': type,
      'paymentMethod': paymentMethod,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  factory Donation.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return Donation(
      id: map['id'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      recipientId: map['recipientId'],
      amount: AppConstants.parseDouble(map['amount']),
      type: map['type'] ?? 'Sadaqah',
      paymentMethod: map['paymentMethod'] ?? 'Bank Transfer',
      status: map['status'] ?? 'Pending',
      timestamp: parseDateTime(map['timestamp']),
      notes: map['notes'],
    );
  }

  Donation copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? recipientId,
    double? amount,
    String? type,
    String? paymentMethod,
    String? status,
    DateTime? timestamp,
    String? notes,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      recipientId: recipientId ?? this.recipientId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
}
