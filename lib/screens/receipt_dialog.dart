import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../theme/app_theme.dart';

class ReceiptDialog extends StatelessWidget {
  final Donation donation;
  const ReceiptDialog({Key? key, required this.donation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.borderDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: AppTheme.primaryEmeraldLight, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'Donation Record',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textLight),
            ),
            const SizedBox(height: 6),
            Text(
              'Record ID: ${donation.id}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 18),
            const Divider(color: AppTheme.borderDark),
            const SizedBox(height: 12),
            _buildReceiptRow('Amount Given', '\$${donation.amount.toStringAsFixed(2)}', isBold: true),
            _buildReceiptRow('Cause', donation.category.displayName),
            _buildReceiptRow('Recipient', donation.recipient),
            _buildReceiptRow('Date', '${donation.date.month}/${donation.date.day}/${donation.date.year}'),
            _buildReceiptRow('Schedule', donation.recurringType.name.toUpperCase()),
            if (donation.notes != null) ...[
              const SizedBox(height: 8),
              _buildReceiptRow('Notes', donation.notes!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: isBold ? AppTheme.primaryEmeraldLight : AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
