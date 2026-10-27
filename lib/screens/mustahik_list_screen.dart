import 'package:flutter/material.dart';
import '../models/mustahik.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import 'mustahik_details_screen.dart';

/// Standalone screen for browsing and filtering Mustahik (beneficiaries)
/// Displays all beneficiaries in a grid/list view with category filtering
class MustahikListScreen extends StatefulWidget {
  const MustahikListScreen({super.key});

  @override
  State<MustahikListScreen> createState() => _MustahikListScreenState();
}

class _MustahikListScreenState extends State<MustahikListScreen> with TickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();

  /// All available categories for filtering
  static const List<String> _categories = [
    'All',
    'Fakir',
    'Miskin',
    'Ibnu Sabil',
    'Gharimin',
    'Fisabilillah',
    'Amil',
    'Muallaf',
    'Riqab',
  ];

  String _selectedCategory = 'All';
  String _selectedAidType = 'All'; // Filter for aidType: 'All', 'emergency', 'sustainable'
  late TabController _aidTypeTabController;

  @override
  void initState() {
    super.initState();
    _aidTypeTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _aidTypeTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mustahik Recipients'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppTheme.lightSurface,
        elevation: 0,
        foregroundColor: AppTheme.charcoal,
      ),
      body: Column(
        children: [
          // Aid Type Filter TabBar (NEW)
          Container(
            color: AppTheme.lightSurface,
            child: TabBar(
              controller: _aidTypeTabController,
              onTap: (index) {
                setState(() {
                  _selectedAidType = index == 0 ? 'All' : (index == 1 ? 'emergency' : 'sustainable');
                });
              },
              labelColor: AppTheme.charcoal,
              unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
              indicatorColor: AppTheme.emerald,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'All'),
                Tab(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emergency_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Emergency'),
                  ],
                )),
                Tab(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up, size: 16),
                    SizedBox(width: 6),
                    Text('Sustainable'),
                  ],
                )),
              ],
            ),
          ),
          
          // Category Filter Bar
          _buildCategoryFilterBar(),

          // Mustahik List
          Expanded(
            child: StreamBuilder<List<Mustahik>>(
              stream: _db.getMustahikListStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 64, color: Theme.of(context).colorScheme.error.withValues(alpha: 0.6)),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading beneficiaries',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMutedLight)),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }

                List<Mustahik> allMustahik = snapshot.data ?? [];

                // Filter by category
                if (_selectedCategory != 'All') {
                  allMustahik = allMustahik
                      .where((m) => m.category == _selectedCategory)
                      .toList();
                }

                // Filter by aidType
                if (_selectedAidType != 'All') {
                  allMustahik = allMustahik
                      .where((m) => m.aidType == _selectedAidType)
                      .toList();
                }

                // Filter to show only verified beneficiaries to users
                allMustahik = allMustahik.where((m) => m.status == 'Verified').toList();

                if (allMustahik.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 64, color: AppTheme.textMutedLight),
                        const SizedBox(height: 16),
                        Text(
                          'No beneficiaries found',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.textMutedLight),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  itemCount: allMustahik.length,
                  itemBuilder: (context, index) {
                    return _buildMustahikCard(
                        context, allMustahik[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the horizontal category filter bar
  Widget _buildCategoryFilterBar() {
    return Container(
      color: AppTheme.lightBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    _selectedCategory = selected ? category : 'All';
                  });
                },
                backgroundColor: Colors.transparent,
                selectedColor: AppTheme.charcoal.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.charcoal : AppTheme.textMutedLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.charcoal
                      : AppTheme.textMutedLight.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Builds a single mustahik card that navigates to details on tap
  Widget _buildMustahikCard(BuildContext context, Mustahik mustahik) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MustahikDetailsScreen(mustahik: mustahik),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.charcoal.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      mustahik.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mustahik.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Description (truncated)
              if (mustahik.description != null)
                Text(
                  mustahik.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // Aid Type and Support Status Badges (NEW)
              Row(
                children: [
                  // Aid Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: mustahik.aidType == 'emergency' 
                        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.15)
                        : AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mustahik.aidType == 'emergency' ? Icons.emergency_outlined : Icons.trending_up,
                          size: 14,
                          color: mustahik.aidType == 'emergency' ? Theme.of(context).colorScheme.error : AppTheme.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mustahik.aidType == 'emergency' ? 'Emergency' : 'Sustainable',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: mustahik.aidType == 'emergency' ? Theme.of(context).colorScheme.error : AppTheme.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Support Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: mustahik.supportStatus == 'approved'
                        ? AppTheme.emerald.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mustahik.supportStatus == 'approved' ? Icons.verified_user : Icons.hourglass_bottom,
                          size: 14,
                          color: mustahik.supportStatus == 'approved' ? AppTheme.emerald : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mustahik.supportStatus == 'approved' ? 'Approved' : 'Temporary',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: mustahik.supportStatus == 'approved' ? AppTheme.emerald : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Monthly Income Badge
              Row(
                children: [
                  Icon(
                    Icons.trending_down_rounded,
                    size: 16,
                    color: AppTheme.emerald.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Monthly Income: \$${mustahik.monthlyIncome.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Learn More Link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Learn more',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppTheme.charcoal.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
