import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../models/donation.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../main.dart' show firebaseInitialized;
import 'services_screen.dart';
import 'donation_details_screen.dart';
import 'login_screen.dart';
import 'mustahik_list_screen.dart';
import 'quick_pay_screen.dart';
import 'request_aid_screen.dart';
import '../widgets/zakat_calculator_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final DatabaseService _db = DatabaseService();

  // ── List-entrance animation ────────────────────────────────────────────────
  late AnimationController _listAnimController;
  final List<Animation<double>> _tileOpacities = [];
  final List<Animation<Offset>> _tileSlides = [];
  List<dynamic> _lastDonations = [];

  void _scheduleListAnimation(List<dynamic> donations) {
    if (donations == _lastDonations) return;
    _lastDonations = donations;
    _tileOpacities.clear();
    _tileSlides.clear();
    _listAnimController.stop();
    _listAnimController.reset();
    final total = donations.length;
    for (int i = 0; i < total; i++) {
      final start = (i / total) * 0.6;
      final end = start + 0.4;
      _tileOpacities.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listAnimController,
            curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
          ),
        ),
      );
      _tileSlides.add(
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _listAnimController,
            curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
          ),
        ),
      );
    }
    _listAnimController.forward();
  }

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot> _getUserStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
    }
    return const Stream.empty();
  }

  String? get _currentDonorId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final showAppBar = _currentIndex != 3;
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(context.loc.translate('app_name')),
                  StreamBuilder<DocumentSnapshot>(
                    stream: firebaseInitialized
                        ? _getUserStream()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      final greeting = getGreeting(context, hour: DateTime.now().hour);
                      String name = 'Ahmad';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        final String fullName = data?['name'] ?? 'Ahmad';
                        name = fullName.split(' ')[0];
                      }
                      final String subtitleText;
                      if (_currentIndex == 1) {
                        subtitleText = context.loc.translate('subtitle_waqf');
                      } else if (_currentIndex == 2) {
                        subtitleText = context.loc.translate('subtitle_opportunities');
                      } else if (_currentIndex == 4) {
                        subtitleText = context.loc.translate('subtitle_more');
                      } else {
                        subtitleText = '$greeting, $name';
                      }
                      return Text(
                        subtitleText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: AppTheme.textSecondary,
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.loc.translate('notifications_coming_soon'))),
                    );
                  },
                ),
              ],
            )
          : null,
      drawer: showAppBar ? _buildDrawer() : null,
      body: SafeArea(
        bottom: false,
        child: _MobileViewport(
          child: _getScreenBody(_currentIndex),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }



  Widget _getScreenBody(int index) {
    switch (index) {
      case 1:
        return _buildWaqfScreen();
      case 2:
        return _buildOpportunitiesScreen();
      case 3:
        return const ServicesScreen();
      case 4:
        return _buildMoreScreen();
      case 0:
      default:
        return _buildDashboardBody();
    }
  }

  // ═══════════════════════════════════════════════
  //  DASHBOARD BODY — FULLY DATA-BOUND
  // ═══════════════════════════════════════════════

  Widget _buildDashboardBody() {
    final loc = context.loc;
    return SingleChildScrollView(
      child: Padding(
        padding: AppConstants.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerseCard(),
            const SizedBox(height: AppConstants.spacingLg),

            Text(
              loc.translate('contribution_overview'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            _buildOverviewCard(),
            const SizedBox(height: AppConstants.spacingLg),

            Text(
              loc.translate('quick_actions'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            _buildQuickActions(context),
            const SizedBox(height: AppConstants.spacingLg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    loc.translate('recent_transactions'),
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showTransactionHistoryDialog();
                  },
                  child: Text(loc.translate('view_all'), style: const TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  DRAWER
  // ═══════════════════════════════════════════════

  Widget _buildDrawer() {
    final loc = context.loc;
    return Drawer(
      backgroundColor: AppTheme.surfaceColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: firebaseInitialized
                ? _getUserStream()
                : const Stream.empty(),
            builder: (context, snapshot) {
              String name = loc.language == AppLanguage.ar ? 'أحمد عبد الله' : 'Ahmad Abdullah';
              String email = 'ahmad.abdullah@example.com';
              String initials = 'AA';

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                name = data?['name'] ?? name;
                email = data?['email'] ?? email;
                if (name.isNotEmpty) {
                  final parts = name.trim().split(' ');
                  if (parts.length >= 2) {
                    initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                  } else {
                    initials = name[0].toUpperCase();
                  }
                }
              }

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceLightColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                accountName: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    initials,
                    style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: AppTheme.primaryColor),
            title: Text(loc.translate('drawer_dashboard')),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.calculate_outlined, color: AppTheme.primaryColor),
            title: Text(loc.translate('drawer_zakat_calculator')),
            onTap: () {
              Navigator.pop(context);
              showZakatCalculatorDialog(context, databaseService: _db);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: AppTheme.primaryColor),
            title: Text(loc.translate('drawer_make_donation')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DonationDetailsScreen(
                    serviceName: '${loc.translate('quick_pay')} / ${loc.translate('type_sadaqah')}',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppTheme.primaryColor),
            title: Text(loc.translate('drawer_transaction_history')),
            onTap: () {
              Navigator.pop(context);
              _showTransactionHistoryDialog();
            },
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
            title: Text(loc.translate('drawer_profile')),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppTheme.primaryColor),
            title: Text(loc.translate('drawer_settings')),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  VERSE CARD
  // ═══════════════════════════════════════════════

  Widget _buildVerseCard() {
    final loc = context.loc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryDark.withValues(alpha: 0.8),
            AppTheme.surfaceColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('charity_in_islam'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('verse_text'),
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('verse_ref'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  OVERVIEW CARD — NOW WITH STREAMBUILDERS
  // ═══════════════════════════════════════════════

  Widget _buildOverviewCard() {
    final loc = context.loc;
    return Column(
      children: [
        // Zakat Total — LIVE from Firestore
        StreamBuilder<double>(
          stream: firebaseInitialized && _currentDonorId != null
              ? _db.getZakatTotalStream(donorId: _currentDonorId)
              : Stream.value(0.0),
          builder: (context, snapshot) {
            final total = snapshot.data ?? 0.0;
            return _buildOverviewStatCard(
              title: loc.translate('zakat_paid'),
              amount: '\$${total.toStringAsFixed(2)}',
              icon: Icons.payments_outlined,
              color: AppTheme.primaryColor,
              subtitle: loc.translate('zakat_paid_subtitle'),
            );
          },
        ),
        const SizedBox(height: 10),
        // Sadaqah Total — LIVE from Firestore
        StreamBuilder<double>(
          stream: firebaseInitialized && _currentDonorId != null
              ? _db.getSadaqahTotalStream(donorId: _currentDonorId)
              : Stream.value(0.0),
          builder: (context, snapshot) {
            final total = snapshot.data ?? 0.0;
            return _buildOverviewStatCard(
              title: loc.translate('sadaqah_paid'),
              amount: '\$${total.toStringAsFixed(2)}',
              icon: Icons.favorite_outline,
              color: AppTheme.accentColor,
              subtitle: loc.translate('sadaqah_paid_subtitle'),
            );
          },
        ),
        const SizedBox(height: 10),
        // Reminder banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.accentColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.translate('next_zakat_remind'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewStatCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  QUICK ACTIONS — NOW FUNCTIONAL
  // ═══════════════════════════════════════════════

  Widget _buildQuickActions(BuildContext context) {
    final loc = context.loc;
    final List<Map<String, dynamic>> actions = [
      {
        'title': loc.translate('calculate_zakat'),
        'icon': Icons.calculate_outlined,
        'color': AppTheme.primaryColor,
        'description': loc.translate('calculate_zakat_desc'),
        'onTap': () => showZakatCalculatorDialog(context, databaseService: _db),
      },
      {
        'title': loc.translate('quick_pay'),
        'icon': Icons.flash_on_outlined,
        'color': AppTheme.accentColor,
        'description': loc.translate('quick_pay_desc'),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QuickPayScreen(),
            ),
          );
        },
      },
      {
        'title': loc.translate('mustahik_list'),
        'icon': Icons.people_outline,
        'color': Colors.blueAccent,
        'description': loc.translate('mustahik_list_desc'),
        'onTap': () => _showMustahikListDialog(),
      },
      {
        'title': loc.translate('request_aid'),
        'icon': Icons.volunteer_activism_outlined,
        'color': Colors.purpleAccent,
        'description': loc.translate('request_aid_desc'),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RequestAidScreen(),
            ),
          );
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: action['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: (action['color'] as Color).withValues(alpha: 0.12),
                  radius: 16,
                  child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  action['title'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  action['description'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  //  TRANSACTION LIST — LIVE STREAMBUILDER
  // ═══════════════════════════════════════════════

  Widget _buildTransactionList() {
    final loc = context.loc;

    if (!firebaseInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text(
            loc.translate('firebase_offline_msg'),
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    if (_currentDonorId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text(
            loc.translate('sign_in_for_transactions'),
            style: const TextStyle(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return StreamBuilder<List<Donation>>(
      stream: _db.getRecentDonationsStream(limit: 10, donorId: _currentDonorId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final donations = snapshot.data ?? [];

        if (donations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    loc.translate('no_transactions_yet'),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.translate('make_first_donation'),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        // Trigger staggered entrance animation whenever the data changes.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scheduleListAnimation(donations),
        );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: donations.length,
          itemBuilder: (context, index) {
            final donation = donations[index];
            final tile = _buildTransactionTile(donation, loc);
            if (index < _tileOpacities.length) {
              return FadeTransition(
                opacity: _tileOpacities[index],
                child: SlideTransition(
                  position: _tileSlides[index],
                  child: tile,
                ),
              );
            }
            return tile;
          },
        );
      },
    );
  }

  Widget _buildTransactionTile(Donation donation, AppLocalization loc) {
    final isZakat = donation.type == 'Zakat';

    final String displayNotes;
    if (donation.notes == 'Zakat Al-Mal (Wealth)') {
      displayNotes = loc.translate('zakat_notes');
    } else if (donation.notes == 'Friday Sadaqah for Orphanage') {
      displayNotes = loc.translate('sadaqah_notes');
    } else if (donation.notes == 'Zakat on Savings') {
      displayNotes = loc.translate('savings_zakat_notes');
    } else {
      displayNotes = donation.notes != null
          ? donation.notes!
          : (isZakat ? loc.translate('type_zakat') : loc.translate('type_sadaqah'));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isZakat ? AppTheme.primaryColor : AppTheme.accentColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isZakat ? Icons.payments_outlined : Icons.favorite_outline,
              color: isZakat ? AppTheme.primaryColor : AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayNotes,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${donation.paymentMethod} • ${_formatDate(donation.timestamp)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${donation.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isZakat ? AppTheme.primaryColor : AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(donation.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  donation.status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(donation.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppTheme.primaryColor;
      case 'Pending':
        return AppTheme.accentColor;
      case 'Failed':
      default:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final loc = context.loc;

    if (difference.inDays == 0) {
      return loc.translate('today');
    } else if (difference.inDays == 1) {
      return loc.translate('yesterday');
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // ═══════════════════════════════════════════════
  //  MUSTAHIK LIST NAVIGATION
  // ═══════════════════════════════════════════════

  void _showMustahikListDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MustahikListScreen(),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TRANSACTION HISTORY DIALOG (Drawer)
  // ═══════════════════════════════════════════════

  void _showTransactionHistoryDialog() {
    final loc = context.loc;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.history, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Expanded(child: Text(loc.translate('drawer_transaction_history'), style: const TextStyle(fontSize: 18))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: StreamBuilder<List<Donation>>(
              stream: firebaseInitialized && _currentDonorId != null
                  ? _db.getRecentDonationsStream(limit: 50, donorId: _currentDonorId)
                  : Stream.value([]),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.error)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                }
                final donations = snapshot.data ?? [];
                if (donations.isEmpty) {
                  return Center(
                    child: Text(loc.translate('no_transactions_yet'), style: const TextStyle(color: AppTheme.textMuted)),
                  );
                }
                return ListView.builder(
                  itemCount: donations.length,
                  itemBuilder: (context, index) => _buildTransactionTile(donations[index], loc),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(loc.translate('close_btn'), style: const TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  //  BOTTOM NAV
  // ═══════════════════════════════════════════════

  Widget _buildBottomNav() {
    final loc = context.loc;
    return NavigationBar(
      selectedIndex: _currentIndex,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: loc.translate('nav_home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.account_balance_outlined),
          selectedIcon: const Icon(Icons.account_balance),
          label: loc.translate('nav_waqf'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.explore_outlined),
          selectedIcon: const Icon(Icons.explore),
          label: loc.translate('nav_opportunities'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined),
          selectedIcon: const Icon(Icons.grid_view),
          label: loc.translate('nav_services'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.more_horiz_outlined),
          selectedIcon: const Icon(Icons.more_horiz),
          label: loc.translate('nav_more'),
        ),
      ],
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  // ═══════════════════════════════════════════════
  //  WAQF SCREEN (already using StreamBuilder)
  // ═══════════════════════════════════════════════

  Widget _buildWaqfScreen() {
    final loc = context.loc;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: AppConstants.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLightColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('waqf_main_title'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.translate('waqf_main_desc'),
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Text(
              loc.translate('active_waqf_projects'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            StreamBuilder<QuerySnapshot>(
              stream: firebaseInitialized
                  ? FirebaseFirestore.instance.collection('projects').snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Error loading projects: ${snapshot.error}',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: Text(
                        loc.language == AppLanguage.en
                            ? 'No active projects found.'
                            : 'لم يتم العثور على مشاريع نشطة.',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};

                    final String title = loc.language == AppLanguage.en
                        ? (data['title_en'] ?? data['title'] ?? '')
                        : (data['title_ar'] ?? data['title'] ?? '');
                    final String subtitle = loc.language == AppLanguage.en
                        ? (data['subtitle_en'] ?? data['subtitle'] ?? '')
                        : (data['subtitle_ar'] ?? data['subtitle'] ?? '');
                    final String desc = loc.language == AppLanguage.en
                        ? (data['desc_en'] ?? data['desc'] ?? '')
                        : (data['desc_ar'] ?? data['desc'] ?? '');

                    final double raised = AppConstants.parseDouble(data['raised']);
                    final double target = AppConstants.parseDouble(data['target'] ?? 1.0);
                    final double progress = target > 0 ? raised / target : 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DonationDetailsScreen(
                                serviceName: title,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Hero(
                                        tag: 'project-title-$title',
                                        child: Material(
                                          type: MaterialType.transparency,
                                          child: Text(
                                            title,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        subtitle,
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      loc.translate('ongoing_charity'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                desc,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${loc.translate('raised')}\$${raised.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${loc.translate('target')}\$${target.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  OPPORTUNITIES SCREEN
  // ═══════════════════════════════════════════════

  Widget _buildOpportunitiesScreen() {
    final loc = context.loc;
    final List<Map<String, dynamic>> items = [
      {
        'title': loc.translate('opp_food_title'),
        'subtitle': loc.language == AppLanguage.en ? 'Urgent Food Aid Campaign' : 'إغاثة عاجلة: سلات غذائية',
        'urgency': loc.translate('urgency_critical'),
        'urgencyColor': Theme.of(context).colorScheme.error,
        'desc': loc.translate('opp_food_desc'),
      },
      {
        'title': loc.translate('opp_orphan_title'),
        'subtitle': loc.language == AppLanguage.en ? 'Sponsor Orphan Students' : 'كفالة أيتام التعليمية',
        'urgency': loc.translate('urgency_high'),
        'urgencyColor': AppTheme.accentColor,
        'desc': loc.translate('opp_orphan_desc'),
      },
      {
        'title': loc.translate('opp_dialysis_title'),
        'subtitle': loc.language == AppLanguage.en ? 'Dialysis Machines Fund' : 'توفير أجهزة غسيل كلى لمستشفى خيري',
        'urgency': loc.translate('urgency_medium'),
        'urgencyColor': Colors.blueAccent,
        'desc': loc.translate('opp_dialysis_desc'),
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: AppConstants.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('urgent_opportunities'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            ...items.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (item['urgencyColor'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['urgency'],
                              style: TextStyle(fontSize: 10, color: item['urgencyColor'] as Color, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Icon(Icons.share_outlined, size: 18, color: AppTheme.textMuted),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['title'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item['subtitle'],
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['desc'],
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DonationDetailsScreen(
                                  serviceName: '${loc.translate('donate_now')} / ${item['title']}',
                                ),
                              ),
                            );
                          },
                          child: Text(loc.translate('donate_now')),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  MORE SCREEN
  // ═══════════════════════════════════════════════

  Widget _buildMoreScreen() {
    final loc = context.loc;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: AppConstants.screenPadding,
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: firebaseInitialized
                  ? _getUserStream()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                String name = loc.language == AppLanguage.ar ? 'أحمد عبد الله' : 'Ahmad Abdullah';
                String email = 'ahmad.abdullah@example.com';
                String initials = 'AA';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  name = data?['name'] ?? name;
                  email = data?['email'] ?? email;
                  if (name.isNotEmpty) {
                    final parts = name.trim().split(' ');
                    if (parts.length >= 2) {
                      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                    } else {
                      initials = name[0].toUpperCase();
                    }
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          initials,
                          style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              email,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.translate('muzakki_account'),
                              style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppConstants.spacingLg),
            
            _buildMoreOptionTile(
              icon: Icons.person_outline,
              title: loc.translate('edit_profile'),
              subtitle: loc.translate('edit_profile_sub'),
            ),
            _buildMoreOptionTile(
              icon: Icons.history_edu_outlined,
              title: loc.translate('zakat_history'),
              subtitle: loc.translate('zakat_history_sub'),
              onTap: () {
                _showZakatHistoryDialog();
              },
            ),
            _buildMoreOptionTile(
              icon: Icons.assignment_outlined,
              title: loc.translate('charity_reports'),
              subtitle: loc.translate('charity_reports_sub'),
            ),
            _buildMoreOptionTile(
              icon: Icons.language_outlined,
              title: loc.translate('change_language'),
              subtitle: loc.translate('change_language_sub'),
              onTap: () {
                context.locManager.toggleLanguage();
              },
            ),
            _buildMoreOptionTile(
              icon: Icons.info_outline,
              title: loc.translate('about_app'),
              subtitle: loc.translate('about_app_sub'),
            ),
            _buildMoreOptionTile(
              icon: Icons.headset_mic_outlined,
              title: loc.translate('support'),
              subtitle: loc.translate('support_sub'),
            ),
            
            const SizedBox(height: AppConstants.spacingLg),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.translate('logging_out'))),
                  );
                  try {
                    await AuthService().signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    debugPrint('Sign out error: $e');
                  }
                },
                child: Text(loc.translate('sign_out')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: AppTheme.surfaceColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primaryColor),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          onTap: onTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${context.loc.translate('clicked_on')} "$title"')),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  ZAKAT HISTORY DIALOG (More)
  // ═══════════════════════════════════════════════

  void _showZakatHistoryDialog() {
    final loc = context.loc;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.history_edu_outlined, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Expanded(child: Text(loc.translate('zakat_history'), style: const TextStyle(fontSize: 18))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: StreamBuilder<QuerySnapshot>(
              stream: firebaseInitialized && _currentDonorId != null
                  ? FirebaseFirestore.instance
                      .collection('zakat_calculations')
                      .where('userId', isEqualTo: _currentDonorId)
                      .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.error)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No historical calculations found.', style: TextStyle(color: AppTheme.textMuted)),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final double due = (data['zakatDue'] ?? 0.0).toDouble();
                    final double gold = (data['goldValue'] ?? 0.0).toDouble();
                    final double cash = (data['cashSavings'] ?? 0.0).toDouble();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${loc.translate('total_zakat_due')}:',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              Text(
                                '\$${due.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                          Divider(color: Theme.of(context).dividerColor),
                          Text('Gold: \$${gold.toStringAsFixed(0)} | Cash: \$${cash.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(loc.translate('close_btn'), style: const TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        );
      },
    );
  }
}

/// Constrains content to a mobile-phone width on wide screens (e.g. web preview).
class _MobileViewport extends StatelessWidget {
  const _MobileViewport({required this.child});

  final Widget child;

  static const double _maxWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _maxWidth) {
          return child;
        }
        return Center(
          child: Container(
            width: _maxWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.6),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        );
      },
    );
  }
}
