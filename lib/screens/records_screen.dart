import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'receipt_dialog.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _storage = DonationStorageService();
  String _searchQuery = '';
  DonationCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    var list = _storage.allDonations;

    if (_selectedCategory != null) {
      list = list.where((d) => d.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) {
        final matchesRecipient = d.recipient.toLowerCase().contains(q);
        final matchesNotes = d.notes?.toLowerCase().contains(q) ?? false;
        return matchesRecipient || matchesNotes;
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation History'),
      ),
      body: Column(
        children: [
          // Search & Filter Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search charity, cause, or notes...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                filled: true,
                fillColor: AppTheme.cardDark,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
              ),
            ),
          ),

          // Horizontal Category Filter Pills
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  label: 'All Causes',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...DonationCategory.values.map(
                  (cat) => _buildFilterChip(
                    label: cat.displayName,
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Donation Records List
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'No matching records found.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return _buildRecordCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textMuted,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.primaryEmerald,
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : AppTheme.borderDark,
          ),
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildRecordCard(Donation d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => ReceiptDialog(donation: d),
          );
        },
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryEmerald.withAlpha(40),
          child: const Icon(Icons.volunteer_activism, color: AppTheme.primaryEmeraldLight, size: 20),
        ),
        title: Text(
          d.recipient,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textLight),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${d.category.displayName} • ${d.date.month}/${d.date.day}/${d.date.year}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            if (d.notes != null && d.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                d.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ],
        ),
        trailing: Text(
          '\$${d.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryEmeraldLight,
          ),
        ),
      ),
    );
  }
}
