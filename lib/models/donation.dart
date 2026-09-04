enum DonationCategory {
  zakat,
  sadaqahJariyah,
  emergencyAid,
  education,
  foodRelief,
  masjidSupport,
  generalCharity,
}

extension DonationCategoryExtension on DonationCategory {
  String get displayName {
    switch (this) {
      case DonationCategory.zakat:
        return 'Zakat';
      case DonationCategory.sadaqahJariyah:
        return 'Sadaqah Jariyah';
      case DonationCategory.emergencyAid:
        return 'Emergency Relief';
      case DonationCategory.education:
        return 'Education & Students';
      case DonationCategory.foodRelief:
        return 'Food & Water Aid';
      case DonationCategory.masjidSupport:
        return 'Masjid & Community';
      case DonationCategory.generalCharity:
        return 'General Sadaqah';
    }
  }

  String get iconName {
    switch (this) {
      case DonationCategory.zakat:
        return 'handshake';
      case DonationCategory.sadaqahJariyah:
        return 'tree';
      case DonationCategory.emergencyAid:
        return 'medical_services';
      case DonationCategory.education:
        return 'school';
      case DonationCategory.foodRelief:
        return 'restaurant';
      case DonationCategory.masjidSupport:
        return 'account_balance';
      case DonationCategory.generalCharity:
        return 'favorite';
    }
  }
}

enum RecurringType {
  oneTime,
  monthly,
  annual,
}

class Donation {
  final String id;
  final double amount;
  final DonationCategory category;
  final String recipient;
  final DateTime date;
  final RecurringType recurringType;
  final String? notes;
  final bool isAnonymous;

  const Donation({
    required this.id,
    required this.amount,
    required this.category,
    required this.recipient,
    required this.date,
    this.recurringType = RecurringType.oneTime,
    this.notes,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category.name,
        'recipient': recipient,
        'date': date.toIso8601String(),
        'recurringType': recurringType.name,
        'notes': notes,
        'isAnonymous': isAnonymous,
      };

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: DonationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => DonationCategory.generalCharity,
      ),
      recipient: json['recipient'] as String,
      date: DateTime.parse(json['date'] as String),
      recurringType: RecurringType.values.firstWhere(
        (r) => r.name == json['recurringType'],
        orElse: () => RecurringType.oneTime,
      ),
      notes: json['notes'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
    );
  }
}
