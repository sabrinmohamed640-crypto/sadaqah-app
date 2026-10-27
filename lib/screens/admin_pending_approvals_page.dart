import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// A full-page view listing all pending Zakat aid requests.
/// Navigated to from the Dashboard's "Pending Approvals" card.
class AdminPendingApprovalsPage extends StatefulWidget {
  const AdminPendingApprovalsPage({super.key});

  @override
  State<AdminPendingApprovalsPage> createState() =>
      _AdminPendingApprovalsPageState();
}

class _AdminPendingApprovalsPageState
    extends State<AdminPendingApprovalsPage> {
  static const Color _charcoal = AppTheme.charcoal;
  static const Color _bgColor = AppTheme.lightBackground;

  // Mock data — replace with a Firestore stream in production
  final List<_RequestItem> _requests = [
    _RequestItem(
      id: '#882',
      icon: Icons.school_outlined,
      title: 'Education Grant #882',
      applicant: 'Fatima Zahra',
      amount: 1200,
      category: 'Education',
      urgency: 'Urgent',
      submittedAgo: '2 hours ago',
    ),
    _RequestItem(
      id: '#411',
      icon: Icons.local_hospital_outlined,
      title: 'Emergency Medical #411',
      applicant: 'Ahmed Al-Sayed',
      amount: 4500,
      category: 'Medical',
      urgency: 'Critical',
      submittedAgo: '5 hours ago',
    ),
    _RequestItem(
      id: '#319',
      icon: Icons.home_outlined,
      title: 'Housing Assistance #319',
      applicant: 'Mariam Yusuf',
      amount: 800,
      category: 'Shelter',
      urgency: 'Standard',
      submittedAgo: '1 day ago',
    ),
    _RequestItem(
      id: '#504',
      icon: Icons.fastfood_outlined,
      title: 'Food Aid Package #504',
      applicant: 'Omar Khalid',
      amount: 350,
      category: 'Food',
      urgency: 'Urgent',
      submittedAgo: '1 day ago',
    ),
    _RequestItem(
      id: '#701',
      icon: Icons.work_outline,
      title: 'Livelihood Support #701',
      applicant: 'Noor Aisha',
      amount: 2200,
      category: 'Livelihood',
      urgency: 'Standard',
      submittedAgo: '2 days ago',
    ),
  ];

  String _filter = 'All';
  final List<String> _filters = ['All', 'Urgent', 'Critical', 'Standard'];

  List<_RequestItem> get _filteredRequests => _filter == 'All'
      ? _requests
      : _requests.where((r) => r.urgency == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.charcoal, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pending Approvals',
          style: TextStyle(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.lightSurfaceAlt),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats bar ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                _buildStatChip(
                    '${_requests.length}', 'Total', const Color(0xFF0F172A)),
                const SizedBox(width: 12),
                _buildStatChip(
                    '${_requests.where((r) => r.urgency == 'Critical').length}',
                    'Critical',
                    const Color(0xFFDC2626)),
                const SizedBox(width: 12),
                _buildStatChip(
                    '${_requests.where((r) => r.urgency == 'Urgent').length}',
                    'Urgent',
                    const Color(0xFFD97706)),
              ],
            ),
          ),

          // ── Filter chips ───────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final bool isSelected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppTheme.emerald.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.charcoal,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.charcoal : AppTheme.textMutedLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF6EE7B7)
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

          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: _filteredRequests.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _filteredRequests.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _filteredRequests[index];
                      return _buildRequestCard(context, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildRequestCard(BuildContext context, _RequestItem item) {
    Color urgencyColor;
    Color urgencyBg;
    switch (item.urgency) {
      case 'Critical':
        urgencyColor = const Color(0xFFDC2626);
        urgencyBg = const Color(0xFFFEE2E2);
        break;
      case 'Urgent':
        urgencyColor = const Color(0xFFD97706);
        urgencyBg = const Color(0xFFFEF3C7);
        break;
      default:
        urgencyColor = const Color(0xFF0369A1);
        urgencyBg = const Color(0xFFE0F2FE);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: _charcoal, size: 22),
                ),
                const SizedBox(width: 14),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.applicant,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: urgencyBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.urgency,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: urgencyColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.submittedAgo,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '\$${item.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Reject',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () => _handleAction(context, item, false),
                  ),
                ),
                Container(
                    width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.check_rounded,
                        size: 16, color: _charcoal),
                    label: const Text(
                      'Approve',
                      style: TextStyle(
                        color: _charcoal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () => _handleAction(context, item, true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(
      BuildContext context, _RequestItem item, bool approved) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          approved ? 'Approve Request?' : 'Reject Request?',
          style: TextStyle(
            color: approved ? _charcoal : const Color(0xFFDC2626),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          approved
              ? 'Confirm approval of "${item.title}" for ${item.applicant} — \$${item.amount.toStringAsFixed(0)}.'
              : 'Confirm rejection of "${item.title}" submitted by ${item.applicant}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  approved ? _charcoal : const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _requests.remove(item));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(approved
                      ? '✅ Approved: ${item.title}'
                      : '❌ Rejected: ${item.title}'),
                  backgroundColor:
                      approved ? const Color(0xFF047857) : const Color(0xFFDC2626),
                ),
              );
            },
            child: Text(approved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF6EE7B7)),
          SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'No pending requests match the selected filter.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _RequestItem {
  final String id;
  final IconData icon;
  final String title;
  final String applicant;
  final double amount;
  final String category;
  final String urgency;
  final String submittedAgo;

  const _RequestItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.applicant,
    required this.amount,
    required this.category,
    required this.urgency,
    required this.submittedAgo,
  });
}
