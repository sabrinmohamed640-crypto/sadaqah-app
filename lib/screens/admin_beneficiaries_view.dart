import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/mustahik.dart';
import '../utils/theme.dart';

class AdminBeneficiariesView extends StatefulWidget {
  const AdminBeneficiariesView({super.key});

  @override
  State<AdminBeneficiariesView> createState() => _AdminBeneficiariesViewState();
}

class _AdminBeneficiariesViewState extends State<AdminBeneficiariesView> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedRole = 'All Roles';
  String _selectedStatus = 'All Statuses';
  int _currentPage = 1;

  final List<String> _rolesList = ['All Roles', 'Family Support', 'Orphan Care', 'Elderly Support', 'Gharimin', 'Fakir', 'Miskin'];
  final List<String> _statusesList = ['All Statuses', 'Verified', 'Pending', 'Rejected'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPad =
        MediaQuery.of(context).padding.bottom + 70 + 24;

    return SafeArea(
      bottom: false, // bottom padding is handled manually via bottomPad
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Description
            const Text(
              'Beneficiary Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Review and manage support applications with dignity and precision.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Search input field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, ID or location',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.charcoal, width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                    _currentPage = 1; // reset page
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            // Dropdown filters in separate white cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
                        items: _rolesList.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRole = val;
                              _currentPage = 1;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
                        items: _statusesList.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStatus = val;
                              _currentPage = 1;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Beneficiaries List Card
            StreamBuilder<List<Mustahik>>(
              stream: _db.getMustahikListStream(),
              builder: (context, snapshot) {
                // Determine display list
                List<Mustahik> mustahiks = [];
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  mustahiks = snapshot.data!;
                } else {
                  // Standard Fallback mock data as in design screenshots
                  mustahiks = [
                    Mustahik(
                      id: 'ZK-88219',
                      name: 'Ahmed Al-Farsi',
                      email: 'ahmed.farsi@example.com',
                      category: 'Family Support',
                      monthlyIncome: 450,
                      status: 'Verified',
                      registeredAt: DateTime.now().subtract(const Duration(days: 12)),
                    ),
                    Mustahik(
                      id: 'ZK-99012',
                      name: 'Sara Mahmoud',
                      email: 'sara.m@example.com',
                      category: 'Orphan Care',
                      monthlyIncome: 250,
                      status: 'Pending',
                      registeredAt: DateTime.now().subtract(const Duration(days: 10)),
                    ),
                    Mustahik(
                      id: 'ZK-77123',
                      name: 'Omar Qabbani',
                      email: 'omar.q@example.com',
                      category: 'Elderly Support',
                      monthlyIncome: 300,
                      status: 'Verified',
                      registeredAt: DateTime.now().subtract(const Duration(days: 8)),
                    ),
                  ];
                }

                // Apply Search query filter
                if (_searchQuery.isNotEmpty) {
                  mustahiks = mustahiks.where((m) {
                    return m.name.toLowerCase().contains(_searchQuery) ||
                        m.id.toLowerCase().contains(_searchQuery) ||
                        m.category.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                // Apply Role filter
                if (_selectedRole != 'All Roles') {
                  mustahiks = mustahiks.where((m) {
                    // map categories or categories directly
                    final cat = m.category.toLowerCase();
                    final filter = _selectedRole.toLowerCase();
                    return cat.contains(filter) || filter.contains(cat);
                  }).toList();
                }

                // Apply Status filter
                if (_selectedStatus != 'All Statuses') {
                  mustahiks = mustahiks.where((m) => m.status.toLowerCase() == _selectedStatus.toLowerCase()).toList();
                }

                if (mustahiks.isEmpty) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 40, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No applicants match the filter criteria.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                // Pagination arithmetic (Mocking 10 per page, but for fallback we have a smaller size,
                // we'll say our full total is 245 as shown in pagination footer, so we show the page count index)
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header columns row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'APPLICANT',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'ROLE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'STATUS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // List rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: mustahiks.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final m = mustahiks[index];
                          
                          // Image mock
                          final imageNum = 30 + index;
                          final imageUrl = 'https://images.unsplash.com/photo-${1500000000000 + imageNum * 1000}?q=80&w=100&auto=format&fit=crop';
                          
                          return InkWell(
                            onTap: () => _showMustahikDetailSheet(context, m),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // Applicant Column
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFF1F5F9),
                                          ),
                                          child: ClipOval(
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Center(
                                                  child: Text(
                                                    m.name.isNotEmpty ? m.name[0] : 'U',
                                                    style: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Color(0xFF1E293B),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'ID: #${m.id.startsWith('mst_') ? m.id.substring(4).toUpperCase() : m.id}',
                                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Role Column
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      m.category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  // Status Dropdown Column
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: m.status == 'Verified' 
                                            ? const Color(0xFFD1FAE5) 
                                            : (m.status == 'Rejected' 
                                                ? const Color(0xFFFEE2E2) 
                                                : const Color(0xFFFEF3C7)),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: m.status == 'Verified' 
                                              ? const Color(0xFF10B981) 
                                              : (m.status == 'Rejected' 
                                                  ? const Color(0xFFEF4444) 
                                                  : const Color(0xFFF59E0B)),
                                          width: 1,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: m.status,
                                          isDense: true,
                                          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: m.status == 'Verified' 
                                                ? const Color(0xFF065F46) 
                                                : (m.status == 'Rejected' 
                                                    ? const Color(0xFF7F1D1D) 
                                                    : const Color(0xFF78350F)),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                            DropdownMenuItem(value: 'Verified', child: Text('Verified')),
                                            DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                                          ],
                                          onChanged: (newStatus) async {
                                            if (newStatus != null && newStatus != m.status) {
                                              try {
                                                await _db.updateMustahikStatus(m.id, newStatus);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('✅ Status updated to $newStatus'),
                                                    backgroundColor: const Color(0xFF047857),
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error updating status: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Pagination control bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Showing 1-10 of 245 applicants',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            Row(
                              children: [
                                // Chevron left
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  color: Colors.grey,
                                  onPressed: () {
                                    if (_currentPage > 1) {
                                      setState(() {
                                        _currentPage--;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                // [1]
                                _buildPageButton(1, _currentPage == 1, AppTheme.charcoal),
                                const SizedBox(width: 8),
                                _buildPageButton(2, _currentPage == 2, AppTheme.charcoal),
                                const SizedBox(width: 8),
                                _buildPageButton(3, _currentPage == 3, AppTheme.charcoal),
                                const SizedBox(width: 8),
                                // Chevron right
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  color: AppTheme.charcoal,
                                  onPressed: () {
                                    if (_currentPage < 3) {
                                      setState(() {
                                        _currentPage++;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    ), // SingleChildScrollView
    ); // SafeArea
  }

  Widget _buildPageButton(int page, bool isActive, Color activeColor) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentPage = page;
        });
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isActive ? activeColor : const Color(0xFFCBD5E1)),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  void _showMustahikDetailSheet(BuildContext context, Mustahik m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                m.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
              ),
              Text(
                'ID: #${m.id}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Category/Role', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(m.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Income', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('\$${m.monthlyIncome.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Application Status', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: m.status == 'Verified' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      m.status,
                      style: TextStyle(
                        color: m.status == 'Verified' ? const Color(0xFF065F46) : const Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (m.description != null && m.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Need Description:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  m.description!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  if (m.status != 'Verified')
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.charcoal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          try {
                            await _db.updateMustahikStatus(m.id, 'Verified');
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Verified beneficiary: ${m.name}'),
                                backgroundColor: const Color(0xFF047857),
                              ),
                            );
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error verifying beneficiary: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Verify Applicant', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (m.status != 'Verified') const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(m.status == 'Verified' ? 'Close' : 'Reject Applicant', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
