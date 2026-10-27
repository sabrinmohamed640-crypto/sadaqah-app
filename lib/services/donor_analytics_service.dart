import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_metrics.dart';
import 'auth_service.dart';

/// Service for tracking and analyzing donor metrics and behavior patterns.
class DonorAnalyticsService {
  DonorAnalyticsService({AuthService? authService})
      : _auth = authService ?? AuthService();

  final AuthService _auth;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _colDonations = 'donations';
  static const String _colUsers = 'users';

  /// Get analytics for a specific donor (must be admin or the donor themselves)
  Future<DonorAnalytics?> getDonorAnalytics(String donorId) async {
    try {
      final donorDocs = await _firestore
          .collection(_colDonations)
          .where('donorId', isEqualTo: donorId)
          .get();

      if (donorDocs.docs.isEmpty) {
        debugPrint('⚠️ [DonorAnalytics] No donations found for donor: $donorId');
        return null;
      }

      // Get donor info
      final userDoc = await _firestore.collection(_colUsers).doc(donorId).get();
      final donorName = userDoc.data()?['name'] as String? ?? 'Unknown Donor';

      double totalDonated = 0.0;
      double zakatDonated = 0.0;
      double sadaqahDonated = 0.0;
      final List<DateTime> donationDates = [];
      DateTime? lastDonationDate;

      for (final doc in donorDocs.docs) {
        final data = doc.data();
        final amount = _parseDouble(data['amount']);
        final type = (data['type'] as String?)?.toLowerCase() ?? '';
        final timestamp = data['timestamp'];

        totalDonated += amount;
        if (type == 'zakat') {
          zakatDonated += amount;
        } else if (type == 'sadaqah') {
          sadaqahDonated += amount;
        }

        DateTime donationDate;
        if (timestamp is Timestamp) {
          donationDate = timestamp.toDate();
        } else if (timestamp is DateTime) {
          donationDate = timestamp;
        } else {
          continue;
        }

        donationDates.add(donationDate);
        if (lastDonationDate == null ||
            donationDate.isAfter(lastDonationDate)) {
          lastDonationDate = donationDate;
        }
      }

      donationDates.sort((a, b) => b.compareTo(a));

      // Calculate monthly consistency
      final monthlyConsistency =
          _calculateMonthlyConsistency(donationDates);

      debugPrint(
          '📊 [DonorAnalytics] Donor $donorId: Total \$${totalDonated.toStringAsFixed(2)}, Count: ${donorDocs.docs.length}');

      return DonorAnalytics(
        donorId: donorId,
        donorName: donorName,
        totalDonated: totalDonated,
        donationCount: donorDocs.docs.length,
        averageDonation:
            donorDocs.docs.isNotEmpty ? totalDonated / donorDocs.docs.length : 0.0,
        lastDonationDate: lastDonationDate ?? DateTime.now(),
        donationDates: donationDates,
        zakatDonated: zakatDonated,
        sadaqahDonated: sadaqahDonated,
        monthlyConsistency: monthlyConsistency,
      );
    } catch (e) {
      debugPrint('❌ [DonorAnalytics] Error: $e');
      return null;
    }
  }

  /// Get top donors by total amount donated
  Future<List<DonorAnalytics>> getTopDonors({int limit = 10}) async {
    try {
      final isAdmin = await _auth.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('⚠️ [DonorAnalytics] Non-admin user cannot access top donors');
        return [];
      }

      final donationsDocs =
          await _firestore.collection(_colDonations).get();

      // Group by donor
      final Map<String, List<QueryDocumentSnapshot>> donorDonations = {};
      for (final doc in donationsDocs.docs) {
        final donorId = doc.data()['donorId'] as String?;
        if (donorId == null) continue;

        donorDonations.putIfAbsent(donorId, () => []);
        donorDonations[donorId]!.add(doc);
      }

      // Calculate analytics for each donor
      final List<DonorAnalytics> analytics = [];
      for (final donorId in donorDonations.keys) {
        final analytics_ = await getDonorAnalytics(donorId);
        if (analytics_ != null) {
          analytics.add(analytics_);
        }
      }

      // Sort by total donated (descending) and limit
      analytics.sort((a, b) => b.totalDonated.compareTo(a.totalDonated));
      return analytics.take(limit).toList();
    } catch (e) {
      debugPrint('❌ [DonorAnalytics] Error getting top donors: $e');
      return [];
    }
  }

  /// Get donors by engagement level
  Future<Map<String, List<DonorAnalytics>>> getDonorsByEngagement() async {
    try {
      final isAdmin = await _auth.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint(
            '⚠️ [DonorAnalytics] Non-admin user cannot access donor segments');
        return {};
      }

      final topDonors = await getTopDonors(limit: 1000);

      final Map<String, List<DonorAnalytics>> byEngagement = {
        'Highly Engaged': [],
        'Engaged': [],
        'Active': [],
        'Occasional': [],
      };

      for (final donor in topDonors) {
        byEngagement[donor.engagementLevel]!.add(donor);
      }

      debugPrint('📊 [DonorAnalytics] Segmented ${topDonors.length} donors');
      return byEngagement;
    } catch (e) {
      debugPrint('❌ [DonorAnalytics] Error segmenting donors: $e');
      return {};
    }
  }

  /// Get dormant donors (no donations in last N days)
  Future<List<DonorAnalytics>> getDormantDonors({int inactiveDays = 90}) async {
    try {
      final isAdmin = await _auth.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('⚠️ [DonorAnalytics] Non-admin cannot access dormant donors');
        return [];
      }

      final topDonors = await getTopDonors(limit: 1000);
      final cutoffDate = DateTime.now().subtract(Duration(days: inactiveDays));

      final dormant = topDonors
          .where((donor) => donor.lastDonationDate.isBefore(cutoffDate))
          .toList();

      debugPrint(
          '⏱️  [DonorAnalytics] Found ${dormant.length} dormant donors (inactive > $inactiveDays days)');
      return dormant;
    } catch (e) {
      debugPrint('❌ [DonorAnalytics] Error getting dormant donors: $e');
      return [];
    }
  }

  /// Get donation frequency for a donor (donations per month on average)
  double calculateDonationFrequency(DonorAnalytics donor) {
    if (donor.donationDates.isEmpty) return 0.0;

    final oldestDate = donor.donationDates.last;
    final monthsDiff =
        DateTime.now().difference(oldestDate).inDays / 30.0;

    if (monthsDiff == 0) return 0.0;
    return donor.donationCount / monthsDiff;
  }

  /// Compare two donors for benchmarking
  Map<String, dynamic> compareDonors(DonorAnalytics donor1, DonorAnalytics donor2) {
    return {
      'donor1': donor1.donorName,
      'donor2': donor2.donorName,
      'totalDonated_diff': donor1.totalDonated - donor2.totalDonated,
      'frequency_diff': calculateDonationFrequency(donor1) -
          calculateDonationFrequency(donor2),
      'consistency_diff': donor1.monthlyConsistency - donor2.monthlyConsistency,
      'higher_donor':
          donor1.totalDonated > donor2.totalDonated ? donor1.donorName : donor2.donorName,
    };
  }

  /// Helper: Parse amount safely
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper: Calculate monthly consistency (% of months where user donated)
  int _calculateMonthlyConsistency(List<DateTime> donationDates) {
    if (donationDates.isEmpty) return 0;

    final oldestDate = donationDates.last;
    final newestDate = donationDates.first;
    final totalMonths =
        ((newestDate.year - oldestDate.year) * 12 + (newestDate.month - oldestDate.month))
            .toInt() + 1;

    if (totalMonths == 0) return 0;

    final Set<String> donationMonths = {};
    for (final date in donationDates) {
      donationMonths.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }

    return ((donationMonths.length / totalMonths) * 100).toInt();
  }
}
