import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../utils/theme.dart';
import '../utils/zakat_calculator/cash_zakat_calculator.dart';
import '../utils/zakat_calculator/livestock_zakat_calculator.dart';
import '../utils/zakat_calculator/zakat_calculation_result.dart';

/// Shows the dual-mode Zakat calculator (currency + livestock).
void showZakatCalculatorDialog(
  BuildContext context, {
  required DatabaseService databaseService,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => ZakatCalculatorDialog(
      databaseService: databaseService,
    ),
  );
}

class ZakatCalculatorDialog extends StatefulWidget {
  const ZakatCalculatorDialog({
    super.key,
    required this.databaseService,
  });

  final DatabaseService databaseService;

  @override
  State<ZakatCalculatorDialog> createState() => _ZakatCalculatorDialogState();
}

class _ZakatCalculatorDialogState extends State<ZakatCalculatorDialog> {
  ZakatCalculatorMode _mode = ZakatCalculatorMode.currency;
  LivestockCategory _livestockCategory = LivestockCategory.camels;

  // Currency inputs
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _cashController = TextEditingController();
  final _otherController = TextEditingController();
  final _goldPriceController = TextEditingController(
    text: AppConstants.defaultGoldPricePerGram.toStringAsFixed(2),
  );

  // Livestock input
  final _livestockCountController = TextEditingController();

  CashZakatResult? _cashResult;
  LivestockZakatResult? _livestockResult;

  @override
  void dispose() {
    _goldController.dispose();
    _silverController.dispose();
    _cashController.dispose();
    _otherController.dispose();
    _goldPriceController.dispose();
    _livestockCountController.dispose();
    super.dispose();
  }

  void _resetResults() {
    _cashResult = null;
    _livestockResult = null;
  }

  void _onModeChanged(ZakatCalculatorMode mode) {
    setState(() {
      _mode = mode;
      _resetResults();
    });
  }

  void _calculate() {
    final loc = context.loc;
    setState(() {
      if (_mode == ZakatCalculatorMode.currency) {
        final goldPrice = double.tryParse(_goldPriceController.text.trim());
        if (goldPrice == null || goldPrice <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.translate('gold_price_required'))),
          );
          return;
        }
        _cashResult = CashZakatCalculator.calculate(
          goldValue: _parse(_goldController),
          silverValue: _parse(_silverController),
          cashSavings: _parse(_cashController),
          otherAssets: _parse(_otherController),
          goldPricePerGram: goldPrice,
        );
        _livestockResult = null;
      } else {
        final count = int.tryParse(_livestockCountController.text.trim());
        if (count == null || count < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.translate('livestock_count_invalid'))),
          );
          return;
        }
        _livestockResult = LivestockZakatCalculator.calculate(
          category: _livestockCategory,
          count: count,
        );
        _cashResult = null;
      }
    });
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0.0;

  Future<void> _saveCalculation() async {
    final loc = context.loc;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('sign_in_to_donate'))),
        );
      }
      return;
    }

    final Map<String, dynamic> payload = {
      'userId': uid,
      'calculatorMode': _mode.name,
      'calculatedAt': DateTime.now().toIso8601String(),
    };

    if (_cashResult != null) {
      final r = _cashResult!;
      payload.addAll({
        'goldValue': _parse(_goldController),
        'silverValue': _parse(_silverController),
        'cashSavings': _parse(_cashController),
        'otherAssets': _parse(_otherController),
        'goldPricePerGram': r.goldPricePerGram,
        'nisabThreshold': r.nisabThreshold,
        'totalWealth': r.totalWealth,
        'zakatDue': r.zakatDue,
        'isMandatory': r.isMandatory,
      });
    } else if (_livestockResult != null) {
      final r = _livestockResult!;
      payload.addAll({
        'livestockCategory': r.category.name,
        'livestockCount': r.count,
        'isMandatory': r.isMandatory,
        'livestockDueSummary': _formatLivestockDue(loc, r),
        'zakatDue': 0.0,
      });
    }

    try {
      await widget.databaseService.logZakatCalculation(payload);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('zakat_saved'))),
        );
      }
    } catch (e) {
      debugPrint('Zakat calculation save error: $e');
    }
  }

  String _formatLivestockDue(AppLocalization loc, LivestockZakatResult result) {
    if (!result.isMandatory) {
      return loc.translate('zakat_not_mandatory');
    }
    return result.dueItems
        .map(
          (item) =>
              '${item.quantity} × ${loc.translate(item.descriptionKey)}',
        )
        .join(', ');
  }

  String _livestockCategoryLabel(AppLocalization loc, LivestockCategory c) {
    return switch (c) {
      LivestockCategory.camels => loc.translate('livestock_camels'),
      LivestockCategory.cattle => loc.translate('livestock_cattle'),
      LivestockCategory.goatsSheep => loc.translate('livestock_goats_sheep'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final bool hasResult = _cashResult != null || _livestockResult != null;

    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.translate('zakat_calc_title'),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<ZakatCalculatorMode>(
              segments: [
                ButtonSegment(
                  value: ZakatCalculatorMode.currency,
                  label: Text(loc.translate('calc_mode_currency')),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ZakatCalculatorMode.livestock,
                  label: Text(loc.translate('calc_mode_livestock')),
                  icon: const Icon(Icons.grass_outlined, size: 18),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                _onModeChanged(selection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 16),
            if (_mode == ZakatCalculatorMode.currency) ...[
              Text(
                loc.translate('zakat_calc_cash_info'),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              _buildMoneyField(
                loc.translate('gold_price_per_gram'),
                _goldPriceController,
                Icons.monetization_on_outlined,
              ),
              const SizedBox(height: 10),
              _buildMoneyField(
                loc.translate('gold_value'),
                _goldController,
                Icons.diamond_outlined,
              ),
              const SizedBox(height: 10),
              _buildMoneyField(
                loc.translate('silver_value'),
                _silverController,
                Icons.circle_outlined,
              ),
              const SizedBox(height: 10),
              _buildMoneyField(
                loc.translate('cash_savings'),
                _cashController,
                Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 10),
              _buildMoneyField(
                loc.translate('other_assets'),
                _otherController,
                Icons.inventory_2_outlined,
              ),
              if (_cashResult != null) ...[
                const SizedBox(height: 20),
                _buildCashResultCard(loc, _cashResult!),
              ],
            ] else ...[
              Text(
                loc.translate('zakat_calc_livestock_info'),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<LivestockCategory>(
                initialValue: _livestockCategory,
                dropdownColor: AppTheme.surfaceColor,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: loc.translate('livestock_type_label'),
                  prefixIcon: const Icon(
                    Icons.pets_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                items: LivestockCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_livestockCategoryLabel(loc, category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _livestockCategory = value;
                      _resetResults();
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _livestockCountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: loc.translate('livestock_count_label'),
                  prefixIcon: const Icon(
                    Icons.numbers_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  hintText: loc.translate('livestock_count_hint'),
                ),
              ),
              if (_livestockResult != null) ...[
                const SizedBox(height: 20),
                _buildLivestockResultCard(loc, _livestockResult!),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            loc.translate('close_btn'),
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ),
        if (hasResult)
          TextButton(
            onPressed: _saveCalculation,
            child: Text(
              loc.translate('save_calculation'),
              style: const TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ElevatedButton(
          onPressed: _calculate,
          child: Text(loc.translate('calculate_btn')),
        ),
      ],
    );
  }

  Widget _buildMoneyField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        prefixText: '\$ ',
        prefixStyle: const TextStyle(color: AppTheme.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildCashResultCard(AppLocalization loc, CashZakatResult result) {
    final bool mandatory = result.isMandatory;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (mandatory ? AppTheme.primaryColor : AppTheme.accentColor)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (mandatory ? AppTheme.primaryColor : AppTheme.accentColor)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            mandatory
                ? loc.translate('total_zakat_due')
                : loc.translate('zakat_not_mandatory'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: mandatory ? AppTheme.primaryColor : AppTheme.accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (mandatory) ...[
            const SizedBox(height: 8),
            Text(
              '\$${result.zakatDue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '(2.5% ${loc.translate('of_total_wealth')})',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            loc.translate('nisab_threshold_label')
                .replaceAll('{amount}', result.nisabThreshold.toStringAsFixed(2)),
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          Text(
            loc.translate('total_wealth_label')
                .replaceAll('{amount}', result.totalWealth.toStringAsFixed(2)),
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLivestockResultCard(
    AppLocalization loc,
    LivestockZakatResult result,
  ) {
    final bool mandatory = result.isMandatory;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (mandatory ? AppTheme.primaryColor : AppTheme.accentColor)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (mandatory ? AppTheme.primaryColor : AppTheme.accentColor)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mandatory
                ? loc.translate('livestock_zakat_due')
                : loc.translate('zakat_not_mandatory'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: mandatory ? AppTheme.primaryColor : AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${loc.translate('livestock_type_label')}: '
            '${_livestockCategoryLabel(loc, result.category)} • '
            '${loc.translate('livestock_count_label')}: ${result.count}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          if (mandatory) ...[
            const SizedBox(height: 12),
            ...result.dueItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.pets,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${item.quantity} × ${loc.translate(item.descriptionKey)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
