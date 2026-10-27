import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import 'donation_details_screen.dart';
import 'campaigns_screen.dart';
import 'orphans_list_screen.dart';

class ServiceItem {
  final String key;
  final String title;
  final String englishTitle;
  final String description;
  final IconData icon;
  final Color iconColor;

  const ServiceItem({
    required this.key,
    required this.title,
    required this.englishTitle,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final List<ServiceItem> _allServices = const [
    ServiceItem(
      key: 'zakat',
      title: 'الزكاة',
      englishTitle: 'Zakat',
      description: 'حساب ودفع الزكاة الواجبة لدعم مستحقيها',
      icon: Icons.payments_outlined,
      iconColor: AppTheme.primaryColor,
    ),
    ServiceItem(
      key: 'periodic',
      title: 'التبرع الدوري',
      englishTitle: 'Periodic Donation',
      description: 'صدقة مستمرة تُقتطع تلقائياً بشكل دوري',
      icon: Icons.autorenew_outlined,
      iconColor: AppTheme.accentColor,
    ),
    ServiceItem(
      key: 'campaigns',
      title: 'الحملات',
      englishTitle: 'Campaigns',
      description: 'المشاركة في حملات الإغاثة والمشاريع الموسمية',
      icon: Icons.campaign_outlined,
      iconColor: Colors.blueAccent,
    ),
    ServiceItem(
      key: 'gift',
      title: 'الهدية',
      englishTitle: 'Charity Gift',
      description: 'إرسال صدقة باسم من تحب كهدية مميزة',
      icon: Icons.card_giftcard_outlined,
      iconColor: Colors.purpleAccent,
    ),
    ServiceItem(
      key: 'ghiras',
      title: 'غراس',
      englishTitle: 'Ghiras (Planting)',
      description: 'مبادرة زراعة الأشجار والوقف البيئي المستدام',
      icon: Icons.park_outlined,
      iconColor: Colors.greenAccent,
    ),
    ServiceItem(
      key: 'udhiyah',
      title: 'الأضاحي',
      englishTitle: 'Udhiyah (Qurban)',
      description: 'حجز وتوزيع الأضاحي والهدي في مواسمها الشرعية',
      icon: Icons.restaurant_outlined,
      iconColor: Colors.orangeAccent,
    ),
    ServiceItem(
      key: 'stock',
      title: 'تطهير الأسهم',
      englishTitle: 'Stock Purification',
      description: 'تطهير الأرباح الاستثمارية وإخراج نسب الشبهات',
      icon: Icons.trending_up_outlined,
      iconColor: Colors.tealAccent,
    ),
    ServiceItem(
      key: 'sms',
      title: 'التبرع بالرسائل',
      englishTitle: 'SMS Donation',
      description: 'التبرع المباشر والسريع عبر الرسائل النصية القصيرة',
      icon: Icons.sms_outlined,
      iconColor: Colors.pinkAccent,
    ),
    ServiceItem(
      key: 'orphan',
      title: 'كفالة اليتيم',
      englishTitle: 'Orphan Sponsorship',
      description: 'رعاية يتيم وتوفير احتياجاته الأساسية بكفالة شهرية',
      icon: Icons.child_care_outlined,
      iconColor: Colors.redAccent,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final query = _searchController.text.toLowerCase();
    
    final filteredServices = query.isEmpty
        ? _allServices
        : _allServices.where((service) {
            final title = loc.translate('service_${service.key}_title').toLowerCase();
            final desc = loc.translate('service_${service.key}_desc').toLowerCase();
            final altTitle = (loc.language == AppLanguage.en ? service.title : service.englishTitle).toLowerCase();
            return title.contains(query) ||
                altTitle.contains(query) ||
                desc.contains(query);
          }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppConstants.spacingMd),
            // Header text
            Text(
              loc.translate('services_title'),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              loc.translate('services_subtitle'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: loc.translate('search_service_hint'),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Services Grid
            Expanded(
              child: filteredServices.isEmpty
                  ? _buildEmptyState(loc)
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = filteredServices[index];
                        return _buildServiceCard(context, service, loc);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalization loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_outlined, size: 60, color: AppTheme.textMuted),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            loc.translate('search_empty'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          TextButton(
            onPressed: () => _searchController.clear(),
            child: Text(loc.translate('show_all_services'), style: const TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceItem service, AppLocalization loc) {
    final title = loc.translate('service_${service.key}_title');
    final altTitle = loc.language == AppLanguage.en ? service.title : service.englishTitle;
    final description = loc.translate('service_${service.key}_desc');

    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.surfaceColor,
      child: InkWell(
        onTap: () {
          _handleServiceTap(context, service, loc);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon Header Container
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: service.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  service.icon,
                  color: service.iconColor,
                  size: 26,
                ),
              ),
              // Titles & Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    altTitle,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleServiceTap(BuildContext context, ServiceItem service, AppLocalization loc) {
    final title = loc.translate('service_${service.key}_title');
    final altTitle = loc.language == AppLanguage.en ? service.title : service.englishTitle;

    // Special handling for campaigns
    if (service.key == 'campaigns') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CampaignsScreen(),
        ),
      );
      return;
    }

    // Special handling for orphan sponsorship
    if (service.key == 'orphan') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OrphansListScreen(),
        ),
      );
      return;
    }

    // For other services, navigate to DonationDetailsScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonationDetailsScreen(
          serviceName: '$title / $altTitle',
        ),
      ),
    );
  }
}

