import '../models/donation.dart';

class DonationStorageService {
  static final DonationStorageService _instance = DonationStorageService._internal();
  factory DonationStorageService() => _instance;
  DonationStorageService._internal();

  final List<Donation> _donations = [];

  List<Donation> get allDonations => List.unmodifiable(_donations);

  double get monthlyGivingGoal => 500.0;

  void initializeWithDemoData() {
    if (_donations.isNotEmpty) return;

    final now = DateTime.now();
    _donations.addAll([
      Donation(
        id: 'don-01',
        amount: 150.00,
        category: DonationCategory.foodRelief,
        recipient: 'Local Food Pantry Support',
        date: DateTime(now.year, now.month, 4),
        recurringType: RecurringType.monthly,
        notes: 'Monthly food basket contribution for local families in need.',
      ),
      Donation(
        id: 'don-02',
        amount: 200.00,
        category: DonationCategory.emergencyAid,
        recipient: 'International Disaster Relief Fund',
        date: DateTime(now.year, now.month, 10),
        recurringType: RecurringType.oneTime,
        notes: 'Emergency medical supplies and clean drinking water.',
      ),
      Donation(
        id: 'don-03',
        amount: 50.00,
        category: DonationCategory.masjidSupport,
        recipient: 'Community Center Youth Program',
        date: DateTime(now.year, now.month, 14),
        recurringType: RecurringType.oneTime,
        notes: 'Educational books and classroom supplies.',
      ),
      Donation(
        id: 'don-04',
        amount: 100.00,
        category: DonationCategory.sadaqahJariyah,
        recipient: 'Clean Water Well Initiative',
        date: DateTime(now.year, now.month, 18),
        recurringType: RecurringType.oneTime,
        notes: 'Dedicated water well construction fund.',
      ),
      Donation(
        id: 'don-05',
        amount: 75.00,
        category: DonationCategory.education,
        recipient: 'Student Academic Scholarship Fund',
        date: DateTime(now.year, now.month - 1, 22),
        recurringType: RecurringType.monthly,
        notes: 'University textbook sponsorship.',
      ),
    ]);
  }

  void addDonation(Donation donation) {
    _donations.insert(0, donation);
  }

  void deleteDonation(String id) {
    _donations.removeWhere((d) => d.id == id);
  }

  double getTotalGivenThisMonth() {
    final now = DateTime.now();
    return _donations
        .where((d) => d.date.year == now.year && d.date.month == now.month)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  double getTotalGivenAllTime() {
    return _donations.fold(0.0, (sum, d) => sum + d.amount);
  }

  Map<DonationCategory, double> getCategoryBreakdown() {
    final map = <DonationCategory, double>{};
    for (var d in _donations) {
      map[d.category] = (map[d.category] ?? 0.0) + d.amount;
    }
    return map;
  }
}
