class Muzakki {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime registeredAt;
  final double totalZakatPaid;
  final double totalSadaqahPaid;

  Muzakki({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.registeredAt,
    this.totalZakatPaid = 0.0,
    this.totalSadaqahPaid = 0.0,
  });

  // Convert to Map for Firestore / Database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'registeredAt': registeredAt.toIso8601String(),
      'totalZakatPaid': totalZakatPaid,
      'totalSadaqahPaid': totalSadaqahPaid,
    };
  }

  // Create from Map (Firestore DocumentSnapshot)
  factory Muzakki.fromMap(Map<String, dynamic> map) {
    return Muzakki(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      registeredAt: map['registeredAt'] != null 
          ? DateTime.parse(map['registeredAt']) 
          : DateTime.now(),
      totalZakatPaid: (map['totalZakatPaid'] ?? 0.0).toDouble(),
      totalSadaqahPaid: (map['totalSadaqahPaid'] ?? 0.0).toDouble(),
    );
  }

  Muzakki copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? registeredAt,
    double? totalZakatPaid,
    double? totalSadaqahPaid,
  }) {
    return Muzakki(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      registeredAt: registeredAt ?? this.registeredAt,
      totalZakatPaid: totalZakatPaid ?? this.totalZakatPaid,
      totalSadaqahPaid: totalSadaqahPaid ?? this.totalSadaqahPaid,
    );
  }
}
