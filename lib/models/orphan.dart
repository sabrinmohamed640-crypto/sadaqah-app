import 'package:cloud_firestore/cloud_firestore.dart';

class Orphan {
  final String id;
  final String name;
  final int age;
  final String bio;
  final String imageUrl;
  final double sponsorshipAmount;
  final String status; // 'available', 'sponsored'
  final DateTime createdAt;
  final String? sponsorId; // Reference to sponsor user ID
  final String? sponsorName; // Name of current sponsor

  Orphan({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.imageUrl,
    required this.sponsorshipAmount,
    this.status = 'available',
    required this.createdAt,
    this.sponsorId,
    this.sponsorName,
  });

  /// Convert Orphan to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'imageUrl': imageUrl,
      'sponsorshipAmount': sponsorshipAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'sponsorId': sponsorId,
      'sponsorName': sponsorName,
    };
  }

  /// Create Orphan from Firestore document
  factory Orphan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document is empty');
    }

    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return Orphan(
      id: doc.id,
      name: data['name'] ?? '',
      age: parseInt(data['age']),
      bio: data['bio'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      sponsorshipAmount: parseDouble(data['sponsorshipAmount']),
      status: data['status'] ?? 'available',
      createdAt: parseDateTime(data['createdAt']),
      sponsorId: data['sponsorId'],
      sponsorName: data['sponsorName'],
    );
  }

  /// Create Orphan from Map
  factory Orphan.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return Orphan(
      id: id,
      name: map['name'] ?? '',
      age: parseInt(map['age']),
      bio: map['bio'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      sponsorshipAmount: parseDouble(map['sponsorshipAmount']),
      status: map['status'] ?? 'available',
      createdAt: parseDateTime(map['createdAt']),
      sponsorId: map['sponsorId'],
      sponsorName: map['sponsorName'],
    );
  }

  /// Copy with method for updates
  Orphan copyWith({
    String? id,
    String? name,
    int? age,
    String? bio,
    String? imageUrl,
    double? sponsorshipAmount,
    String? status,
    DateTime? createdAt,
    String? sponsorId,
    String? sponsorName,
  }) {
    return Orphan(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      sponsorshipAmount: sponsorshipAmount ?? this.sponsorshipAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      sponsorId: sponsorId ?? this.sponsorId,
      sponsorName: sponsorName ?? this.sponsorName,
    );
  }
}
