import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../utils/theme.dart';
import '../utils/typography.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/animated_buttons.dart';
import 'admin_pending_approvals_page.dart';
import 'admin_system_logs_page.dart';

class AdminDashboardView extends StatelessWidget {
  final VoidCallback onViewAllRequests;
  final VoidCallback onGenerateReport;

  const AdminDashboardView({
    super.key,
    required this.onViewAllRequests,
    required this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    final DashboardService dashboard = DashboardService();
    final double bottomPad =
        MediaQuery.of(context).padding.bottom + 70 + 24;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dashboard Header ───────────────────────────────────────
            _buildHeaderSection(context),
            const SizedBox(height: 32),

            // ── Section: Key Metrics ───────────────────────────────────
            _buildSectionLabel('Key Metrics'),
            const SizedBox(height: 16),

            // Metrics Grid: Total Donations & Active Beneficiaries
            _buildMetricsGrid(context, dashboard),
            const SizedBox(height: 32),

            // ── Section: Additional Metrics ────────────────────────────
            _buildSectionLabel('Overview'),
            const SizedBox(height: 16),
            _buildAdditionalMetrics(context, dashboard),
            const SizedBox(height: 32),

            // ── Section: Quick Actions ─────────────────────────────────
            _buildSectionLabel('Quick Actions'),
            const SizedBox(height: 16),
            _buildQuickActions(context, dashboard),
            const SizedBox(height: 32),

            // ── Section: System Status ─────────────────────────────────
            _buildSectionLabel('System Status'),
            const SizedBox(height: 16),
            _buildStatusCard(context),
          ],
        ),
      ),
    );
  }

  // ── Header Section with Professional Welcome ────────────────────────
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.charcoal,
            AppTheme.charcoal.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.charcoal.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin Portal',
                      style: AppTypography.displayMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.shield_outlined,
                color: Colors.white.withValues(alpha: 0.15),
                size: 60,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'All systems operational',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Metrics Grid with DashboardStatsCard ────────────────────────────
  Widget _buildMetricsGrid(BuildContext context, DashboardService dashboard) {
    return Column(
      children: [
        // Total Donations
        StreamBuilder<double>(
          stream: dashboard.totalDonationsStream,
          builder: (context, snapshot) {
            return DashboardStatsCard(
              title: 'Total Donations',
              subtitle: 'All-time fund collection',
              value: _formatCurrency(snapshot.data ?? 0.0),
              icon: Icons.payments_outlined,
              accentColor: AppTheme.emerald,
              isLoading: snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData,
            );
          },
        ),
        const SizedBox(height: 16),

        // Active Beneficiaries
        StreamBuilder<int>(
          stream: dashboard.activeBeneficiariesCountStream,
          builder: (context, snapshot) {
            return DashboardStatsCard(
              title: 'Active Beneficiaries',
              subtitle: 'Verified recipients',
              value: snapshot.data?.toString() ?? '0',
              icon: Icons.people_outline,
              accentColor: AppTheme.gold,
              isLoading: snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData,
            );
          },
        ),
      ],
    );
  }

  // ── Additional Metrics ─────────────────────────────────────────────
  Widget _buildAdditionalMetrics(
      BuildContext context, DashboardService dashboard) {
    return Column(
      children: [
        // Total Donors
        StreamBuilder<int>(
          stream: dashboard.totalDonorsStream,
          builder: (context, snapshot) {
            return DashboardStatsCard(
              title: 'Total Donors',
              subtitle: 'Unique contributors',
              value: snapshot.data?.toString() ?? '0',
              icon: Icons.person_outline,
              accentColor: const Color(0xFF3B82F6),
              isLoading: snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData,
            );
          },
        ),
        const SizedBox(height: 16),

        // Average Donation
        StreamBuilder<double>(
          stream: dashboard.averageDonationStream,
          builder: (context, snapshot) {
            return DashboardStatsCard(
              title: 'Average Donation',
              subtitle: 'Per contribution',
              value: _formatCurrency(snapshot.data ?? 0.0),
              icon: Icons.trending_up_outlined,
              accentColor: const Color(0xFF8B5CF6),
              isLoading: snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData,
            );
          },
        ),
      ],
    );
  }

  // ── Quick Actions Section ──────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, DashboardService dashboard) {
    return Column(
      children: [
        // Pending Approvals
        StreamBuilder<int>(
          stream: dashboard.pendingApprovalsCountStream,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

            return SmoothAnimatedButton(
              label: 'Pending Approvals',
              icon: Icons.assignment_turned_in_outlined,
              backgroundColor: const Color(0xFFFEF9C3),
              foregroundColor: AppTheme.charcoal,
              height: 56,
              isLoading: isLoading,
              onPressed: () {
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPendingApprovalsPage(),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),

        // System Logs
        SmoothAnimatedButton(
          label: 'System Logs',
          icon: Icons.receipt_long_outlined,
          backgroundColor: const Color(0xFFEFF6FF),
          foregroundColor: const Color(0xFF1F2937),
          height: 56,
          onPressed: () {
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminSystemLogsPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Generate Report
        SmoothAnimatedButton(
          label: 'Generate Report',
          icon: Icons.bar_chart_rounded,
          backgroundColor: AppTheme.emerald.withValues(alpha: 0.1),
          foregroundColor: AppTheme.charcoal,
          height: 56,
          onPressed: onGenerateReport,
        ),
      ],
    );
  }

  // ── Section Label ────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.labelMedium.copyWith(
        color: AppTheme.textMutedLight,
        letterSpacing: 1.0,
      ),
    );
  }

  // ── System Status Card ────────────────────────────────────────────
  Widget _buildStatusCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkSurfaceAlt.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatusRow(
            Icons.storage_outlined,
            'Database',
            'Healthy',
            true,
            isDark,
          ),
          Divider(
            height: 20,
            color: isDark
                ? AppTheme.darkSurfaceAlt.withValues(alpha: 0.3)
                : const Color(0xFFF1F5F9),
          ),
          _buildStatusRow(
            Icons.cloud_done_outlined,
            'Cloud Backup',
            'Synced',
            true,
            isDark,
          ),
          Divider(
            height: 20,
            color: isDark
                ? AppTheme.darkSurfaceAlt.withValues(alpha: 0.3)
                : const Color(0xFFF1F5F9),
          ),
          _buildStatusRow(
            Icons.security_outlined,
            'Security',
            'No threats',
            true,
            isDark,
          ),
          Divider(
            height: 20,
            color: isDark
                ? AppTheme.darkSurfaceAlt.withValues(alpha: 0.3)
                : const Color(0xFFF1F5F9),
          ),
          _buildStatusRow(
            Icons.notifications_active_outlined,
            'Alerts',
            '2 warnings',
            false,
            isDark,
          ),
        ],
      ),
    );
  }

  // ── Status Row ────────────────────────────────────────────────────
  Widget _buildStatusRow(
    IconData icon,
    String label,
    String status,
    bool isOk,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF1E293B),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isOk
                ? const Color(0xFFD1FAE5)
                : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOk ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                size: 12,
                color: isOk
                    ? const Color(0xFF065F46)
                    : const Color(0xFFB45309),
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: AppTypography.labelSmall.copyWith(
                  color: isOk
                      ? const Color(0xFF065F46)
                      : const Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helper: Format Currency ───────────────────────────────────────
  static String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }
}
