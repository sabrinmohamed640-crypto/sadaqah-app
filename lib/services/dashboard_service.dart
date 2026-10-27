import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../utils/constants.dart';
import '../models/dashboard_metrics.dart';
import 'auth_service.dart';

/// Admin-only real-time metrics for the dashboard.
///
/// Firestore security rules enforce the same constraints server-side:
///   • [totalDonationsStream]      → `donations` readable only by admin (all docs)
///   • [activeBeneficiariesCountStream] → `mustahik` (admin UI; rules allow signed-in read)
///   • [pendingApprovalsCountStream]    → `aid_requests` admin-only read
class DashboardService {
  DashboardService({AuthService? authService})
      : _auth = authService ?? AuthService();

  final AuthService _auth;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _colDonations = 'donations';
  static const String _colMustahik = 'mustahik';
  static const String _colAidRequests = 'aid_requests';

  /// Sum of `amount` across every document in `donations`.
  Stream<double> get totalDonationsStream => _adminGuarded(
        'totalDonations',
        () => _firestore.collection(_colDonations).snapshots().map(
              (snapshot) => _sumAmounts(snapshot.docs),
            ),
      );

  /// Count of verified (approved) beneficiaries in `mustahik`.
  Stream<int> get activeBeneficiariesCountStream => _adminGuarded(
        'activeBeneficiariesCount',
        () => _firestore
            .collection(_colMustahik)
            .where('status', isEqualTo: 'Verified')
            .snapshots()
            .map((snapshot) => snapshot.docs.length),
      );

  /// Count of aid requests awaiting admin review (`status == 'Pending'`).
  Stream<int> get pendingApprovalsCountStream => _adminGuarded(
        'pendingApprovalsCount',
        () => _firestore
            .collection(_colAidRequests)
            .where('status', isEqualTo: 'Pending')
            .snapshots()
            .map((snapshot) => snapshot.docs.length),
      );

  /// Fund distribution breakdown by donation type (Zakat vs Sadaqah).
  Stream<FundDistribution> get fundDistributionStream => _adminGuarded(
        'fundDistribution',
        () => _firestore.collection(_colDonations).snapshots().map(
              (snapshot) => _calculateFundDistribution(snapshot.docs),
            ),
      );

  /// Donation trends over time (last 30 days, grouped by date).
  Stream<List<DonationTrendPoint>> get donationTrendsStream => _adminGuarded(
        'donationTrends',
        () => _firestore.collection(_colDonations).snapshots().map(
              (snapshot) => _calculateDonationTrends(snapshot.docs),
            ),
      );

  /// Beneficiaries grouped by category (e.g., Fakir, Miskin, etc.).
  Stream<Map<String, int>> get beneficiariesByCategoryStream => _adminGuarded(
        'beneficiariesByCategory',
        () => _firestore.collection(_colMustahik).snapshots().map(
              (snapshot) => _calculateBeneficiariesByCategory(snapshot.docs),
            ),
      );

  /// Average donation amount across all donations.
  Stream<double> get averageDonationStream => _adminGuarded(
        'averageDonation',
        () => _firestore.collection(_colDonations).snapshots().map(
              (snapshot) {
                if (snapshot.docs.isEmpty) return 0.0;
                double total = _sumAmounts(snapshot.docs);
                return total / snapshot.docs.length;
              },
            ),
      );

  /// Total unique donors count.
  Stream<int> get totalDonorsStream => _adminGuarded(
        'totalDonors',
        () => _firestore.collection(_colDonations).snapshots().map(
              (snapshot) {
                final Set<String> donorIds = {};
                for (final doc in snapshot.docs) {
                  final donorId = doc.data()['donorId'];
                  if (donorId != null) donorIds.add(donorId);
                }
                return donorIds.length;
              },
            ),
      );

  /// Donation completion rate (% of successful vs total donations).
  Stream<double> get donationCompletionRateStream => _adminGuarded(
        'completionRate',
        () => _firestore.collection(_colDonations).snapshots().map(
              (snapshot) {
                if (snapshot.docs.isEmpty) return 0.0;
                int completed = 0;
                for (final doc in snapshot.docs) {
                  if (doc.data()['status'] == 'Completed') completed++;
                }
                return (completed / snapshot.docs.length) * 100;
              },
            ),
      );

  /// Combined dashboard metrics (all metrics in one stream).
  Stream<DashboardMetrics> get dashboardMetricsStream => _adminGuarded(
        'dashboardMetrics',
        () => Rx.combineLatest8(
          totalDonationsStream,
          activeBeneficiariesCountStream,
          pendingApprovalsCountStream,
          averageDonationStream,
          totalDonorsStream,
          fundDistributionStream,
          donationTrendsStream,
          beneficiariesByCategoryStream,
          (totalDonations, activeBeneficiaries, pendingApprovals,
              averageDonation, totalDonors, fundDistribution, trends,
              categoriesMap) {
            return DashboardMetrics(
              totalDonations: totalDonations,
              activeBeneficiaries: activeBeneficiaries,
              pendingApprovals: pendingApprovals,
              averageDonation: averageDonation,
              totalDonors: totalDonors,
              fundDistributionByCategory:
                  fundDistribution.byBeneficiaryCategory,
              donationTrends: trends,
              beneficiariesByCategory: categoriesMap,
              completionRate: fundDistribution.zakatPercentage,
            );
          },
        ),
      );

  /// Subscribes to [build] only when the signed-in user has role `admin`.
  Stream<T> _adminGuarded<T>(String label, Stream<T> Function() build) {
    return Stream.fromFuture(_auth.isCurrentUserAdmin()).asyncExpand((isAdmin) {
      if (!isAdmin) {
        debugPrint('⚠️ [Dashboard] $label blocked — caller is not admin');
        return Stream<T>.empty();
      }
      debugPrint('🔗 [Dashboard] $label stream active (admin verified)');
      return build();
    });
  }

  double _sumAmounts(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    double total = 0.0;
    for (final doc in docs) {
      total += AppConstants.parseDouble(doc.data()['amount']);
    }
    debugPrint('   📊 [Dashboard] totalDonations = \$${total.toStringAsFixed(2)}');
    return total;
  }

  /// Calculate fund distribution by donation type and beneficiary category.
  FundDistribution _calculateFundDistribution(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    double zakatAmount = 0.0;
    double sadaqahAmount = 0.0;
    final Map<String, double> byCategory = {};

    for (final doc in docs) {
      final data = doc.data();
      final amount = AppConstants.parseDouble(data['amount']);
      final type = data['type'] as String? ?? 'Unknown';

      if (type.toLowerCase() == 'zakat') {
        zakatAmount += amount;
      } else if (type.toLowerCase() == 'sadaqah') {
        sadaqahAmount += amount;
      }

      // Group by beneficiary category if available
      final category = data['beneficiaryCategory'] as String? ?? 'Uncategorized';
      byCategory[category] = (byCategory[category] ?? 0.0) + amount;
    }

    final totalAmount = zakatAmount + sadaqahAmount;
    debugPrint(
        '   💰 [Dashboard] Zakat: \$${zakatAmount.toStringAsFixed(2)}, Sadaqah: \$${sadaqahAmount.toStringAsFixed(2)}');

    return FundDistribution(
      zakatAmount: zakatAmount,
      sadaqahAmount: sadaqahAmount,
      totalAmount: totalAmount,
      byBeneficiaryCategory: byCategory,
    );
  }

  /// Calculate donation trends (daily aggregation for last 30 days).
  List<DonationTrendPoint> _calculateDonationTrends(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<DateTime, (double, int)> trendMap = {}; // date -> (amount, count)

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    for (final doc in docs) {
      final data = doc.data();
      final timestamp = data['timestamp'];

      DateTime donationDate;
      if (timestamp is Timestamp) {
        donationDate = timestamp.toDate();
      } else if (timestamp is DateTime) {
        donationDate = timestamp;
      } else {
        continue;
      }

      // Filter to last 30 days
      if (donationDate.isBefore(thirtyDaysAgo)) continue;

      // Normalize to date only (ignore time)
      final dateKey =
          DateTime(donationDate.year, donationDate.month, donationDate.day);
      final amount = AppConstants.parseDouble(data['amount']);

      if (trendMap.containsKey(dateKey)) {
        final (total, count) = trendMap[dateKey]!;
        trendMap[dateKey] = (total + amount, count + 1);
      } else {
        trendMap[dateKey] = (amount, 1);
      }
    }

    // Convert to sorted list
    final trends = trendMap.entries
        .map((e) => DonationTrendPoint(
              date: e.key,
              amount: e.value.$1,
              count: e.value.$2,
            ))
        .toList();

    trends.sort((a, b) => a.date.compareTo(b.date));

    debugPrint(
        '   📈 [Dashboard] Donation trends: ${trends.length} days tracked');
    return trends;
  }

  /// Group beneficiaries by their category.
  Map<String, int> _calculateBeneficiariesByCategory(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, int> categoryCount = {};

    for (final doc in docs) {
      final category = doc.data()['category'] as String? ?? 'Uncategorized';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    debugPrint('   👥 [Dashboard] Beneficiaries by category: $categoryCount');
    return categoryCount;
  }
}
