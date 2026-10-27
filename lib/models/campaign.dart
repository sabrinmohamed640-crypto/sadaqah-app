import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final double targetAmount;
  final double currentAmount;
  final DateTime createdDate;
  final DateTime? endDate;
  final String? status; // 'active', 'completed', 'paused'

  Campaign({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.targetAmount,
    required this.currentAmount,
    required this.createdDate,
    this.endDate,
    this.status = 'active',
  });

  /// Calculate progress percentage (0-100)
  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return ((currentAmount / targetAmount) * 100).clamp(0, 100);
  }

  /// Calculate remaining amount needed
  double get remainingAmount {
    final remaining = targetAmount - currentAmount;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if campaign is completed
  bool get isCompleted => currentAmount >= targetAmount;

  /// Check if campaign has ended
  bool get hasEnded => endDate != null && DateTime.now().isAfter(endDate!);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'createdDate': Timestamp.fromDate(createdDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status,
    };
  }

  factory Campaign.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return Campaign(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Campaign',
      description: map['description'] ?? '',
      imagePath: map['imagePath'] ?? 'assets/default_campaign.png',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      createdDate: parseDateTime(map['createdDate']),
      endDate: map['endDate'] != null ? parseDateTime(map['endDate']) : null,
      status: map['status'],
    );
  }

  /// Factory constructor to create Campaign from Firestore DocumentSnapshot
  factory Campaign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return Campaign(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Campaign',
      description: data['description'] ?? '',
      imagePath: data['imagePath'] ?? 'assets/default_campaign.png',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      createdDate: parseDateTime(data['createdDate']),
      endDate: data['endDate'] != null ? parseDateTime(data['endDate']) : null,
      status: data['status'],
    );
  }

  /// Create a copy with modified fields
  Campaign copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    double? targetAmount,
    double? currentAmount,
    DateTime? createdDate,
    DateTime? endDate,
    String? status,
  }) {
    return Campaign(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      createdDate: createdDate ?? this.createdDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }
}
