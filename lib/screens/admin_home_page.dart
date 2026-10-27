import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/mustahik.dart';
import '../utils/app_roles.dart';
import '../utils/theme.dart';
import 'access_denied_page.dart';
import 'admin_dashboard_view.dart';
import 'admin_beneficiaries_view.dart';
import 'advanced_beneficiary_management.dart';
import 'admin_reports_view.dart';
import 'admin_campaigns_view.dart';
import 'admin_aid_requests_view.dart';
import 'admin_orphan_screen.dart';
import 'login_screen.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();

  bool _isLoading = true;
  bool _isAdmin = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('🔐 [AdminHomePage] Checking admin access for UID: ${user?.uid ?? "NULL"}');
      
      if (user == null) {
        debugPrint('❌ [AdminHomePage] No user logged in');
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
        return;
      }

      final role = await _authService.getUserRole(user.uid);
      debugPrint('📋 [AdminHomePage] Raw role from DB: "${role ?? "NULL"}"');
      
      final roleTrimmed = (role ?? '').trim(); // CRITICAL: Trim whitespace
      debugPrint('✂️  [AdminHomePage] Trimmed role: "$roleTrimmed"');
      
      final isAdminRole = AppRoles.isAdminRole(roleTrimmed);
      debugPrint('🔑 [AdminHomePage] isAdminRole result: $isAdminRole');
      
      if (isAdminRole) {
        debugPrint('✅ [AdminHomePage] Admin access GRANTED - showing admin portal');
        setState(() {
          _isAdmin = true;
          _isLoading = false;
        });
      } else {
        debugPrint('🚫 [AdminHomePage] Admin access DENIED - showing access denied page');
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AdminHomePage] Error checking admin status: $e');
      debugPrint('   StackTrace: $stackTrace');
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
    }
  }

  void _showAddNewBeneficiaryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final incomeController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Family Support';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        const Color darkGreen = Color(0xFF064E3B);
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Add New Beneficiary',
                style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        decoration: InputDecoration(
                          labelText: 'Applicant Name',
                          labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 12),
                      // Income
                      TextFormField(
                        controller: incomeController,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monthly Income (\$)',
                          labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        validator: (value) => (value == null || double.tryParse(value) == null) ? 'Please enter a valid amount' : null,
                      ),
                      const SizedBox(height: 12),
                      // Category Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: category,
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                            items: ['Family Support', 'Orphan Care', 'Elderly Support', 'Gharimin', 'Fakir', 'Miskin']
                                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setStateDialog(() {
                                  category = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Description
                      TextFormField(
                        controller: descController,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: ' हार्डशिप वर्णन / Details of Need',
                          labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
                   onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newMustahik = Mustahik(
                        id: 'mst_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        email: '${nameController.text.trim().replaceAll(' ', '.').toLowerCase()}@example.com',
                        category: category,
                        monthlyIncome: double.parse(incomeController.text),
                        description: descController.text.trim(),
                        status: 'Pending',
                        registeredAt: DateTime.now(),
                      );
                      await _db.addMustahik(newMustahik);
                      if (!context.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Beneficiary application logged: ${newMustahik.name}'),
                          backgroundColor: AppTheme.emerald,
                        ),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.charcoal),
              const SizedBox(height: 20),
              Text(
                'Verifying administrative privileges...',
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return const AccessDeniedPage(attemptedPath: '/admin/beneficiary-vault');
    }

    // List of screens for index stack
    final List<Widget> views = [
      AdminDashboardView(
        onViewAllRequests: () {
          setState(() {
            _currentIndex = 1; // Go to Beneficiaries tab
          });
        },
        onGenerateReport: () {
          setState(() {
            _currentIndex = 5; // Go to Reports tab (updated index)
          });
        },
      ),
      const AdminBeneficiariesView(),
      const AdvancedBeneficiaryManagement(),
      const AdminCampaignsView(),
      const AdminAidRequestsView(), // New Aid Requests tab
      const AdminReportsView(),
      const AdminOrphanScreen(), // New Orphan Management tab
    ];

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.lightSurface,
        elevation: 0,
        title: Row(
          children: [
            // Green app symbol
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.volunteer_activism_outlined,
                color: AppTheme.charcoal,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Zakat Admin',
              style: TextStyle(
                color: AppTheme.charcoal,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // Sign Out confirmation button
          IconButton(
            icon: Icon(Icons.logout_outlined, color: Theme.of(context).textTheme.bodySmall?.color),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: Text('Sign Out', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
                  content: Text('Are you sure you want to log out from the Admin Portal?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _authService.signOut();
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text('Sign Out', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.notifications_none, color: Theme.of(context).textTheme.bodySmall?.color),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('No new notifications.'), backgroundColor: Theme.of(context).colorScheme.primary),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: views,
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 2 || _currentIndex == 6)
          ? FloatingActionButton(
              backgroundColor: AppTheme.charcoal,
              foregroundColor: AppTheme.lightSurface,
              shape: const CircleBorder(),
              onPressed: () => _currentIndex == 6
                  ? null // AdminOrphanScreen has its own FAB
                  : _showAddNewBeneficiaryDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Custom Bottom Navigation Bar matching the mockup layout exactly
  Widget _buildBottomNavBar() {
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.lightSurfaceAlt,
          border: Border(
            top: BorderSide(
                color: AppTheme.textMutedLight.withValues(alpha: 0.2), width: 1),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(0, Icons.grid_view_rounded, 'Dashboard'),
              _buildNavBarItem(1, Icons.people_outline, 'Beneficiaries'),
              _buildNavBarItem(2, Icons.manage_accounts_rounded, 'Management'),
              _buildNavBarItem(3, Icons.campaign_rounded, 'Campaigns'),
              _buildNavBarItem(4, Icons.request_quote_rounded, 'Aid Requests'),
              _buildNavBarItem(5, Icons.bar_chart, 'Reports'),
              _buildNavBarItem(6, Icons.child_care_outlined, 'Orphans'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final bool isActive = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.charcoal : AppTheme.textMutedLight,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.charcoal : AppTheme.textMutedLight,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
