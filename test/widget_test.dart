import 'package:flutter_test/flutter_test.dart';
import 'package:sadaqah_app/models/donation.dart';
import 'package:sadaqah_app/services/storage_service.dart';

void main() {
  group('Donation Model & Category Tests', () {
    test('Category display names are properly mapped', () {
      expect(DonationCategory.zakat.displayName, 'Zakat');
      expect(DonationCategory.sadaqahJariyah.displayName, 'Sadaqah Jariyah');
      expect(DonationCategory.emergencyAid.displayName, 'Emergency Relief');
      expect(DonationCategory.foodRelief.displayName, 'Food & Water Aid');
    });

    test('Donation JSON serialization and deserialization', () {
      final donation = Donation(
        id: 'test-123',
        amount: 75.50,
        category: DonationCategory.foodRelief,
        recipient: 'Community Pantry',
        date: DateTime(2026, 8, 21),
        recurringType: RecurringType.monthly,
        notes: 'Monthly food basket',
      );

      final json = donation.toJson();
      expect(json['id'], 'test-123');
      expect(json['amount'], 75.50);
      expect(json['category'], 'foodRelief');

      final reconstructed = Donation.fromJson(json);
      expect(reconstructed.id, 'test-123');
      expect(reconstructed.amount, 75.50);
      expect(reconstructed.category, DonationCategory.foodRelief);
      expect(reconstructed.recipient, 'Community Pantry');
      expect(reconstructed.recurringType, RecurringType.monthly);
      expect(reconstructed.notes, 'Monthly food basket');
    });
  });

  group('StorageService Business Logic Tests', () {
    final storage = DonationStorageService();

    test('Initialize with demo data loads default contributions', () {
      storage.initializeWithDemoData();
      expect(storage.allDonations.isNotEmpty, true);
      expect(storage.allDonations.length, greaterThanOrEqualTo(5));
    });

    test('Adding a new donation updates all-time and monthly totals', () {
      final initialTotal = storage.getTotalGivenAllTime();
      final testDonation = Donation(
        id: 'test-add-${DateTime.now().millisecondsSinceEpoch}',
        amount: 150.00,
        category: DonationCategory.emergencyAid,
        recipient: 'Medical Aid Fund',
        date: DateTime.now(),
        recurringType: RecurringType.oneTime,
        notes: 'QA Test',
      );

      storage.addDonation(testDonation);
      expect(storage.getTotalGivenAllTime(), equals(initialTotal + 150.00));

      final breakdown = storage.getCategoryBreakdown();
      expect(breakdown.containsKey(DonationCategory.emergencyAid), true);
      expect(breakdown[DonationCategory.emergencyAid]!, greaterThanOrEqualTo(150.00));
    });

    test('Deleting a donation removes it from records', () {
      final toDelete = Donation(
        id: 'to-delete-999',
        amount: 25.00,
        category: DonationCategory.generalCharity,
        recipient: 'Delete Me',
        date: DateTime.now(),
      );

      storage.addDonation(toDelete);
      expect(storage.allDonations.any((d) => d.id == 'to-delete-999'), true);

      storage.deleteDonation('to-delete-999');
      expect(storage.allDonations.any((d) => d.id == 'to-delete-999'), false);
    });
  });
}
