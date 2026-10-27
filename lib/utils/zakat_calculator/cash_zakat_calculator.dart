import '../constants.dart';
import 'zakat_calculation_result.dart';

/// Calculates Zakat on monetary wealth (cash, gold/silver value, other assets).
///
/// Nisab: [AppConstants.goldNisabGrams] × current gold price per gram.
/// Zakat rate: 2.5% when wealth meets or exceeds nisab.
class CashZakatCalculator {
  CashZakatCalculator._();

  static CashZakatResult calculate({
    required double goldValue,
    required double silverValue,
    required double cashSavings,
    required double otherAssets,
    required double goldPricePerGram,
  }) {
    final double totalWealth = goldValue + silverValue + cashSavings + otherAssets;
    final double nisabThreshold =
        AppConstants.goldNisabGrams * goldPricePerGram;
    final bool isMandatory = totalWealth >= nisabThreshold;
    final double zakatDue =
        isMandatory ? totalWealth * AppConstants.zakatRate : 0.0;

    return CashZakatResult(
      totalWealth: totalWealth,
      goldPricePerGram: goldPricePerGram,
      nisabThreshold: nisabThreshold,
      zakatDue: zakatDue,
      isMandatory: isMandatory,
    );
  }
}
