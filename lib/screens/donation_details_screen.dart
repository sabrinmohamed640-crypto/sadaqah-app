import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../models/donation.dart';
import '../models/campaign.dart';
import '../services/database_service.dart';
import '../main.dart' show firebaseInitialized;
import '../widgets/impact_tracking_card.dart';
import '../models/project_impact_model.dart';
import '../data/project_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Payment Method Model
// ─────────────────────────────────────────────────────────────────────────────
enum PaymentMethod { premierWallet, evcHormuud }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.premierWallet:
        return 'Premier Wallet';
      case PaymentMethod.evcHormuud:
        return 'EVC (Hormuud)';
    }
  }

  String get shortName {
    switch (this) {
      case PaymentMethod.premierWallet:
        return 'Premier Wallet';
      case PaymentMethod.evcHormuud:
        return 'EVC Plus';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethod.premierWallet:
        return 'Pay securely with your Premier Wallet balance';
      case PaymentMethod.evcHormuud:
        return 'Pay via EVC Plus — Hormuud Telecom';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.premierWallet:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethod.evcHormuud:
        return Icons.phone_android_rounded;
    }
  }

  /// Primary brand colour for each provider.
  Color get brandColor {
    switch (this) {
      case PaymentMethod.premierWallet:
        return const Color(0xFF6366F1); // indigo/violet
      case PaymentMethod.evcHormuud:
        return const Color(0xFF10B981); // emerald
    }
  }

  /// Secondary / gradient end colour.
  Color get brandColorDark {
    switch (this) {
      case PaymentMethod.premierWallet:
        return const Color(0xFF4F46E5);
      case PaymentMethod.evcHormuud:
        return const Color(0xFF047857);
    }
  }

  /// Receiver phone shown on the confirmation prompt.
  String get receiverPhone {
    switch (this) {
      case PaymentMethod.premierWallet:
        return '+252-61-7000-100';
      case PaymentMethod.evcHormuud:
        return '+252-61-8000-200';
    }
  }

  /// Prompt label for the input field.
  String get inputLabel {
    switch (this) {
      case PaymentMethod.premierWallet:
        return 'Premier Wallet ID / Phone';
      case PaymentMethod.evcHormuud:
        return 'EVC Plus Phone Number';
    }
  }

  String get inputHint {
    switch (this) {
      case PaymentMethod.premierWallet:
        return 'e.g.  +252 61 XXX XXXX';
      case PaymentMethod.evcHormuud:
        return 'e.g.  +252 61 XXX XXXX';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Utility — Generate realistic TX ID
// ─────────────────────────────────────────────────────────────────────────────
String _generateTxId(PaymentMethod method) {
  final String prefix = method == PaymentMethod.premierWallet ? 'PW' : 'EV';
  final int epoch = DateTime.now().millisecondsSinceEpoch;
  // e.g. TX_PW_178147392810
  return 'TX_${prefix}_$epoch';
}

// ─────────────────────────────────────────────────────────────────────────────
//  ZAKAT CONFIGURATION — Dynamic Zakat Types & Calculation
// ─────────────────────────────────────────────────────────────────────────────

enum ZakatType { alFitr, alMal, tradeAssets, goldSilver }

extension ZakatTypeExtension on ZakatType {
  String get displayName {
    switch (this) {
      case ZakatType.alFitr:
        return 'Zakat Al-Fitr';
      case ZakatType.alMal:
        return 'Zakat Al-Mal';
      case ZakatType.tradeAssets:
        return 'Trade Assets Zakat';
      case ZakatType.goldSilver:
        return 'Gold/Silver Zakat';
    }
  }

  String get description {
    switch (this) {
      case ZakatType.alFitr:
        return 'Fixed rate per person at end of Ramadan';
      case ZakatType.alMal:
        return '2.5% of total accumulated wealth';
      case ZakatType.tradeAssets:
        return '2.5% of the value of trade goods';
      case ZakatType.goldSilver:
        return '2.5% of precious metals (by weight)';
    }
  }

  String get inputLabel {
    switch (this) {
      case ZakatType.alFitr:
        return 'Number of People';
      case ZakatType.alMal:
        return 'Total Wealth (\$)';
      case ZakatType.tradeAssets:
        return 'Value of Goods (\$)';
      case ZakatType.goldSilver:
        return 'Weight (grams)';
    }
  }

  String get secondaryInputLabel {
    switch (this) {
      case ZakatType.goldSilver:
        return 'Current Price per Gram (\$)';
      default:
        return '';
    }
  }

  /// Fixed Zakat Al-Fitr rate per person (in USD)
  static const double alFitrRate = 2.5;

  /// Calculate zakat based on input value
  double calculate(double value, {double? secondaryValue}) {
    switch (this) {
      case ZakatType.alFitr:
        // value = number of people
        return value * alFitrRate;
      case ZakatType.alMal:
      case ZakatType.tradeAssets:
        // 2.5% of wealth/goods
        return value * 0.025;
      case ZakatType.goldSilver:
        // 2.5% of (weight × price)
        final totalValue = value * (secondaryValue ?? 0);
        return totalValue * 0.025;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class DonationDetailsScreen extends StatefulWidget {
  final String serviceName;
  final Campaign? campaign;
  final String? waqfProjectId; // Optional: project ID for Waqf donations

  const DonationDetailsScreen({
    super.key,
    required this.serviceName,
    this.campaign,
    this.waqfProjectId,
  });

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _primaryInputController =
      TextEditingController(); // For Zakat Al-Fitr, Wealth, Goods, Weight
  final TextEditingController _secondaryInputController =
      TextEditingController(); // For Gold/Silver price
  final _formKey = GlobalKey<FormState>();

  final List<double> _presetAmounts = const [
    10.0,
    50.0,
    100.0,
    250.0,
    500.0,
    1000.0,
  ];

  // ── Zakat-specific state ────────────────────────────────────────────────
  bool _isZakat = false;
  ZakatType? _selectedZakatType;
  double? _selectedPreset;
  bool _isLoading = false;
  double _calculatedAmount = 0.0;

  // ── Button scale animation ──────────────────────────────────────────────
  late final AnimationController _btnController;
  late final Animation<double> _btnScaleAnim;

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _btnScaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _btnController, curve: Curves.easeInOut));

    // Detect if this is a Zakat service
    _isZakat = widget.serviceName.toLowerCase().contains('zakat');
    if (_isZakat) {
      _selectedZakatType = ZakatType.alMal; // Default
    }

    _primaryInputController.addListener(_recalculateAmount);
    _secondaryInputController.addListener(_recalculateAmount);
  }

  @override
  void dispose() {
    _btnController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _primaryInputController.dispose();
    _secondaryInputController.dispose();
    super.dispose();
  }

  /// Recalculate zakat amount based on inputs
  void _recalculateAmount() {
    if (!_isZakat || _selectedZakatType == null) return;

    final double? primaryValue = double.tryParse(_primaryInputController.text);
    if (primaryValue == null || primaryValue <= 0) {
      setState(() {
        _calculatedAmount = 0;
        _amountController.clear();
      });
      return;
    }

    final double? secondaryValue = double.tryParse(
      _secondaryInputController.text,
    );
    final double calculated = _selectedZakatType!.calculate(
      primaryValue,
      secondaryValue: secondaryValue,
    );

    setState(() {
      _calculatedAmount = calculated;
      _amountController.text = calculated.toStringAsFixed(2);
      _selectedPreset = null; // Clear preset when manually changed
    });
  }

  /// Handle Zakat type change
  void _onZakatTypeChanged(ZakatType? newType) {
    if (newType == null) return;
    setState(() {
      _selectedZakatType = newType;
      _primaryInputController.clear();
      _secondaryInputController.clear();
      _amountController.clear();
      _calculatedAmount = 0;
      _selectedPreset = null;
    });
  }

  // ── Preset helpers ─────────────────────────────────────────────────────────
  void _onPresetSelected(double amount) {
    setState(() {
      _selectedPreset = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  void _onAmountChanged(String value) {
    final double? amount = double.tryParse(value);
    setState(() {
      _selectedPreset = (amount != null && _presetAmounts.contains(amount))
          ? amount
          : null;
    });
  }

  // ── STEP 1 — Open payment method selector ──────────────────────────────────
  void _openPaymentMethodSheet() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    // Use calculated amount if Zakat, otherwise use manual input
    final double finalAmount = _isZakat
        ? _calculatedAmount
        : double.parse(_amountController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentMethodSheet(
        amount: finalAmount,
        onSelected: (method) {
          Navigator.pop(ctx);
          Future.delayed(
            const Duration(milliseconds: 180),
            () => _openPaymentInputSheet(method),
          );
        },
      ),
    );
  }

  // ── STEP 2 — Open secure phone / wallet input ──────────────────────────────
  void _openPaymentInputSheet(PaymentMethod method) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentInputSheet(
        method: method,
        amount: _isZakat
            ? _calculatedAmount
            : double.parse(_amountController.text),
        serviceName: widget.serviceName,
        zakatType: _isZakat ? _selectedZakatType : null,
        onConfirm: (phone) {
          Navigator.pop(ctx);
          _processPayment(method, phone);
        },
        onBack: () {
          Navigator.pop(ctx);
          _openPaymentMethodSheet();
        },
      ),
    );
  }

  // ── STEP 3 — Process transaction & write to Firestore ─────────────────────
  Future<void> _processPayment(PaymentMethod method, String senderPhone) async {
    setState(() => _isLoading = true);

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.translate('sign_in_to_donate')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    final double amount = _isZakat
        ? _calculatedAmount
        : double.parse(_amountController.text);
    final String notes = _notesController.text.trim();
    final String transactionId = _generateTxId(method);
    final DateTime timestamp = DateTime.now();

    // Resolve donation type
    final nameLower = widget.serviceName.toLowerCase();
    final String resolvedType =
        (nameLower.contains('zakat') || nameLower.contains('زكاة'))
        ? 'Zakat'
        : 'Sadaqah';

    // Fetch donor info from the authenticated user's profile.
    String donorName = user.displayName ?? 'Donor';
    final String donorId = user.uid;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) donorName = doc.data()?['name'] ?? donorName;
    } catch (e) {
      debugPrint('⚠️ Could not fetch donor name: $e');
    }

    // Build donation model
    final donation = Donation(
      id: transactionId,
      donorId: donorId,
      donorName: donorName,
      amount: amount,
      type: resolvedType,
      paymentMethod: method.displayName,
      status: 'Completed',
      timestamp: timestamp,
      notes: notes.isNotEmpty ? notes : null,
    );

    // Write to global donations collection
    try {
      await DatabaseService().logDonation(donation);
    } catch (e) {
      debugPrint('❌ logDonation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Warning: Saved offline. Accountability log delayed: $e',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // Increment campaign funding if this is a campaign donation
    if (widget.campaign != null) {
      try {
        await DatabaseService().incrementCampaignFunding(widget.campaign!.id, amount);
        debugPrint('✅ Campaign funding updated for campaign: ${widget.campaign!.id}');
      } catch (e) {
        debugPrint('❌ Error updating campaign funding: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Warning: Donation recorded but campaign progress may be delayed: $e',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }

    // Write to users/<uid>/transactions/<txId>
    try {
      final transactionData = {
        'transactionId': transactionId,
        'amount': amount,
        'type': resolvedType,
        'paymentMethod': method.displayName,
        'senderPhone': senderPhone,
        'receiverPhone': method.receiverPhone,
        'serviceName': widget.serviceName,
        'status': 'Completed',
        'timestamp': FieldValue.serverTimestamp(),
        'notes': notes.isNotEmpty ? notes : null,
        'donorName': donorName,
      };

      // Add Zakat-specific metadata
      if (_isZakat && _selectedZakatType != null) {
        transactionData['zakatType'] = _selectedZakatType!.displayName;
        transactionData['zakatInputValue'] =
            double.tryParse(_primaryInputController.text) ?? 0;
        if (_secondaryInputController.text.isNotEmpty) {
          transactionData['zakatSecondaryValue'] =
              double.tryParse(_secondaryInputController.text) ?? 0;
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .set(transactionData);
      debugPrint('✅ Saved to users/$donorId/transactions/$transactionId');

      // Update Waqf project raised amount if this is a Waqf donation
      if (widget.waqfProjectId != null && widget.waqfProjectId!.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(widget.waqfProjectId)
              .update({
            'raised': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint(
              '✅ Updated Waqf project ${widget.waqfProjectId} raised amount by $amount');
        } catch (e) {
          debugPrint('⚠️ Failed to update Waqf project raised amount: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Sub-collection write failed: $e');
    }

    if (mounted) setState(() => _isLoading = false);
    if (!mounted) return;

    _showSuccessSheet(
      transactionId: transactionId,
      amount: amount,
      method: method,
      senderPhone: senderPhone,
      donorName: donorName,
      timestamp: timestamp,
      zakatType: _isZakat ? _selectedZakatType?.displayName : null,
      zakatInputValue: _isZakat
          ? double.tryParse(_primaryInputController.text)
          : null,
      zakatSecondaryValue:
          _isZakat && _selectedZakatType == ZakatType.goldSilver
          ? double.tryParse(_secondaryInputController.text)
          : null,
    );
  }

  // ── STEP 4 — Polished success receipt ─────────────────────────────────────
  void _showSuccessSheet({
    required String transactionId,
    required double amount,
    required PaymentMethod method,
    required String senderPhone,
    required String donorName,
    required DateTime timestamp,
    String? zakatType,
    double? zakatInputValue,
    double? zakatSecondaryValue,
  }) {
    final loc = context.loc;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _SuccessReceiptSheet(
        transactionId: transactionId,
        amount: amount,
        method: method,
        senderPhone: senderPhone,
        receiverPhone: method.receiverPhone,
        serviceName: widget.serviceName,
        donorName: donorName,
        timestamp: timestamp,
        loc: loc,
        zakatType: zakatType,
        zakatInputValue: zakatInputValue,
        zakatSecondaryValue: zakatSecondaryValue,
        onDone: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final ProjectImpactModel? projectImpact =
        ProjectDummyData.getProjectByServiceName(widget.serviceName);

    // Get keyboard height for responsive scrolling
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(loc.translate('donation_details_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // ── Scrollable content area
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Main scrollable content
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: AppConstants.screenPadding.left,
                  right: AppConstants.screenPadding.right,
                  top: AppConstants.screenPadding.top,
                  // Add bottom padding: fixed button (56dp) + spacing (12dp) + keyboard + safe area
                  bottom:
                      80 +
                      keyboardHeight +
                      MediaQuery.of(context).viewPadding.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header banner — fully responsive
                      _buildHeaderBanner(loc),

                      if (projectImpact != null) ...[
                        const SizedBox(height: AppConstants.spacingLg),
                        ImpactTrackingCard(projectImpact: projectImpact),
                      ],

                      const SizedBox(height: AppConstants.spacingLg),

                      // ── ZAKAT SECTION (if applicable) ──────────────────────
                      if (_isZakat) ...[
                        // Zakat type selector
                        Text(
                          'Zakat Type',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        SizedBox(
                          width: double.infinity,
                          child: DropdownButtonFormField<ZakatType>(
                            initialValue: _selectedZakatType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Select Zakat Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: ZakatType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        type.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        type.description,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _onZakatTypeChanged,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingLg),

                        // Dynamic input fields based on Zakat type
                        if (_selectedZakatType != null) ...[
                          // Primary input
                          TextFormField(
                            controller: _primaryInputController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: _selectedZakatType!.inputLabel,
                              hintText: _selectedZakatType == ZakatType.alFitr
                                  ? 'e.g., 5'
                                  : 'e.g., 1000.00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a value';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingMd),

                          // Secondary input (for Gold/Silver)
                          if (_selectedZakatType == ZakatType.goldSilver) ...[
                            TextFormField(
                              controller: _secondaryInputController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText:
                                    _selectedZakatType!.secondaryInputLabel,
                                hintText: 'e.g., 60.00',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter price per gram';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                          ],

                          // Calculated amount display
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Calculated Zakat Amount',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${_calculatedAmount.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.calculate_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingLg),
                        ],
                      ] else ...[
                        // NON-ZAKAT SECTION (Traditional donation)
                        // Amount section
                        Text(
                          loc.translate('set_donation_amount'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        _buildAmountField(loc),
                        const SizedBox(height: AppConstants.spacingMd),

                        // Preset amounts grid — fully responsive
                        _buildPresetsGrid(),

                        const SizedBox(height: AppConstants.spacingLg),
                      ],

                      // Notes section
                      Text(
                        loc.translate('optional_message'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: loc.translate('optional_message_hint'),
                        ),
                      ),

                      const SizedBox(height: AppConstants.spacingLg),
                    ],
                  ),
                ),
              ),

              // Fixed button at bottom — always visible and clickable
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: AppConstants.screenPadding.left,
                    right: AppConstants.screenPadding.right,
                    top: AppConstants.spacingMd,
                    bottom:
                        AppConstants.spacingMd +
                        MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: _buildProceedButton(loc),
                ),
              ),

              // Loading overlay — appears above button, doesn't block it
              if (_isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              color: AppTheme.gold,
                              strokeWidth: 3.5,
                              backgroundColor: AppTheme.gold.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Processing transaction…',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Please wait a moment',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildHeaderBanner(AppLocalization loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.18),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'project-title-${widget.serviceName}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      widget.serviceName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                StreamBuilder<DocumentSnapshot>(
                  stream:
                      firebaseInitialized &&
                          FirebaseAuth.instance.currentUser != null
                      ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .snapshots()
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    String donorName =
                        FirebaseAuth.instance.currentUser?.displayName ??
                        'Donor';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      donorName = data?['name'] ?? donorName;
                    }
                    return Text(
                      '${loc.translate('donation_allocation_desc')} • $donorName',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(AppLocalization loc) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: _onAmountChanged,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
        letterSpacing: 1.0,
      ),
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '\$',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: '0.00',
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        contentPadding: const EdgeInsets.symmetric(vertical: 22),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return loc.translate('enter_amount_error');
        }
        final double? amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return loc.translate('enter_amount_positive_error');
        }
        return null;
      },
    );
  }

  Widget _buildPresetsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemCount: _presetAmounts.length,
      itemBuilder: (context, index) {
        final double val = _presetAmounts[index];
        final bool isSelected = _selectedPreset == val;
        return InkWell(
          onTap: () => _onPresetSelected(val),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.15)
                  : AppTheme.surfaceColor,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : const Color(0xFF1F2937),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '\$${val.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProceedButton(AppLocalization loc) {
    return ScaleTransition(
      scale: _btnScaleAnim,
      child: SizedBox(
        width: double.infinity,
        height: 56, // Fixed height ensures button is always visible
        child: GestureDetector(
          onTapDown: (_) {
            if (!_isLoading) _btnController.forward();
          },
          onTapUp: (_) {
            _btnController.reverse();
            if (!_isLoading) _openPaymentMethodSheet();
          },
          onTapCancel: () => _btnController.reverse(),
          child: ElevatedButton.icon(
            // Button is disabled during loading; GestureDetector handles taps
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLoading
                  ? AppTheme.gold.withValues(alpha: 0.5)
                  : AppTheme.gold,
              disabledBackgroundColor: AppTheme.gold.withValues(alpha: 0.5),
              foregroundColor: AppTheme.charcoal,
              disabledForegroundColor: AppTheme.charcoal.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppColors.gold.withValues(alpha: 0.4),
            ),
            icon: Icon(
              _isLoading
                  ? Icons.hourglass_empty_rounded
                  : Icons.payment_rounded,
              size: 22,
            ),
            label: Text(
              _isLoading ? 'Processing…' : loc.translate('confirm_donation'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHEET 1 — Payment Method Selector
// ═════════════════════════════════════════════════════════════════════════════
class _PaymentMethodSheet extends StatelessWidget {
  final double amount;
  final void Function(PaymentMethod) onSelected;

  const _PaymentMethodSheet({required this.amount, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          _SheetHandle(),
          const SizedBox(height: 28),

          // Lock icon with glow
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Amount pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Total Donation: \$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Payment options
          for (final method in PaymentMethod.values) ...[
            _PaymentOption(method: method, onTap: () => onSelected(method)),
            if (method != PaymentMethod.values.last) const SizedBox(height: 14),
          ],

          const SizedBox(height: 24),

          // Security badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 13,
                color: AppTheme.textMuted.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              const Text(
                'Secured & Encrypted  ·  256-bit SSL',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final PaymentMethod method;
  final VoidCallback onTap;

  const _PaymentOption({required this.method, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: method.brandColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                // Brand icon with gradient background
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        method.brandColor.withValues(alpha: 0.2),
                        method.brandColorDark.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: method.brandColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(method.icon, color: method.brandColor, size: 26),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.displayName,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        method.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: method.brandColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: method.brandColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHEET 2 — Secure Payment Input  (phone / wallet ID)
// ═════════════════════════════════════════════════════════════════════════════
class _PaymentInputSheet extends StatefulWidget {
  final PaymentMethod method;
  final double amount;
  final String serviceName;
  final ZakatType? zakatType;
  final void Function(String phone) onConfirm;
  final VoidCallback onBack;

  const _PaymentInputSheet({
    required this.method,
    required this.amount,
    required this.serviceName,
    this.zakatType,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  State<_PaymentInputSheet> createState() => _PaymentInputSheetState();
}

class _PaymentInputSheetState extends State<_PaymentInputSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final _inputKey = GlobalKey<FormState>();
  bool _sending = false;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_inputKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      HapticFeedback.vibrate();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _sending = true);

    // Simulate network handshake (1.8 s)
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;
    setState(() => _sending = false);
    widget.onConfirm(_phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.method;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(
          color: method.brandColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      // Constrain max height to prevent overflow when keyboard appears
      constraints: BoxConstraints(
        maxHeight: screenHeight - keyboardHeight - 60,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: 36 + keyboardHeight,
        ),
        child: Form(
          key: _inputKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: _SheetHandle()),
              const SizedBox(height: 20),

              // ── Brand header ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      method.brandColor.withValues(alpha: 0.15),
                      method.brandColorDark.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: method.brandColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: method.brandColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        method.icon,
                        color: method.brandColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.displayName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: method.brandColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const Text(
                            'Secure Payment Gateway',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: method.brandColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: method.brandColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Secure',
                            style: TextStyle(
                              fontSize: 11,
                              color: method.brandColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Amount summary row ──────────────────────────────────
              _InfoRow(
                label: 'Amount to Send',
                value: '\$${widget.amount.toStringAsFixed(2)}',
                valueStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // ── Merchant info card ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1F2937), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Receiver / Merchant',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Khairat',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Text(
                        method.receiverPhone,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: method.brandColor,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Phone input ─────────────────────────────────────────
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (ctx, child) => Transform.translate(
                  offset: Offset(
                    _shakeAnim.value * sin(_shakeCtrl.value * pi * 6),
                    0,
                  ),
                  child: child,
                ),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\s]')),
                  ],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    labelText: method.inputLabel,
                    labelStyle: TextStyle(color: method.brandColor),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(
                        left: 14,
                        right: 10,
                        top: 10,
                        bottom: 10,
                      ),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: method.brandColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.phone_rounded,
                        color: method.brandColor,
                        size: 18,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    hintText: method.inputHint,
                    hintStyle: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.normal,
                      fontSize: 15,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: method.brandColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: method.brandColor,
                        width: 2.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone / wallet ID';
                    }
                    if (value
                            .trim()
                            .replaceAll(RegExp(r'[\s\-\+]'), '')
                            .length <
                        7) {
                      return 'Enter a valid phone number (min 7 digits)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Send button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: method.brandColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: method.brandColor.withValues(
                      alpha: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _sending
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Sending…',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              'Send Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Back link
              TextButton.icon(
                onPressed: _sending ? null : widget.onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                label: const Text(
                  'Choose different method',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHEET 3 — Polished Success Receipt
// ═════════════════════════════════════════════════════════════════════════════
class _SuccessReceiptSheet extends StatefulWidget {
  final String transactionId;
  final double amount;
  final PaymentMethod method;
  final String senderPhone;
  final String receiverPhone;
  final String serviceName;
  final String donorName;
  final DateTime timestamp;
  final AppLocalization loc;
  final String? zakatType;
  final double? zakatInputValue;
  final double? zakatSecondaryValue;
  final VoidCallback onDone;

  const _SuccessReceiptSheet({
    required this.transactionId,
    required this.amount,
    required this.method,
    required this.senderPhone,
    required this.receiverPhone,
    required this.serviceName,
    required this.donorName,
    required this.timestamp,
    required this.loc,
    this.zakatType,
    this.zakatInputValue,
    this.zakatSecondaryValue,
    required this.onDone,
  });

  @override
  State<_SuccessReceiptSheet> createState() => _SuccessReceiptSheetState();
}

class _SuccessReceiptSheetState extends State<_SuccessReceiptSheet>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _confettiCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _confettiCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _confettiCtrl.repeat(reverse: true);
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final String formattedDate =
        '${widget.timestamp.day.toString().padLeft(2, '0')}/'
        '${widget.timestamp.month.toString().padLeft(2, '0')}/'
        '${widget.timestamp.year}  '
        '${widget.timestamp.hour.toString().padLeft(2, '0')}:'
        '${widget.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: AnimatedBuilder(
            animation: _slideAnim,
            builder: (ctx, child) => Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: child,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHandle(),
                const SizedBox(height: 28),

                // ── Animated success badge ────────────────────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: ScaleTransition(
                    scale: _pulseAnim,
                    child: _SuccessBadge(),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Headline ──────────────────────────────────────────
                Text(
                  loc.translate('donation_success'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loc.translate('may_allah_reward'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.primaryColor.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),

                // ── Amount hero card ──────────────────────────────────
                _AmountHeroCard(
                  amount: widget.amount,
                  serviceName: widget.serviceName,
                  method: widget.method,
                ),
                const SizedBox(height: 20),

                // ── Transaction receipt card ──────────────────────────
                _ReceiptCard(
                  senderPhone: widget.senderPhone,
                  receiverPhone: widget.receiverPhone,
                  method: widget.method,
                  transactionId: widget.transactionId,
                  formattedDate: formattedDate,
                  donorName: widget.donorName,
                  loc: loc,
                  zakatType: widget.zakatType,
                  zakatInputValue: widget.zakatInputValue,
                  zakatSecondaryValue: widget.zakatSecondaryValue,
                  amount: widget.amount,
                ),
                const SizedBox(height: 28),

                // ── Done button ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.home_rounded, size: 22),
                    label: Text(
                      loc.translate('return_home'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Disclaimer
                const Text(
                  'Your contribution is safely recorded. JazakAllah Khayran.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Success Badge ─────────────────────────────────────────────────────────
class _SuccessBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outermost glow ring
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              width: 2,
            ),
          ),
        ),
        // Middle ring
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
              width: 2,
            ),
          ),
        ),
        // Inner filled circle
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.4),
                AppTheme.primaryColor.withValues(alpha: 0.18),
              ],
            ),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.primaryColor,
            size: 44,
          ),
        ),
      ],
    );
  }
}

// ── Amount Hero Card ──────────────────────────────────────────────────────
class _AmountHeroCard extends StatelessWidget {
  final double amount;
  final String serviceName;
  final PaymentMethod method;

  const _AmountHeroCard({
    required this.amount,
    required this.serviceName,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.22),
            AppTheme.primaryColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Total Amount Donated',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              serviceName,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Payment method badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(method.icon, size: 14, color: method.brandColor),
              const SizedBox(width: 6),
              Text(
                'via ${method.displayName}',
                style: TextStyle(
                  fontSize: 12,
                  color: method.brandColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Receipt Card ──────────────────────────────────────────────────────────
class _ReceiptCard extends StatelessWidget {
  final String senderPhone;
  final String receiverPhone;
  final PaymentMethod method;
  final String transactionId;
  final String formattedDate;
  final String donorName;
  final AppLocalization loc;
  final String? zakatType;
  final double? zakatInputValue;
  final double? zakatSecondaryValue;
  final double amount;

  const _ReceiptCard({
    required this.senderPhone,
    required this.receiverPhone,
    required this.method,
    required this.transactionId,
    required this.formattedDate,
    required this.donorName,
    required this.loc,
    this.zakatType,
    this.zakatInputValue,
    this.zakatSecondaryValue,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2937), width: 1),
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF1F2937), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Transaction Receipt',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✓  Completed',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rows
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ReceiptRow(
                  icon: Icons.person_rounded,
                  label: 'Donor Name',
                  value: donorName,
                  iconColor: AppTheme.primaryColor,
                ),
                _Divider(),
                _ReceiptRow(
                  icon: Icons.phone_rounded,
                  label: loc.translate('sender_phone'),
                  value: senderPhone,
                  iconColor: method.brandColor,
                ),
                _Divider(),
                _ReceiptRow(
                  icon: Icons.storefront_rounded,
                  label: loc.translate('receiver_phone'),
                  value: receiverPhone,
                  iconColor: const Color(0xFF8B5CF6),
                ),
                _Divider(),
                _ReceiptRow(
                  icon: method.icon,
                  label: loc.translate('payment_method_label'),
                  value: method.displayName,
                  valueColor: method.brandColor,
                  iconColor: method.brandColor,
                ),
                _Divider(),
                _ReceiptRow(
                  icon: Icons.tag_rounded,
                  label: loc.translate('transaction_id_label'),
                  value: transactionId,
                  mono: true,
                  small: true,
                  iconColor: AppTheme.accentColor,
                ),
                _Divider(),
                _ReceiptRow(
                  icon: Icons.calendar_today_rounded,
                  label: loc.translate('date_time_label'),
                  value: formattedDate,
                  iconColor: AppTheme.textMuted,
                ),
                // ── Zakat Details (conditional) ───────────────────────
                if (zakatType != null) ...[_Divider()],
                if (zakatType != null)
                  _ReceiptRow(
                    icon: Icons.mosque_rounded,
                    label: 'Zakat Type',
                    value: zakatType!,
                    valueColor: AppTheme.primaryColor,
                    iconColor: AppTheme.primaryColor,
                  ),
                if (zakatType != null) ...[_Divider()],
                if (zakatType != null && zakatInputValue != null)
                  _ReceiptRow(
                    icon: Icons.info_rounded,
                    label: 'Zakat Details',
                    value: _getZakatCalculationDetails(),
                    iconColor: AppTheme.primaryColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Generate calculation details based on Zakat type
  String _getZakatCalculationDetails() {
    if (zakatType == null || zakatInputValue == null) return 'N/A';

    // Extract number from "Zakat Al-Fitr" format
    if (zakatType!.contains('Al-Fitr')) {
      return '${zakatInputValue!.toStringAsFixed(0)} people × \$2.50 = \$${amount.toStringAsFixed(2)}';
    } else if (zakatType!.contains('Al-Mal')) {
      return '2.5% of \$${zakatInputValue!.toStringAsFixed(2)} = \$${amount.toStringAsFixed(2)}';
    } else if (zakatType!.contains('Trade Assets')) {
      return '2.5% of \$${zakatInputValue!.toStringAsFixed(2)} = \$${amount.toStringAsFixed(2)}';
    } else if (zakatType!.contains('Gold') || zakatType!.contains('Silver')) {
      if (zakatSecondaryValue != null) {
        return '${zakatInputValue!.toStringAsFixed(2)}g × \$${zakatSecondaryValue!.toStringAsFixed(2)}/g × 2.5% = \$${amount.toStringAsFixed(2)}';
      }
    }
    return '\$${amount.toStringAsFixed(2)}';
  }
}

class _ReceiptRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color iconColor;
  final bool mono;
  final bool small;

  const _ReceiptRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.iconColor,
    this.mono = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: small ? 10.5 : 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textPrimary,
              fontFamily: mono ? 'monospace' : null,
              letterSpacing: mono ? 0.5 : 0,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Shared micro-widgets
// ═════════════════════════════════════════════════════════════════════════════

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFF374151),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(color: Color(0xFF1F2937), height: 22, thickness: 0.8);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style:
              valueStyle ??
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
      ],
    );
  }
}
