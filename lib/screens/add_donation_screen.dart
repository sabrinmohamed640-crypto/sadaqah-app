import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class AddDonationScreen extends StatefulWidget {
  const AddDonationScreen({Key? key}) : super(key: key);

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _notesController = TextEditingController();

  DonationCategory _selectedCategory = DonationCategory.generalCharity;
  RecurringType _selectedRecurring = RecurringType.oneTime;
  final DateTime _selectedDate = DateTime.now();

  final List<double> _quickAmounts = [10, 25, 50, 100, 250];

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid donation amount.')),
      );
      return;
    }

    final newDonation = Donation(
      id: 'don-${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      category: _selectedCategory,
      recipient: _recipientController.text.trim(),
      date: _selectedDate,
      recurringType: _selectedRecurring,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    DonationStorageService().addDonation(newDonation);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Donation logged successfully! May it be accepted.'),
        backgroundColor: AppTheme.primaryEmerald,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Charitable Giving'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AMOUNT INPUT ──
              const Text('DONATION AMOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryEmeraldLight),
                  hintText: '0.00',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.borderDark)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.borderDark)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter amount' : null,
              ),

              const SizedBox(height: 12),

              // Quick Amount Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _quickAmounts.map((amt) {
                  return InkWell(
                    onTap: () {
                      _amountController.text = amt.toStringAsFixed(0);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Text('\$${amt.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmeraldLight)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── CATEGORY PICKER ──
              const Text('CAUSE / CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              DropdownButtonFormField<DonationCategory>(
                initialValue: _selectedCategory,
                dropdownColor: AppTheme.cardDark,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderDark)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderDark)),
                ),
                items: DonationCategory.values.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c.displayName, style: const TextStyle(color: AppTheme.textLight)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),

              const SizedBox(height: 20),

              // ── RECIPIENT OR ORGANIZATION ──
              const Text('RECIPIENT / ORGANIZATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  hintText: 'e.g. Local Food Relief, Masjid Fund, Student Aid',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderDark)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderDark)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter recipient name or cause' : null,
              ),

              const SizedBox(height: 20),

              // ── FREQUENCY ──
              const Text('GIVING SCHEDULE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildRecurringChoice('One-Time', RecurringType.oneTime),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRecurringChoice('Monthly', RecurringType.monthly),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRecurringChoice('Annual (Zakat)', RecurringType.annual),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── NOTES / REFLECTION ──
              const Text('INTENTION / PRIVATE NOTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Optional reflection or project reference...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderDark)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderDark)),
                ),
              ),

              const SizedBox(height: 32),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Confirm & Log Donation', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringChoice(String label, RecurringType type) {
    final isSelected = _selectedRecurring == type;
    return InkWell(
      onTap: () => setState(() => _selectedRecurring = type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryEmerald.withAlpha(50) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.primaryEmeraldLight : AppTheme.borderDark),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
