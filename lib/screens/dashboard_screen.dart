import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'add_donation_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToRecords;
  const DashboardScreen({Key? key, required this.onNavigateToRecords}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = DonationStorageService();

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = _storage.getTotalGivenThisMonth();
    final allTimeTotal = _storage.getTotalGivenAllTime();
    final goal = _storage.monthlyGivingGoal;
    final goalProgress = (monthlyTotal / goal).clamp(0.0, 1.0);
    final breakdown = _storage.getCategoryBreakdown();
    final recentDonations = _storage.allDonations.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sadaqah & Giving'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.textMuted),
            onPressed: widget.onNavigateToRecords,
            tooltip: 'View All Records',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── MONTHLY GOAL & TOTAL CARD ──
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryEmerald.withAlpha(75),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'THIS MONTH’S GIVING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF99F6E4),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(goalProgress * 100).toInt()}% of Goal',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$${monthlyTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: goalProgress,
                      minHeight: 8,
                      backgroundColor: Colors.black26,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Goal: \$${goal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFCCFBF1)),
                      ),
                      Text(
                        'Lifetime: \$${allTimeTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── CATEGORY BREAKDOWN ──
            const Text(
              'Giving by Cause',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textLight),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: breakdown.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No donations recorded yet.', style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    )
                  : Column(
                      children: breakdown.entries.map((e) {
                        final maxVal = breakdown.values.reduce((a, b) => a > b ? a : b);
                        final ratio = maxVal > 0 ? (e.value / maxVal) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.key.displayName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                                  ),
                                  Text(
                                    '\$${e.value.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryEmeraldLight),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFF1E293B),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryEmeraldLight),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 28),

            // ── RECENT DONATIONS STREAM ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Contributions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textLight),
                ),
                TextButton(
                  onPressed: widget.onNavigateToRecords,
                  child: const Text('See All', style: TextStyle(color: AppTheme.primaryEmeraldLight, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...recentDonations.map((d) => _buildDonationCard(d)),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDonationScreen()),
          );
          if (result == true) {
            setState(() {});
          }
        },
        backgroundColor: AppTheme.primaryEmerald,
        icon: const Icon(Icons.favorite, color: Colors.white),
        label: const Text('Log Sadaqah', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildDonationCard(Donation d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.volunteer_activism, color: AppTheme.primaryEmeraldLight, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.recipient,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textLight),
                ),
                const SizedBox(height: 3),
                Text(
                  '${d.category.displayName} • ${d.date.month}/${d.date.day}/${d.date.year}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '\$${d.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryEmeraldLight),
          ),
        ],
      ),
    );
  }
}
