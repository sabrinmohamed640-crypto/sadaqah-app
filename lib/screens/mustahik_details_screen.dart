import 'package:flutter/material.dart';
import '../models/mustahik.dart';
import '../utils/theme.dart';
import 'donation_details_screen.dart';

enum PaymentMethod { premierWallet, evcHormuud }

/// Detailed view for a single Mustahik beneficiary
/// Shows full description, stats, and donation options
class MustahikDetailsScreen extends StatefulWidget {
  final Mustahik mustahik;

  const MustahikDetailsScreen({
    super.key,
    required this.mustahik,
  });

  @override
  State<MustahikDetailsScreen> createState() =>
      _MustahikDetailsScreenState();
}

class _MustahikDetailsScreenState extends State<MustahikDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Avatar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.charcoal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.mustahik.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                color: AppTheme.charcoal,
                child: Stack(
                  children: [
                    // Gradient Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.charcoal,
                            AppTheme.charcoal.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    // Avatar
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.gold.withValues(alpha: 0.2),
                          border: Border.all(
                            color: AppTheme.gold,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Stats Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: _buildStatsGrid(),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      height: 1,
                      color: AppTheme.textMutedLight.withValues(alpha: 0.2),
                    ),
                  ),

                  // Description Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildDescriptionSection(),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      height: 1,
                      color: AppTheme.textMutedLight.withValues(alpha: 0.2),
                    ),
                  ),

                  // Contact Information
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildContactSection(),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      height: 1,
                      color: AppTheme.textMutedLight.withValues(alpha: 0.2),
                    ),
                  ),

                  // Donation Button
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: _buildDonationSection(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a stats grid showing category, monthly income, and status
  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.category_rounded,
            label: 'Category',
            value: widget.mustahik.category,
            color: AppTheme.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_down_rounded,
            label: 'Monthly Income',
            value: '\$${widget.mustahik.monthlyIncome.toStringAsFixed(2)}',
            color: AppTheme.emerald,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_rounded,
            label: 'Status',
            value: widget.mustahik.status,
            color: widget.mustahik.status == 'Verified'
                ? AppTheme.emerald
                : AppTheme.textMutedLight,
          ),
        ),
      ],
    );
  }

  /// Individual stat card
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.charcoal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Builds the full description section
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoal,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.lightBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textMutedLight.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Text(
            widget.mustahik.description ??
                'No additional description provided.',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds contact information section
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoal,
              ),
        ),
        const SizedBox(height: 12),
        _buildContactItem(
          icon: Icons.email_rounded,
          label: 'Email',
          value: widget.mustahik.email,
        ),
        const SizedBox(height: 10),
        if (widget.mustahik.phoneNumber != null)
          _buildContactItem(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: widget.mustahik.phoneNumber!,
          ),
        const SizedBox(height: 10),
        _buildContactItem(
          icon: Icons.calendar_today_rounded,
          label: 'Registered',
          value:
              '${widget.mustahik.registeredAt.day}/${widget.mustahik.registeredAt.month}/${widget.mustahik.registeredAt.year}',
        ),
      ],
    );
  }

  /// Individual contact item
  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.charcoal.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMutedLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the donation button section
  Widget _buildDonationSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Make a Difference',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoal,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your generous contribution will directly support this beneficiary.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _showDonationOptions(context),
            icon: const Icon(Icons.favorite_rounded),
            label: const Text('Donate to This Case'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.charcoal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  /// Shows donation type selection dialog
  void _showDonationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Donation Type',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDonationTypeButton(
              context,
              icon: Icons.favorite_rounded,
              title: 'Zakat',
              subtitle: 'Obligatory charity (2.5% of wealth)',
              onTap: () {
                Navigator.pop(context);
                _navigateToDonation(context, 'Zakat');
              },
            ),
            const SizedBox(height: 12),
            _buildDonationTypeButton(
              context,
              icon: Icons.favorite_border_rounded,
              title: 'Sadaqah',
              subtitle: 'Voluntary charity',
              onTap: () {
                Navigator.pop(context);
                _navigateToDonation(context, 'Sadaqah');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Individual donation type button in modal
  Widget _buildDonationTypeButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.charcoal.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppTheme.charcoal),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded,
                color: AppTheme.charcoal.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  /// Navigate to donation screen with service name and optional campaign
  void _navigateToDonation(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonationDetailsScreen(
          serviceName: type,
          campaign: null, // Direct donation to beneficiary, not campaign
        ),
      ),
    );
  }
}
