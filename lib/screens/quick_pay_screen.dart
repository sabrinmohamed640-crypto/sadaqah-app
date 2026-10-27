import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/donation.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';

/// Quick Pay screen for fast Zakat/Sadaqah donations with preset amounts
class QuickPayScreen extends StatefulWidget {
  const QuickPayScreen({super.key});

  @override
  State<QuickPayScreen> createState() => _QuickPayScreenState();
}

class _QuickPayScreenState extends State<QuickPayScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _customAmountController = TextEditingController();
  
  String _donationType = 'Sadaqah'; // Default to Sadaqah
  double? _selectedAmount;
  bool _isProcessing = false;

  final List<double> _presetAmounts = [10.0, 50.0, 100.0];

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Pay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppTheme.lightSurface,
        elevation: 0,
        foregroundColor: AppTheme.charcoal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: 28),

            // Donation Type Toggle
            _buildDonationTypeToggle(),
            const SizedBox(height: 24),

            // Quick Amount Buttons
            _buildQuickAmountButtons(),
            const SizedBox(height: 24),

            // Custom Amount Section
            _buildCustomAmountSection(),
            const SizedBox(height: 32),

            // Selected Amount Display
            _buildAmountSummary(),
            const SizedBox(height: 32),

            // Pay Now Button
            _buildPayButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Header section with description
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.charcoal,
            AppTheme.charcoal.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Make a Quick Donation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a preset amount or enter a custom amount to donate',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle between Zakat and Sadaqah
  Widget _buildDonationTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Donation Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.charcoal.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildTypeButton('Zakat'),
              _buildTypeButton('Sadaqah'),
            ],
          ),
        ),
      ],
    );
  }

  /// Individual donation type button
  Widget _buildTypeButton(String type) {
    final isSelected = _donationType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _donationType = type;
            _selectedAmount = null;
            _customAmountController.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.charcoal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Quick amount selection buttons
  Widget _buildQuickAmountButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Select Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _presetAmounts
              .map((amount) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildAmountButton(amount),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Individual preset amount button
  Widget _buildAmountButton(double amount) {
    final isSelected = _selectedAmount == amount;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAmount = amount;
          _customAmountController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.charcoal : AppTheme.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.charcoal
                : AppTheme.charcoal.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '\$${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Custom amount input section
  Widget _buildCustomAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.charcoal.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _customAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter custom amount',
              hintStyle: TextStyle(
                color: AppTheme.textMutedLight,
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.attach_money_rounded),
              prefixIconColor: AppTheme.charcoal.withValues(alpha: 0.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.charcoal,
            ),
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  _selectedAmount = double.tryParse(value);
                } else {
                  _selectedAmount = null;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  /// Display selected amount summary
  Widget _buildAmountSummary() {
    final displayAmount = _selectedAmount ?? 0.0;
    final isValid = displayAmount > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.gold.withValues(alpha: 0.15),
            AppTheme.emerald.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Donation Summary',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Type:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                _donationType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\$${displayAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isValid ? AppTheme.charcoal : AppTheme.textMutedLight,
                ),
              ),
            ],
          ),
          if (!isValid)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Please enter an amount greater than \$0',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Pay Now button
  Widget _buildPayButton() {
    final isValid = (_selectedAmount ?? 0) > 0 && !_isProcessing;

    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isValid ? _processPayment : null,
        icon: _isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.check_circle_rounded),
        label: Text(
          _isProcessing ? 'Processing...' : 'Pay Now',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? AppTheme.charcoal : AppTheme.textMutedLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.textMutedLight.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isValid ? 4 : 0,
        ),
      ),
    );
  }

  /// Process the payment
  Future<void> _processPayment() async {
    final amount = _selectedAmount;
    if (amount == null || amount <= 0) {
      _showErrorDialog('Invalid Amount', 'Please enter an amount greater than \$0');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('Not Authenticated', 'Please log in to make a donation');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get user name (for display in donation record)
      final userName = await _db.getUserName(user.uid);

      // Generate donation ID (timestamp-based, matching existing pattern)
      final donationId = 'QPAY_${DateTime.now().millisecondsSinceEpoch}';

      // Create donation object
      final donation = Donation(
        id: donationId,
        donorId: user.uid,
        donorName: userName,
        amount: amount,
        type: _donationType,
        paymentMethod: 'Quick Pay',
        status: 'Completed',
        timestamp: DateTime.now(),
      );

      // Process the donation (logs it and updates user totals)
      await _db.processQuickDonation(donation);

      setState(() {
        _isProcessing = false;
      });

      // Show success dialog
      _showSuccessDialog(amount, _donationType);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      _showErrorDialog('Payment Failed', 'Error: $e');
      debugPrint('❌ [QuickPay] Payment processing failed: $e');
    }
  }

  /// Show success dialog
  void _showSuccessDialog(double amount, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 50,
                color: AppTheme.emerald,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Donation Successful!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Amount
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.emerald,
              ),
            ),
            const SizedBox(height: 8),

            // Type and message
            Text(
              '$type donation received',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Additional message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Thank you for your generosity. Your donation will help those in need.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charcoal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.charcoal,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'OK',
              style: TextStyle(color: AppTheme.charcoal),
            ),
          ),
        ],
      ),
    );
  }
}
