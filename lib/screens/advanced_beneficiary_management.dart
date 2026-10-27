import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/paginated_query_service.dart';
import '../services/beneficiary_analytics_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';

class AdvancedBeneficiaryManagement extends StatefulWidget {
  const AdvancedBeneficiaryManagement({super.key});

  @override
  State<AdvancedBeneficiaryManagement> createState() =>
      _AdvancedBeneficiaryManagementState();
}

class _AdvancedBeneficiaryManagementState
    extends State<AdvancedBeneficiaryManagement> {
  final PaginatedQueryService _paginationService = PaginatedQueryService();
  final BeneficiaryAnalyticsService _analyticsService =
      BeneficiaryAnalyticsService();
  final NotificationService _notificationService = NotificationService();

  int _currentPage = 1;
  String _sortBy = 'name';
  final bool _sortDesc = false;
  String _filterStatus = '';
  String _filterCategory = '';
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final values = await _paginationService.getDistinctValues(
      'mustahik',
      'category',
    );
    setState(() {
      _categories = values.whereType<String>().toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiary Management'),
        elevation: 0,
        backgroundColor: AppTheme.charcoal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _currentPage = 1),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBeneficiaryDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFiltersSection(),

          // Beneficiaries list
          Expanded(child: _buildBeneficiariesList()),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status filter
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Status'),
                    onSelected: (_) => _showStatusFilterDialog(),
                    selected: _filterStatus.isNotEmpty,
                  ),
                ),
                // Category filter
                if (_categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DropdownButton<String>(
                      value: _filterCategory.isEmpty ? null : _filterCategory,
                      hint: const Text('Category'),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('All Categories'),
                        ),
                        ..._categories.map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterCategory = value ?? '';
                          _currentPage = 1;
                        });
                      },
                    ),
                  ),
                // Sort option
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                      DropdownMenuItem(value: 'status', child: Text('Status')),
                      DropdownMenuItem(
                        value: 'registeredAt',
                        child: Text('Registered'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value ?? 'name';
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiariesList() {
    final filters = <QueryFilter>[];
    if (_filterStatus.isNotEmpty) {
      filters.add(QueryFilter(fieldPath: 'status', isEqualTo: _filterStatus));
    }
    if (_filterCategory.isNotEmpty) {
      filters.add(
        QueryFilter(fieldPath: 'category', isEqualTo: _filterCategory),
      );
    }

    return FutureBuilder(
      future: _paginationService.getPaginatedCollection(
        'mustahik',
        pageSize: 15,
        page: _currentPage,
        filters: filters.isNotEmpty ? filters : null,
        sortBy: QuerySort(fieldPath: _sortBy, descending: _sortDesc),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final state = snapshot.data;
        if (state == null || state.isEmpty) {
          return const Center(child: Text('No beneficiaries found'));
        }

        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final beneficiary = state.items[index];
            return _BeneficiaryCard(
              beneficiary: beneficiary,
              onEdit: () => _showEditBeneficiaryDialog(beneficiary),
              onApprove: () => _approveBeneficiary(beneficiary),
              onReject: () => _rejectBeneficiary(beneficiary),
              onViewAnalytics: () => _showAnalyticsDialog(beneficiary['id']),
            );
          },
        );
      },
    );
  }

  void _showAddBeneficiaryDialog() {
    showDialog(
      context: context,
      builder: (context) => _BeneficiaryFormDialog(
        onSubmit: (data) {
          _saveBeneficiary(data);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditBeneficiaryDialog(Map<String, dynamic> beneficiary) {
    showDialog(
      context: context,
      builder: (context) => _BeneficiaryFormDialog(
        initialData: beneficiary,
        onSubmit: (data) {
          _updateBeneficiary(beneficiary['id'], data);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Status'),
        children: ['Pending', 'Verified', 'Rejected']
            .map(
              (status) => SimpleDialogOption(
                onPressed: () {
                  setState(() => _filterStatus = status);
                  Navigator.pop(context);
                },
                child: Text(status),
              ),
            )
            .toList(),
      ),
    );
  }

  void _showAnalyticsDialog(String beneficiaryId) async {
    final impact = await _analyticsService.getBeneficiaryImpact(beneficiaryId);
    if (!mounted || impact == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beneficiary Impact Analysis'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalyticsRow('Name', impact.beneficiaryName),
              _buildAnalyticsRow(
                'Total Received',
                '\$${impact.amountReceived.toStringAsFixed(2)}',
              ),
              _buildAnalyticsRow('Donations Count', '${impact.donationCount}'),
              _buildAnalyticsRow(
                'Avg Monthly',
                '\$${impact.averageMonthlyFunding.toStringAsFixed(2)}',
              ),
              _buildAnalyticsRow(
                'Monthly Need',
                '\$${impact.estimatedMonthlyNeed.toStringAsFixed(2)}',
              ),
              _buildAnalyticsRow(
                'Status',
                impact.stillInNeed ? 'Still in Need' : 'Needs Met',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _saveBeneficiary(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('mustahik').add(data);
      _notificationService.notifyMilestone(
        title: 'Beneficiary Added',
        message: '${data['name']} has been added as a beneficiary',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beneficiary added successfully')),
      );
      setState(() => _currentPage = 1);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateBeneficiary(String id, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('mustahik')
          .doc(id)
          .update(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beneficiary updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _approveBeneficiary(Map<String, dynamic> beneficiary) async {
    try {
      await FirebaseFirestore.instance
          .collection('mustahik')
          .doc(beneficiary['id'])
          .update({'status': 'Verified'});
      _notificationService.notifyMilestone(
        title: 'Beneficiary Approved',
        message: '${beneficiary['name']} has been verified as a beneficiary',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Beneficiary approved')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectBeneficiary(Map<String, dynamic> beneficiary) async {
    try {
      await FirebaseFirestore.instance
          .collection('mustahik')
          .doc(beneficiary['id'])
          .update({'status': 'Rejected'});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Beneficiary rejected')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

/// Card widget for displaying single beneficiary
/// Bulletproof layout with NO horizontal overflow - uses Wrap for responsive buttons
class _BeneficiaryCard extends StatelessWidget {
  final Map<String, dynamic> beneficiary;
  final VoidCallback onEdit;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewAnalytics;

  const _BeneficiaryCard({
    required this.beneficiary,
    required this.onEdit,
    required this.onApprove,
    required this.onReject,
    required this.onViewAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final status = beneficiary['status'] ?? 'Unknown';
    final statusColor = status == 'Verified'
        ? Colors.green
        : (status == 'Rejected' ? Colors.red : Colors.orange);

    // Use LayoutBuilder to get actual available width and force constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            // Force width to match parent constraints - this is the KEY FIX
            width: constraints.maxWidth,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header section: Name, Category, Status
                _buildHeaderSection(statusColor, status),

                const SizedBox(height: 12),

                // Email section - constrained with ellipsis
                _buildEmailSection(),

                const SizedBox(height: 12),

                // Action buttons - uses Wrap to prevent overflow
                _buildActionButtons(status),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the header with name, category, and status badge
  /// Uses Expanded + proper spacing to prevent overflow
  Widget _buildHeaderSection(Color statusColor, String status) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and Category - takes remaining space
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Beneficiary Name - CRITICAL: ellipsis + maxLines + softWrap
              Text(
                beneficiary['name'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
              const SizedBox(height: 4),
              // Category - CRITICAL: ellipsis + maxLines + softWrap
              Text(
                beneficiary['category'] ?? 'Uncategorized',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Status Badge - shrink-wrapped to content to avoid forcing extra width
        IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the email display section with full width constraint
  Widget _buildEmailSection() {
    return Container(
      width: double.infinity, // CRITICAL: Force full width
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.email, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          // CRITICAL: Expanded to prevent overflow
          Expanded(
            child: Text(
              beneficiary['email'] ?? 'N/A',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds action buttons using Wrap widget to prevent overflow
  /// Wrap automatically moves buttons to next line if they don't fit
  Widget _buildActionButtons(String status) {
    final bool isPending = status == 'Pending';

    return SizedBox(
      width: double.infinity, // CRITICAL: Force full width
      child: Wrap(
        spacing: 8, // Horizontal gap between buttons
        runSpacing: 8, // Vertical gap if buttons wrap to next line
        alignment: WrapAlignment.start,
        runAlignment: WrapAlignment.start,
        children: [
          // Analytics button - always present
          SizedBox(
            width: 100, // Fixed width for consistent sizing
            child: _buildActionButton(
              icon: Icons.analytics,
              label: 'Analytics',
              onPressed: onViewAnalytics,
              isPrimary: false,
            ),
          ),

          if (isPending) ...[
            // Approve button - for pending beneficiaries
            SizedBox(
              width: 100,
              child: _buildActionButton(
                icon: Icons.check_circle,
                label: 'Approve',
                onPressed: onApprove,
                isPrimary: true,
              ),
            ),

            // Reject button - for pending beneficiaries
            SizedBox(
              width: 100,
              child: _buildActionButton(
                icon: Icons.cancel,
                label: 'Reject',
                onPressed: onReject,
                isPrimary: false,
                isDestructive: true,
              ),
            ),
          ] else ...[
            // Edit button - for verified/rejected beneficiaries
            SizedBox(
              width: 100,
              child: _buildActionButton(
                icon: Icons.edit,
                label: 'Edit',
                onPressed: onEdit,
                isPrimary: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a single action button with consistent styling
  /// Simplified - button is now in SizedBox, so no need for constraints
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    final Color buttonColor = isDestructive
        ? Colors.red
        : (isPrimary ? const Color(0xFF064E3B) : Colors.grey[700]!);

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

/// Form dialog for adding/editing beneficiary
class _BeneficiaryFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSubmit;

  /// Constructor without const - function callbacks cannot be const
  /// (const requires all fields to be compile-time constants)
  // ignore: prefer_const_constructors_in_immutables
  _BeneficiaryFormDialog({this.initialData, required this.onSubmit});

  @override
  State<_BeneficiaryFormDialog> createState() => _BeneficiaryFormDialogState();
}

class _BeneficiaryFormDialogState extends State<_BeneficiaryFormDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController monthlyNeedCtrl;
  String selectedCategory = 'Fakir';

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialData?['name'] ?? '');
    emailCtrl = TextEditingController(text: widget.initialData?['email'] ?? '');
    phoneCtrl = TextEditingController(
      text: widget.initialData?['phoneNumber'] ?? '',
    );
    monthlyNeedCtrl = TextEditingController(
      text: (widget.initialData?['monthlyIncome'] ?? '').toString(),
    );
    selectedCategory = widget.initialData?['category'] ?? 'Fakir';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    monthlyNeedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialData == null ? 'Add Beneficiary' : 'Edit Beneficiary',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              items:
                  [
                        'Fakir',
                        'Miskin',
                        'Amil',
                        'Muallaf',
                        'Riqab',
                        'Gharimin',
                        'Fisabilillah',
                        'Ibnu Sabil',
                      ]
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() => selectedCategory = value ?? 'Fakir');
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: monthlyNeedCtrl,
              decoration: const InputDecoration(labelText: 'Monthly Need (\$)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit({
              'name': nameCtrl.text,
              'email': emailCtrl.text,
              'phoneNumber': phoneCtrl.text,
              'category': selectedCategory,
              'monthlyIncome': double.tryParse(monthlyNeedCtrl.text) ?? 0,
              'status': widget.initialData?['status'] ?? 'Pending',
              'registeredAt':
                  widget.initialData?['registeredAt'] ?? Timestamp.now(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
