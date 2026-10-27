import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zakat_sadaqah_app/services/cache_manager.dart';
import 'package:zakat_sadaqah_app/models/dashboard_metrics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheManager Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('setCache and getCache - string value', () async {
      const testKey = 'test_string';
      const testValue = 'Hello, World!';

      final result =
          await CacheManager.setCache(testKey, testValue);
      expect(result, true);

      final retrieved = await CacheManager.getCache(testKey);
      expect(retrieved, testValue);
    });

    test('setCache and getCache - number value', () async {
      const testKey = 'test_number';
      const testValue = 42.5;

      await CacheManager.setCache(testKey, testValue);
      final retrieved = await CacheManager.getCacheTyped<double>(testKey);

      expect(retrieved, testValue);
    });

    test('setCache and getCache - list value', () async {
      const testKey = 'test_list';
      const testValue = [1, 2, 3, 4, 5];

      await CacheManager.setCache(testKey, testValue);
      final retrieved = await CacheManager.getCache(testKey);

      expect(retrieved, testValue);
    });

    test('setCache and getCache - map value', () async {
      const testKey = 'test_map';
      final testValue = {'name': 'John', 'age': 30};

      await CacheManager.setCache(testKey, testValue);
      final retrieved = await CacheManager.getCache(testKey);

      expect(retrieved, testValue);
    });

    test('setCache expiration - should return null when expired', () async {
      const testKey = 'expiring_key';
      const testValue = 'temporary';

      await CacheManager.setCache(
        testKey,
        testValue,
        cacheDuration: const Duration(milliseconds: 100),
      );

      // Immediate retrieval should work
      var retrieved = await CacheManager.getCache(testKey);
      expect(retrieved, testValue);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));
      retrieved = await CacheManager.getCache(testKey);
      expect(retrieved, null);
    });

    test('removeCache - should remove cached value', () async {
      const testKey = 'removable_key';
      const testValue = 'remove me';

      await CacheManager.setCache(testKey, testValue);
      var retrieved = await CacheManager.getCache(testKey);
      expect(retrieved, testValue);

      await CacheManager.removeCache(testKey);
      retrieved = await CacheManager.getCache(testKey);
      expect(retrieved, null);
    });

    test('hasCacheValid - should return true for valid cache', () async {
      const testKey = 'valid_key';
      await CacheManager.setCache(testKey, 'value');

      final isValid = await CacheManager.hasCacheValid(testKey);
      expect(isValid, true);
    });

    test('hasCacheValid - should return false for non-existent cache',
        () async {
      const testKey = 'non_existent_key';
      final isValid = await CacheManager.hasCacheValid(testKey);
      expect(isValid, false);
    });

    test('clearAllCache - should clear all cached values', () async {
      await CacheManager.setCache('key1', 'value1');
      await CacheManager.setCache('key2', 'value2');
      await CacheManager.setCache('key3', 'value3');

      var val1 = await CacheManager.getCache('key1');
      expect(val1, 'value1');

      await CacheManager.clearAllCache();

      val1 = await CacheManager.getCache('key1');
      expect(val1, null);
    });
  });

  group('DashboardCacheManager Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('cacheTotalDonations and getCachedTotalDonations', () async {
      const amount = 5000.50;

      await DashboardCacheManager.cacheTotalDonations(amount);
      final cached =
          await DashboardCacheManager.getCachedTotalDonations();

      expect(cached, amount);
    });

    test('cacheActiveBeneficiaries and getCachedActiveBeneficiaries',
        () async {
      const count = 25;

      await DashboardCacheManager.cacheActiveBeneficiaries(count);
      final cached =
          await DashboardCacheManager.getCachedActiveBeneficiaries();

      expect(cached, count);
    });

    test('cachePendingApprovals and getCachedPendingApprovals', () async {
      const count = 5;

      await DashboardCacheManager.cachePendingApprovals(count);
      final cached =
          await DashboardCacheManager.getCachedPendingApprovals();

      expect(cached, count);
    });

    test('cacheFundDistribution and getCachedFundDistribution', () async {
      final distribution = {
        'Fakir': 1000.0,
        'Miskin': 500.0,
        'Amil': 250.0,
      };

      await DashboardCacheManager.cacheFundDistribution(distribution);
      final cached =
          await DashboardCacheManager.getCachedFundDistribution();

      expect(cached, distribution);
    });

    test('clearDashboardCache - should clear all dashboard cache', () async {
      await DashboardCacheManager.cacheTotalDonations(1000);
      await DashboardCacheManager.cacheActiveBeneficiaries(10);

      await DashboardCacheManager.clearDashboardCache();

      final donations =
          await DashboardCacheManager.getCachedTotalDonations();
      final beneficiaries =
          await DashboardCacheManager.getCachedActiveBeneficiaries();

      expect(donations, null);
      expect(beneficiaries, null);
    });
  });

  group('DashboardMetrics Tests', () {
    test('DashboardMetrics creation with all parameters', () {
      final metrics = DashboardMetrics(
        totalDonations: 50000,
        activeBeneficiaries: 100,
        pendingApprovals: 5,
        averageDonation: 500,
        totalDonors: 50,
        fundDistributionByCategory: {
          'Fakir': 20000,
          'Miskin': 15000,
          'Amil': 10000,
        },
        donationTrends: [],
        beneficiariesByCategory: {
          'Fakir': 40,
          'Miskin': 35,
          'Amil': 25,
        },
        completionRate: 95.5,
      );

      expect(metrics.totalDonations, 50000);
      expect(metrics.activeBeneficiaries, 100);
      expect(metrics.pendingApprovals, 5);
      expect(metrics.averageDonation, 500);
      expect(metrics.totalDonors, 50);
      expect(metrics.completionRate, 95.5);
    });

    test('DashboardMetrics.empty() creates empty metrics', () {
      final emptyMetrics = DashboardMetrics.empty();

      expect(emptyMetrics.totalDonations, 0.0);
      expect(emptyMetrics.activeBeneficiaries, 0);
      expect(emptyMetrics.pendingApprovals, 0);
      expect(emptyMetrics.averageDonation, 0.0);
      expect(emptyMetrics.totalDonors, 0);
      expect(emptyMetrics.fundDistributionByCategory, isEmpty);
      expect(emptyMetrics.donationTrends, isEmpty);
      expect(emptyMetrics.beneficiariesByCategory, isEmpty);
      expect(emptyMetrics.completionRate, 0.0);
    });

    test('DonationTrendPoint creation and formatting', () {
      final now = DateTime(2024, 6, 15);
      final trendPoint = DonationTrendPoint(
        date: now,
        amount: 1500.50,
        count: 3,
      );

      expect(trendPoint.date, now);
      expect(trendPoint.amount, 1500.50);
      expect(trendPoint.count, 3);
      expect(trendPoint.formattedDate, '6/15');
    });

    test('FundDistribution calculation of percentages', () {
      final distribution = FundDistribution(
        zakatAmount: 6000,
        sadaqahAmount: 4000,
        totalAmount: 10000,
        byBeneficiaryCategory: {},
      );

      expect(distribution.zakatPercentage, 60.0);
      expect(distribution.sadaqahPercentage, 40.0);
    });

    test('FundDistribution with zero total amount', () {
      final distribution = FundDistribution(
        zakatAmount: 0,
        sadaqahAmount: 0,
        totalAmount: 0,
        byBeneficiaryCategory: {},
      );

      expect(distribution.zakatPercentage, 0);
      expect(distribution.sadaqahPercentage, 0);
    });
  });

  group('DonorAnalytics Tests', () {
    test('DonorAnalytics engagement level - Highly Engaged', () {
      final donor = DonorAnalytics(
        donorId: '123',
        donorName: 'John Donor',
        totalDonated: 50000,
        donationCount: 15,
        averageDonation: 3333.33,
        lastDonationDate: DateTime.now(),
        donationDates: List.generate(15, (i) =>
            DateTime.now().subtract(Duration(days: i))),
        zakatDonated: 30000,
        sadaqahDonated: 20000,
        monthlyConsistency: 90,
      );

      expect(donor.engagementLevel, 'Highly Engaged');
    });

    test('DonorAnalytics engagement level - Engaged', () {
      final donor = DonorAnalytics(
        donorId: '123',
        donorName: 'Jane Donor',
        totalDonated: 10000,
        donationCount: 8,
        averageDonation: 1250,
        lastDonationDate: DateTime.now(),
        donationDates: List.generate(8, (i) =>
            DateTime.now().subtract(Duration(days: i * 15))),
        zakatDonated: 5000,
        sadaqahDonated: 5000,
        monthlyConsistency: 70,
      );

      expect(donor.engagementLevel, 'Engaged');
    });

    test('DonorAnalytics engagement level - Active', () {
      final donor = DonorAnalytics(
        donorId: '123',
        donorName: 'Bob Donor',
        totalDonated: 3000,
        donationCount: 4,
        averageDonation: 750,
        lastDonationDate: DateTime.now(),
        donationDates: List.generate(4, (i) =>
            DateTime.now().subtract(Duration(days: i * 30))),
        zakatDonated: 2000,
        sadaqahDonated: 1000,
        monthlyConsistency: 50,
      );

      expect(donor.engagementLevel, 'Active');
    });

    test('DonorAnalytics daysSinceLastDonation', () {
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
      final donor = DonorAnalytics(
        donorId: '123',
        donorName: 'Recent Donor',
        totalDonated: 1000,
        donationCount: 1,
        averageDonation: 1000,
        lastDonationDate: fiveDaysAgo,
        donationDates: [fiveDaysAgo],
        zakatDonated: 1000,
        sadaqahDonated: 0,
        monthlyConsistency: 100,
      );

      expect(donor.daysSinceLastDonation,
          lessThanOrEqualTo(5)); // Allow small time difference
    });
  });

  group('BeneficiaryImpact Tests', () {
    test('BeneficiaryImpact monthsSinceFunding calculation', () {
      final twoMonthsAgo =
          DateTime.now().subtract(const Duration(days: 60));
      final beneficiary = BeneficiaryImpact(
        beneficiaryId: '456',
        beneficiaryName: 'Ahmed Beneficiary',
        category: 'Fakir',
        amountReceived: 5000,
        donationCount: 3,
        registrationDate: DateTime.now(),
        status: 'Verified',
        fundingDates: [twoMonthsAgo],
        estimatedMonthlyNeed: 1000,
      );

      expect(beneficiary.monthsSinceFunding, 2);
    });

    test('BeneficiaryImpact averageMonthlyFunding calculation', () {
      final threeMonthsAgo =
          DateTime.now().subtract(const Duration(days: 90));
      final beneficiary = BeneficiaryImpact(
        beneficiaryId: '456',
        beneficiaryName: 'Fatima Beneficiary',
        category: 'Miskin',
        amountReceived: 3000,
        donationCount: 3,
        registrationDate: DateTime.now(),
        status: 'Verified',
        fundingDates: [threeMonthsAgo],
        estimatedMonthlyNeed: 500,
      );

      expect(beneficiary.averageMonthlyFunding, 1000);
    });

    test('BeneficiaryImpact stillInNeed detection', () {
      final beneficiary = BeneficiaryImpact(
        beneficiaryId: '456',
        beneficiaryName: 'Test Beneficiary',
        category: 'Amil',
        amountReceived: 1000,
        donationCount: 1,
        registrationDate: DateTime.now(),
        status: 'Verified',
        fundingDates: [
          DateTime.now().subtract(const Duration(days: 60))
        ],
        estimatedMonthlyNeed: 500,
      );

      expect(beneficiary.stillInNeed, false); // 333 > 500 is false
    });
  });
}
