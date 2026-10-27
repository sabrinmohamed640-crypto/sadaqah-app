import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// A full-page view showing the Admin System Logs timeline.
/// Navigated to from the Dashboard's "System Logs" card.
class AdminSystemLogsPage extends StatefulWidget {
  const AdminSystemLogsPage({super.key});

  @override
  State<AdminSystemLogsPage> createState() => _AdminSystemLogsPageState();
}

class _AdminSystemLogsPageState extends State<AdminSystemLogsPage> {
  static const Color _charcoal = AppTheme.charcoal;
  static const Color _bgColor = AppTheme.lightBackground;

  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Success', 'Warning', 'Error', 'Info'];

  final List<_LogEntry> _logs = [
    _LogEntry(
      type: 'Success',
      icon: Icons.verified_outlined,
      title: 'Successful Audit Completed',
      detail: 'Full compliance audit passed — 0 discrepancies found.',
      actor: 'System Automator',
      timeAgo: '2 mins ago',
      timestamp: '2026-06-13 · 09:11 AM',
    ),
    _LogEntry(
      type: 'Info',
      icon: Icons.payments_outlined,
      title: 'Disbursement Batch #109 Released',
      detail: 'RM 48,200 distributed across 38 verified beneficiaries.',
      actor: 'Admin: Sarah J.',
      timeAgo: '45 mins ago',
      timestamp: '2026-06-13 · 08:28 AM',
    ),
    _LogEntry(
      type: 'Error',
      icon: Icons.gpp_bad_outlined,
      title: 'Failed Login Attempt',
      detail: 'Unauthorized access attempt detected and blocked.',
      actor: 'IP: 192.168.1.45',
      timeAgo: '2 hours ago',
      timestamp: '2026-06-13 · 07:15 AM',
    ),
    _LogEntry(
      type: 'Warning',
      icon: Icons.warning_amber_outlined,
      title: 'Fund Reserve Below Threshold',
      detail: 'Emergency reserve fell below the 15% safety margin.',
      actor: 'System Monitor',
      timeAgo: '4 hours ago',
      timestamp: '2026-06-13 · 05:08 AM',
    ),
    _LogEntry(
      type: 'Info',
      icon: Icons.person_add_alt_1_outlined,
      title: 'New Beneficiary Registered',
      detail: 'Application by Mariam Yusuf submitted and queued for review.',
      actor: 'Admin: Khalid R.',
      timeAgo: '6 hours ago',
      timestamp: '2026-06-13 · 03:05 AM',
    ),
    _LogEntry(
      type: 'Success',
      icon: Icons.backup_outlined,
      title: 'Database Backup Completed',
      detail: 'Weekly cloud snapshot created successfully — 2.4 GB.',
      actor: 'System Automator',
      timeAgo: '1 day ago',
      timestamp: '2026-06-12 · 11:00 PM',
    ),
    _LogEntry(
      type: 'Warning',
      icon: Icons.update_outlined,
      title: 'System Update Available',
      detail: 'Version 2.4.1 is available. Manual deployment required.',
      actor: 'System Monitor',
      timeAgo: '1 day ago',
      timestamp: '2026-06-12 · 08:00 AM',
    ),
    _LogEntry(
      type: 'Error',
      icon: Icons.sync_problem_outlined,
      title: 'Report Generation Failed',
      detail: 'Timeout during Q2 financial summary export. Retry pending.',
      actor: 'Admin: Yusuf A.',
      timeAgo: '2 days ago',
      timestamp: '2026-06-11 · 02:30 PM',
    ),
  ];

  List<_LogEntry> get _filteredLogs => _activeFilter == 'All'
      ? _logs
      : _logs.where((l) => l.type == _activeFilter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _charcoal, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'System Logs',
          style: TextStyle(
            color: _charcoal,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined,
                color: Color(0xFF64748B), size: 20),
            tooltip: 'Export Logs',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exporting system logs as CSV...'),
                  backgroundColor: Color(0xFF047857),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary chips ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                _buildSummaryChip('Success',
                    _logs.where((l) => l.type == 'Success').length),
                const SizedBox(width: 10),
                _buildSummaryChip(
                    'Warning', _logs.where((l) => l.type == 'Warning').length),
                const SizedBox(width: 10),
                _buildSummaryChip(
                    'Error', _logs.where((l) => l.type == 'Error').length),
              ],
            ),
          ),

          // ── Filter chips ───────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final bool isSelected = _activeFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _activeFilter = f),
                      selectedColor: _logTypeColor(f).withValues(alpha: 0.12),
                      checkmarkColor: _logTypeColor(f),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? _logTypeColor(f)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isSelected
                            ? _logTypeColor(f).withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Log timeline ───────────────────────────────────────────
          Expanded(
            child: _filteredLogs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      return _buildTimelineItem(
                        _filteredLogs[index],
                        isLast: index == _filteredLogs.length - 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String type, int count) {
    final color = _logTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $type',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(_LogEntry log, {required bool isLast}) {
    final Color dotColor = _logTypeColor(log.type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline dot + line column
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(log.icon, size: 14, color: dotColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              log.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              log.type,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: dotColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Detail text
                      Text(
                        log.detail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Footer row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 11, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                log.actor,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 11, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 3),
                              Text(
                                log.timeAgo,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _logTypeColor(String type) {
    switch (type) {
      case 'Success':
        return const Color(0xFF10B981);
      case 'Warning':
        return const Color(0xFFD97706);
      case 'Error':
        return const Color(0xFFEF4444);
      case 'Info':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            'No logs found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'No system logs match the selected filter.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _LogEntry {
  final String type;
  final IconData icon;
  final String title;
  final String detail;
  final String actor;
  final String timeAgo;
  final String timestamp;

  const _LogEntry({
    required this.type,
    required this.icon,
    required this.title,
    required this.detail,
    required this.actor,
    required this.timeAgo,
    required this.timestamp,
  });
}
