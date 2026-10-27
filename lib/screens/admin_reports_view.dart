import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AdminReportsView extends StatelessWidget {
  const AdminReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final double bottomPad =
        MediaQuery.of(context).padding.bottom + 70 + 24;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Consolidated Funds Card
            _buildReportCard(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL CONSOLIDATED FUNDS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                          color: AppTheme.textMutedLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '\$4,280,450.00',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.trending_up, color: AppTheme.emerald, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '+12.4% vs last month',
                          style: TextStyle(
                            color: AppTheme.emerald,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Grid of 4 funds (2x2 layout)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildFundGridItem('Zakat', '\$3,120,000', const Color(0xFFEFF6FF), const Color(0xFF1E40AF)),
                        _buildFundGridItem('Sadaqah', '\$890,450', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
                        _buildFundGridItem('Waqf', '\$270,000', const Color(0xFFEFF6FF), const Color(0xFF1E40AF)),
                        _buildFundGridItem('Emergency', '\$110,000', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Funds Disbursed Card (Dark Green)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Funds Disbursed',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Icon(Icons.volunteer_activism_outlined, color: Colors.white.withValues(alpha: 0.6), size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '\$2,845,000.00',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supporting 12,450 verified families across 14 regions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '68% of annual target reached',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            Text(
                              'Target: \$4.1M',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.68,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // View Disbursement Log Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: AppTheme.charcoal,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Downloading complete distribution logs...'),
                            backgroundColor: Color(0xFF047857),
                          ),
                        );
                      },
                      child: const Text(
                        'View Disbursement Log',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fund Distribution Card (Donut Chart)
            _buildReportCard(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fund Distribution',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        // Dropdown simulation
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Text('This Quarter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 12, color: Color(0xFF475569)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Donut graph
                    Center(
                      child: SizedBox(
                        width: 160,
                        height: 160,
                        child: CustomPaint(
                          painter: DonutChartPainter(),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'RATIO',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '3:1',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Legend
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.charcoal, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Zakat (75%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    Text('Obligatory Alms', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF78350F), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sadaqah (25%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    Text('Voluntary Charity', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Donation Trends Card (Bar chart representation)
            _buildReportCard(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Donation Trends',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        // Chart type selector toggle buttons
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.bar_chart, size: 16, color: AppTheme.charcoal),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.show_chart, size: 16, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48), // extra spacer to fit tooltip
                    
                    // The Bar Graph widget
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final barWidth = width / 11;
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildBarChartColumn('JAN', 60, barWidth, false),
                            _buildBarChartColumn('FEB', 85, barWidth, false),
                            _buildBarChartColumn('MAR', 115, barWidth, false),
                            _buildBarChartColumn('APR', 90, barWidth, false),
                            _buildBarChartColumn('MAY', 140, barWidth, true), // May is highlighted
                            _buildBarChartColumn('JUN', 105, barWidth, false),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recent Large Contributions Card (Table)
            _buildReportCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Large\nContributions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.charcoal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Exporting records to large_contributions.csv'),
                                backgroundColor: Color(0xFF047857),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download, size: 14),
                          label: const Text('Download CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  
                  // Table Row Columns
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: const Color(0xFFF8FAFC),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('DONOR NAME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('FUND TYPE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('METHOD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  ),
                  
                  // Table Rows data
                  _buildContributionRow('Ahmed Khan', 'AK', 'Zakat al-Mal', 'Bank Transfer', Icons.account_balance, const Color(0xFFFDE68A)),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildContributionRow('Sara Jameel', 'SJ', 'Sadaqah Jariyah', 'Visa **** 4492', Icons.credit_card, const Color(0xFFA7F3D0)),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildContributionRow('Fatima Al-Sayed', 'FA', 'Emergency Relief', 'Apple Pay', Icons.phone_android, const Color(0xFFFECDD3)),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildContributionRow('Omar Mukhtar', 'OM', 'Waqf Investment', 'Bank Transfer', Icons.account_balance, const Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    ), // SingleChildScrollView
    ); // SafeArea
  }

  // Helper Card Builder
  Widget _buildReportCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  // Helper for Fund breakdown item
  Widget _buildFundGridItem(String name, String value, Color bg, Color textThemeColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: TextStyle(fontSize: 11, color: textThemeColor.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textThemeColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Custom Bar Chart Column with Tooltip
  Widget _buildBarChartColumn(String month, double height, double barWidth, bool isHighlighted) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Bar background slot / Bar
            Container(
              width: barWidth,
              height: height,
              decoration: BoxDecoration(
                color: isHighlighted ? AppTheme.charcoal : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Tooltip bubble on top of highlighted May bar
            if (isHighlighted)
              Positioned(
                top: -38,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '\$220k',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Small arrow pointing down
                    CustomPaint(
                      size: const Size(6, 4),
                      painter: TooltipArrowPainter(),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          month,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? AppTheme.charcoal : AppTheme.textMutedLight,
          ),
        ),
      ],
    );
  }

  // Helper for contribution row in list
  Widget _buildContributionRow(
    String name,
    String initials,
    String type,
    String method,
    IconData methodIcon,
    Color avatarBg,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Name / Avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: avatarBg,
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Fund Type
          Expanded(
            flex: 2,
            child: Text(
              type,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ),
          // Method
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(methodIcon, size: 14, color: const Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    method,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Donut Chart Custom Painter
class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paintZakat = Paint()
      ..color = const Color(0xFF064E3B) // Dark Green (75%)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final paintSadaqah = Paint()
      ..color = const Color(0xFF78350F) // Brown (25%)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    // Draw Zakat Arc (75%, from -90 degrees to 180 degrees)
    canvas.drawArc(rect, -math.pi / 2, 1.5 * math.pi, false, paintZakat);

    // Draw Sadaqah Arc (25%, from 180 degrees to 270 degrees)
    canvas.drawArc(rect, math.pi, math.pi / 2, false, paintSadaqah);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter to draw the small down-pointing triangle under the bar tooltip
class TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
