import 'package:flutter_test/flutter_test.dart';
import 'package:zakat_sadaqah_app/utils/constants.dart';
import 'package:zakat_sadaqah_app/utils/zakat_calculator/cash_zakat_calculator.dart';
import 'package:zakat_sadaqah_app/utils/zakat_calculator/livestock_zakat_calculator.dart';
import 'package:zakat_sadaqah_app/utils/zakat_calculator/zakat_calculation_result.dart';

void main() {
  group('CashZakatCalculator', () {
    test('returns not mandatory when wealth is below nisab', () {
      const goldPrice = 80.0;
      final nisab = AppConstants.goldNisabGrams * goldPrice; // 6800

      final result = CashZakatCalculator.calculate(
        goldValue: 1000,
        silverValue: 500,
        cashSavings: 1000,
        otherAssets: 0,
        goldPricePerGram: goldPrice,
      );

      expect(result.totalWealth, 2500);
      expect(result.nisabThreshold, nisab);
      expect(result.isMandatory, isFalse);
      expect(result.zakatDue, 0);
    });

    test('returns 2.5% when wealth meets nisab', () {
      const goldPrice = 80.0;

      final result = CashZakatCalculator.calculate(
        goldValue: 5000,
        silverValue: 2000,
        cashSavings: 1000,
        otherAssets: 1000,
        goldPricePerGram: goldPrice,
      );

      expect(result.isMandatory, isTrue);
      expect(result.zakatDue, closeTo(9000 * 0.025, 0.001));
    });
  });

  group('LivestockZakatCalculator — Camels', () {
    test('below 5: no zakat', () {
      final r = LivestockZakatCalculator.calculate(
        category: LivestockCategory.camels,
        count: 4,
      );
      expect(r.isMandatory, isFalse);
      expect(r.dueItems, isEmpty);
    });

    test('5-9: one sheep', () {
      final r = LivestockZakatCalculator.calculate(
        category: LivestockCategory.camels,
        count: 7,
      );
      expect(r.dueItems, hasLength(1));
      expect(r.dueItems.first.quantity, 1);
      expect(r.dueItems.first.descriptionKey, 'livestock_sheep');
    });

    test('25-35: one bint makhad', () {
      final r = LivestockZakatCalculator.calculate(
        category: LivestockCategory.camels,
        count: 30,
      );
      expect(r.dueItems.first.descriptionKey, 'livestock_bint_makhad');
    });

    test('91-120: two hiqqah', () {
      final r = LivestockZakatCalculator.calculate(
        category: LivestockCategory.camels,
        count: 100,
      );
      expect(r.dueItems.first.quantity, 2);
      expect(r.dueItems.first.descriptionKey, 'livestock_hiqqah');
    });
  });

  group('LivestockZakatCalculator — Cattle', () {
    test('below 30: no zakat', () {
      final r = LivestockZakatCalculator.calculate(
        category: LivestockCategory.cattle,
        count: 29,
      );
      expect(r.isMandatory, isFalse);
    });

    test('30-39: one tabi', () {
      final r = LivestockZakatCalculator.calculate(
        category: LivestockCategory.cattle,
        count: 35,
      );
      expect(r.dueItems.first.descriptionKey, 'livestock_tabi');
    });

    test('40-59: one musinnah', () {
      final r = LivestockZakatCalculator.calculate(
        category: LivestockCategory.cattle,
        count: 45,
      );
      expect(r.dueItems.first.descriptionKey, 'livestock_musinnah');
    });
  });

  group('LivestockZakatCalculator — Goats/Sheep', () {
    test('below 40: no zakat', () {
      final r = LivestockZakatCalculator.calculate(
        category: LivestockCategory.goatsSheep,
        count: 39,
      );
      expect(r.isMandatory, isFalse);
    });

    test('40-120: one sheep or goat', () {
      final r = LivestockZakatCalculator.calculate(
        category: LivestockCategory.goatsSheep,
        count: 80,
      );
      expect(r.dueItems.first.quantity, 1);
      expect(r.dueItems.first.descriptionKey, 'livestock_sheep_or_goat');
    });

    test('121-200: two sheep or goats', () {
      final r = LivestockZakatCalculator.calculate(
        category: LivestockCategory.goatsSheep,
        count: 150,
      );
      expect(r.dueItems.first.quantity, 2);
    });
  });
}
