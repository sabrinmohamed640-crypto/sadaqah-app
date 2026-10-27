/// Advanced dashboard metrics model for real-time analytics.
class DashboardMetrics {
  final double totalDonations;
  final int activeBeneficiaries;
  final int pendingApprovals;
  final double averageDonation;
  final int totalDonors;
  final Map<String, double> fundDistributionByCategory; // category -> amount
  final List<DonationTrendPoint> donationTrends; // Daily/Weekly trends
  final Map<String, int> beneficiariesByCategory; // category -> count
  final double completionRate; // % of successful vs failed donations

  DashboardMetrics({
    required this.totalDonations,
    required this.activeBeneficiaries,
    required this.pendingApprovals,
    required this.averageDonation,
    required this.totalDonors,
    required this.fundDistributionByCategory,
    required this.donationTrends,
    required this.beneficiariesByCategory,
    required this.completionRate,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      totalDonations: 0.0,
      activeBeneficiaries: 0,
      pendingApprovals: 0,
      averageDonation: 0.0,
      totalDonors: 0,
      fundDistributionByCategory: {},
      donationTrends: [],
      beneficiariesByCategory: {},
      completionRate: 0.0,
    );
  }
}

/// Represents a single data point in donation trend analysis
class DonationTrendPoint {
  final DateTime date;
  final double amount;
  final int count; // Number of donations on this date

  DonationTrendPoint({
    required this.date,
    required this.amount,
    required this.count,
  });

  String get formattedDate => '${date.month}/${date.day}';
}

/// Fund distribution breakdown by donation type and category
class FundDistribution {
  final double zakatAmount;
  final double sadaqahAmount;
  final double totalAmount;
  final Map<String, double> byBeneficiaryCategory;

  FundDistribution({
    required this.zakatAmount,
    required this.sadaqahAmount,
    required this.totalAmount,
    required this.byBeneficiaryCategory,
  });

  double get zakatPercentage => totalAmount > 0 ? (zakatAmount / totalAmount) * 100 : 0;
  double get sadaqahPercentage => totalAmount > 0 ? (sadaqahAmount / totalAmount) * 100 : 0;
}

/// Donor performance metrics
class DonorAnalytics {
  final String donorId;
  final String donorName;
  final double totalDonated;
  final int donationCount;
  final double averageDonation;
  final DateTime lastDonationDate;
  final List<DateTime> donationDates; // Track frequency
  final double zakatDonated;
  final double sadaqahDonated;
  final int monthlyConsistency; // % of months where user donated

  DonorAnalytics({
    required this.donorId,
    required this.donorName,
    required this.totalDonated,
    required this.donationCount,
    required this.averageDonation,
    required this.lastDonationDate,
    required this.donationDates,
    required this.zakatDonated,
    required this.sadaqahDonated,
    required this.monthlyConsistency,
  });

  /// Returns donor engagement level
  String get engagementLevel {
    if (donationCount > 12) return 'Highly Engaged';
    if (donationCount > 6) return 'Engaged';
    if (donationCount > 3) return 'Active';
    return 'Occasional';
  }

  /// Days since last donation
  int get daysSinceLastDonation => DateTime.now().difference(lastDonationDate).inDays;
}

/// Beneficiary impact report
class BeneficiaryImpact {
  final String beneficiaryId;
  final String beneficiaryName;
  final String category; // One of 8 Islamic zakat categories
  final double amountReceived;
  final int donationCount;
  final DateTime registrationDate;
  final String status; // Verified, Pending, Rejected
  final List<DateTime> fundingDates;
  final double estimatedMonthlyNeed;

  BeneficiaryImpact({
    required this.beneficiaryId,
    required this.beneficiaryName,
    required this.category,
    required this.amountReceived,
    required this.donationCount,
    required this.registrationDate,
    required this.status,
    required this.fundingDates,
    required this.estimatedMonthlyNeed,
  });

  /// Months since first funding
  int get monthsSinceFunding => fundingDates.isNotEmpty
      ? DateTime.now().difference(fundingDates.first).inDays ~/ 30
      : 0;

  /// Average monthly funding received
  double get averageMonthlyFunding => monthsSinceFunding > 0
      ? amountReceived / monthsSinceFunding
      : 0.0;

  /// Whether beneficiary is still in need (avg monthly < monthly need estimate)
  bool get stillInNeed => averageMonthlyFunding < estimatedMonthlyNeed;
}
