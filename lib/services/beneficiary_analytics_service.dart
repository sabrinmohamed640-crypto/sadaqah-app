import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_metrics.dart';
import 'auth_service.dart';

/// Service for tracking and analyzing beneficiary impact and progress.
class BeneficiaryAnalyticsService {
  BeneficiaryAnalyticsService({AuthService? authService})
      : _auth = authService ?? AuthService();

  final AuthService _auth;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _colDonations = 'donations';
  static const String _colMustahik = 'mustahik';

  /// Get detailed impact analytics for a specific beneficiary
  Future<BeneficiaryImpact?> getBeneficiaryImpact(String beneficiaryId) async {
    try {
      // Get beneficiary info
      final beneficiary =
          await _firestore.collection(_colMustahik).doc(beneficiaryId).get();

      if (!beneficiary.exists) {
        debugPrint(
            '⚠️ [BeneficiaryAnalytics] Beneficiary not found: $beneficiaryId');
        return null;
      }

      final data = beneficiary.data()!;
      final beneficiaryName = data['name'] as String? ?? 'Unknown';
      final category = data['category'] as String? ?? 'Uncategorized';
      final status = data['status'] as String? ?? 'Unknown';
      final monthlyIncome = _parseDouble(data['monthlyIncome']);
      final registrationDate = _parseDateTime(data['registeredAt']);

      // Get all donations to this beneficiary
      final donationDocs = await _firestore
          .collection(_colDonations)
          .where('recipientId', isEqualTo: beneficiaryId)
          .get();

      double amountReceived = 0.0;
      final List<DateTime> fundingDates = [];

      for (final doc in donationDocs.docs) {
        final docData = doc.data();
        final amount = _parseDouble(docData['amount']);
        amountReceived += amount;

        final timestamp = docData['timestamp'];
        DateTime? fundDate;

        if (timestamp is Timestamp) {
          fundDate = timestamp.toDate();
        } else if (timestamp is DateTime) {
          fundDate = timestamp;
        }

        if (fundDate != null) {
          fundingDates.add(fundDate);
        }
      }

      fundingDates.sort();

      debugPrint(
          '📊 [BeneficiaryAnalytics] Beneficiary $beneficiaryId: Received \$${amountReceived.toStringAsFixed(2)} from ${donationDocs.docs.length} donations');

      return BeneficiaryImpact(
        beneficiaryId: beneficiaryId,
        beneficiaryName: beneficiaryName,
        category: category,
        amountReceived: amountReceived,
        donationCount: donationDocs.docs.length,
        registrationDate: registrationDate,
        status: status,
        fundingDates: fundingDates,
        estimatedMonthlyNeed: monthlyIncome,
      );
    } catch (e) {
      debugPrint('❌ [BeneficiaryAnalytics] Error: $e');
      return null;
    }
  }

  /// Get all beneficiaries with their impact metrics
  Future<List<BeneficiaryImpact>> getAllBeneficiariesImpact() async {
    try {
      final isAdmin = await _auth.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint(
            '⚠️ [BeneficiaryAnalytics] Non-admin cannot access all beneficiaries');
        return [];
      }

      final beneficiaries =
          await _firestore.collection(_colMustahik).get();

      final List<BeneficiaryImpact> impacts = [];
      for (final doc in beneficiaries.docs) {
        final impact = await getBeneficiaryImpact(doc.id);
        if (impact != null) {
          impacts.add(impact);
        }
      }

      return impacts;
    } catch (e) {
      debugPrint('❌ [BeneficiaryAnalytics] Error getting all beneficiaries: $e');
      return [];
    }
  }

  /// Get beneficiaries still in need (avg funding < monthly need)
  Future<List<BeneficiaryImpact>> getBeneficiariesStillInNeed() async {
    try {
      final impacts = await getAllBeneficiariesImpact();
      final inNeed = impacts.where((b) => b.stillInNeed).toList();

      debugPrint(
          '📊 [BeneficiaryAnalytics] ${inNeed.length}/${impacts.length} beneficiaries still in need');
      return inNeed;
    } catch (e) {
      debugPrint('❌ [BeneficiaryAnalytics] Error: $e');
      return [];
    }
  }

  /// Get beneficiaries by category with their total received
  Future<Map<String, (int, double)>> getBeneficiariesByCategory() async {
    try {
      final impacts = await getAllBeneficiariesImpact();
      final Map<String, (int, double)> categoryStats = {};

      for (final impact in impacts) {
        final category = impact.category;
        if (categoryStats.containsKey(category)) {
          final (count, total) = categoryStats[category]!;
          categoryStats[category] = (count + 1, total + impact.amountReceived);
        } else {
          categoryStats[category] = (1, impact.amountReceived);
        }
      }

      return categoryStats;
    } catch (e) {
      debugPrint('❌ [BeneficiaryAnalytics] Error: $e');
      return {};
    }
  }

  /// Get impact distribution (who receives most funding)
  Future<List<BeneficiaryImpact>> getTopBeneficiaries({int limit = 10}) async {
    try {
      final impacts = await getAllBeneficiariesImpact();
      impacts.sort((a, b) => b.amountReceived.compareTo(a.amountReceived));
      return impacts.take(limit).toList();
    } catch (e) {
      debugPrint('❌ [BeneficiaryAnalytics] Error: $e');
      return [];
    }
  }

  /// Calculate beneficiary recovery status
  Map<String, dynamic> calculateRecoveryStatus(BeneficiaryImpact beneficiary) {
    final monthsSinceFunding = beneficiary.monthsSinceFunding;
    final avgMonthlyFunding = beneficiary.averageMonthlyFunding;
    final monthlyNeed = beneficiary.estimatedMonthlyNeed;

    return {
      'beneficiary': beneficiary.beneficiaryName,
      'monthsSinceFunding': monthsSinceFunding,
      'totalReceived': beneficiary.amountReceived,
      'avgMonthlyFunding': avgMonthlyFunding.toStringAsFixed(2),
      'monthlyNeed': monthlyNeed.toStringAsFixed(2),
      'fundingCoverage':
          monthlyNeed > 0 ? ((avgMonthlyFunding / monthlyNeed) * 100) : 0,
      'status': _determineStatus(beneficiary),
      'fundingGap':
          (monthlyNeed - avgMonthlyFunding).abs().toStringAsFixed(2),
    };
  }

  /// Helper: Determine beneficiary status
  String _determineStatus(BeneficiaryImpact beneficiary) {
    if (beneficiary.amountReceived == 0) return 'Never Funded';
    if (beneficiary.monthsSinceFunding < 1) return 'Recently Funded';
    if (beneficiary.stillInNeed) return 'Still in Need';
    if (beneficiary.averageMonthlyFunding >= beneficiary.estimatedMonthlyNeed) {
      return 'Meeting Needs';
    }
    return 'Partial Support';
  }

  /// Helper: Parse double safely
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper: Parse DateTime safely
  DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
