import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/dashboard_metrics.dart';
import 'auth_service.dart';
import 'dashboard_service.dart';
import 'donor_analytics_service.dart';
import 'beneficiary_analytics_service.dart';

/// Service for generating PDF and CSV reports for admins
class ReportGenerationService {
  ReportGenerationService({AuthService? authService})
      : _auth = authService ?? AuthService();

  final AuthService _auth;
  final DashboardService _dashboard = DashboardService();
  final DonorAnalyticsService _donorAnalytics = DonorAnalyticsService();
  final BeneficiaryAnalyticsService _beneficiaryAnalytics =
      BeneficiaryAnalyticsService();

  /// Generate comprehensive PDF dashboard report
  Future<Uint8List> generateDashboardPdf() async {
    try {
      final isAdmin = await _auth.isCurrentUserAdmin();
      if (!isAdmin) throw Exception('Only admins can generate reports');

      final metrics = await _fetchDashboardMetrics();
      final topDonors = await _donorAnalytics.getTopDonors(limit: 5);
      final topBeneficiaries =
          await _beneficiaryAnalytics.getTopBeneficiaries(limit: 5);

      final pdf = pw.Document();

      // Title Page
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Zakat Management System',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Comprehensive Dashboard Report',
                style: const pw.TextStyle(fontSize: 20),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated: ${_formatDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );

      // Key Metrics Page
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Key Metrics',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              _buildMetricTable([
                ['Total Donations', '\$${metrics.totalDonations.toStringAsFixed(2)}'],
                ['Total Donors', '${metrics.totalDonors}'],
                ['Active Beneficiaries', '${metrics.activeBeneficiaries}'],
                ['Pending Approvals', '${metrics.pendingApprovals}'],
                ['Average Donation', '\$${metrics.averageDonation.toStringAsFixed(2)}'],
                ['Completion Rate', '${metrics.completionRate.toStringAsFixed(2)}%'],
              ]),
            ],
          ),
        ),
      );

      // Top Donors Page
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Top Donors',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              _buildDonorTable(topDonors),
            ],
          ),
        ),
      );

      // Top Beneficiaries Page
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Top Beneficiaries',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              _buildBeneficiaryTable(topBeneficiaries),
            ],
          ),
        ),
      );

      debugPrint('✅ [ReportGen] PDF report generated successfully');
      return pdf.save();
    } catch (e) {
      debugPrint('❌ [ReportGen] PDF generation failed: $e');
      rethrow;
    }
  }

  /// Generate CSV report of all donations
  Future<String> generateDonationsCsv() async {
    try {
      final isAdmin = await _auth.isCurrentUserAdmin();
      if (!isAdmin) throw Exception('Only admins can generate reports');

      final topDonors = await _donorAnalytics.getTopDonors(limit: 1000);

      final StringBuffer csv = StringBuffer();
      csv.writeln(
          'Donor Name,Total Donated,Donation Count,Avg Donation,Zakat,Sadaqah,Engagement Level,Last Donation');

      for (final donor in topDonors) {
        csv.writeln(
            '${donor.donorName},${donor.totalDonated.toStringAsFixed(2)},${donor.donationCount},${donor.averageDonation.toStringAsFixed(2)},${donor.zakatDonated.toStringAsFixed(2)},${donor.sadaqahDonated.toStringAsFixed(2)},${donor.engagementLevel},${_formatDate(donor.lastDonationDate)}');
      }

      debugPrint('✅ [ReportGen] Donations CSV generated (${topDonors.length} rows)');
      return csv.toString();
    } catch (e) {
      debugPrint('❌ [ReportGen] CSV generation failed: $e');
      rethrow;
    }
  }

  /// Generate CSV report of all beneficiaries
  Future<String> generateBeneficiariesCsv() async {
    try {
      final isAdmin = await _auth.isCurrentUserAdmin();
      if (!isAdmin) throw Exception('Only admins can generate reports');

      final beneficiaries =
          await _beneficiaryAnalytics.getAllBeneficiariesImpact();

      final StringBuffer csv = StringBuffer();
      csv.writeln(
          'Name,Category,Status,Amount Received,Donation Count,Avg Monthly Funding,Monthly Need,Still in Need');

      for (final beneficiary in beneficiaries) {
        csv.writeln(
            '${beneficiary.beneficiaryName},${beneficiary.category},${beneficiary.status},${beneficiary.amountReceived.toStringAsFixed(2)},${beneficiary.donationCount},${beneficiary.averageMonthlyFunding.toStringAsFixed(2)},${beneficiary.estimatedMonthlyNeed.toStringAsFixed(2)},${beneficiary.stillInNeed ? 'Yes' : 'No'}');
      }

      debugPrint(
          '✅ [ReportGen] Beneficiaries CSV generated (${beneficiaries.length} rows)');
      return csv.toString();
    } catch (e) {
      debugPrint('❌ [ReportGen] CSV generation failed: $e');
      rethrow;
    }
  }

  /// Generate detailed fund distribution CSV
  Future<String> generateFundDistributionCsv() async {
    try {
      final isAdmin = await _auth.isCurrentUserAdmin();
      if (!isAdmin) throw Exception('Only admins can generate reports');

      final metrics = await _fetchDashboardMetrics();

      final StringBuffer csv = StringBuffer();
      csv.writeln('Category,Amount Received');

      for (final entry in metrics.fundDistributionByCategory.entries) {
        csv.writeln('${entry.key},${entry.value.toStringAsFixed(2)}');
      }

      debugPrint('✅ [ReportGen] Fund distribution CSV generated');
      return csv.toString();
    } catch (e) {
      debugPrint('❌ [ReportGen] CSV generation failed: $e');
      rethrow;
    }
  }

  /// Helper: Fetch current dashboard metrics
  Future<DashboardMetrics> _fetchDashboardMetrics() async {
    return DashboardMetrics(
      totalDonations: 0, // These would come from streams in real implementation
      activeBeneficiaries: 0,
      pendingApprovals: 0,
      averageDonation: 0,
      totalDonors: 0,
      fundDistributionByCategory: {},
      donationTrends: [],
      beneficiariesByCategory: {},
      completionRate: 0,
    );
  }

  /// Helper: Build metric table for PDF
  pw.Widget _buildMetricTable(List<List<String>> data) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Metric',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Value',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        // Data rows
        ...data.map((row) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(row[0]),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(row[1]),
            ),
          ],
        )),
      ],
    );
  }

  /// Helper: Build donors table for PDF
  pw.Widget _buildDonorTable(List<DonorAnalytics> donors) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          children: [
            'Name',
            'Total',
            'Count',
            'Avg',
          ]
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(h,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        // Data rows
        ...donors.map((donor) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(donor.donorName),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('\$${donor.totalDonated.toStringAsFixed(2)}'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('${donor.donationCount}'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('\$${donor.averageDonation.toStringAsFixed(2)}'),
            ),
          ],
        )),
      ],
    );
  }

  /// Helper: Build beneficiaries table for PDF
  pw.Widget _buildBeneficiaryTable(List<BeneficiaryImpact> beneficiaries) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          children: [
            'Name',
            'Category',
            'Amount',
            'Count',
          ]
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(h,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        // Data rows
        ...beneficiaries.map((ben) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(ben.beneficiaryName),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(ben.category),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('\$${ben.amountReceived.toStringAsFixed(2)}'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('${ben.donationCount}'),
            ),
          ],
        )),
      ],
    );
  }

  /// Helper: Format date
  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
