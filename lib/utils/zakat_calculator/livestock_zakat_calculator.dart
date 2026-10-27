import 'zakat_calculation_result.dart';

/// Zakat on grazing livestock (Hanafi-style tables, common in the Horn of Africa).
///
/// Returns structured [LivestockDueItem] lists so the UI can localize animal names.
class LivestockZakatCalculator {
  LivestockZakatCalculator._();

  static LivestockZakatResult calculate({
    required LivestockCategory category,
    required int count,
  }) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'Cannot be negative');
    }

    final List<LivestockDueItem> dueItems = switch (category) {
      LivestockCategory.camels => _calculateCamels(count),
      LivestockCategory.cattle => _calculateCattle(count),
      LivestockCategory.goatsSheep => _calculateGoatsSheep(count),
    };

    return LivestockZakatResult(
      category: category,
      count: count,
      isMandatory: dueItems.isNotEmpty,
      dueItems: dueItems,
    );
  }

  // ── Camels ────────────────────────────────────────────────────────────────

  static List<LivestockDueItem> _calculateCamels(int count) {
    if (count < 5) return const [];

    if (count <= 9) {
      return [_item(1, 'livestock_sheep')];
    }
    if (count <= 14) {
      return [_item(2, 'livestock_sheep')];
    }
    if (count <= 19) {
      return [_item(3, 'livestock_sheep')];
    }
    if (count <= 24) {
      return [_item(4, 'livestock_sheep')];
    }
    if (count <= 35) {
      return [_item(1, 'livestock_bint_makhad')];
    }
    if (count <= 45) {
      return [_item(1, 'livestock_bint_labun')];
    }
    if (count <= 60) {
      return [_item(1, 'livestock_hiqqah')];
    }
    if (count <= 75) {
      return [_item(1, 'livestock_jadhaah')];
    }
    if (count <= 90) {
      return [_item(2, 'livestock_bint_labun')];
    }
    if (count <= 120) {
      return [_item(2, 'livestock_hiqqah')];
    }
    if (count <= 145) {
      return [_item(3, 'livestock_bint_labun')];
    }
    if (count <= 160) {
      return [_item(3, 'livestock_hiqqah')];
    }
    if (count <= 179) {
      return [_item(4, 'livestock_bint_labun')];
    }
    if (count <= 199) {
      return [_item(4, 'livestock_hiqqah')];
    }
    if (count <= 219) {
      return [_item(5, 'livestock_bint_labun')];
    }
    if (count <= 239) {
      return [_item(5, 'livestock_hiqqah')];
    }

    // 240+: alternating 20-camel brackets (6+ head, type alternates).
    int lower = 240;
    int quantity = 6;
    bool useBintLabun = true;
    while (count >= lower + 20) {
      lower += 20;
      if (!useBintLabun) quantity++;
      useBintLabun = !useBintLabun;
    }
    return [
      _item(
        quantity,
        useBintLabun ? 'livestock_bint_labun' : 'livestock_hiqqah',
      ),
    ];
  }

  // ── Cattle (Baqar) ──────────────────────────────────────────────────────

  static List<LivestockDueItem> _calculateCattle(int count) {
    if (count < 30) return const [];

    if (count <= 39) {
      return [_item(1, 'livestock_tabi')];
    }
    if (count <= 59) {
      return [_item(1, 'livestock_musinnah')];
    }
    if (count <= 69) {
      return [_item(2, 'livestock_tabi')];
    }
    if (count <= 79) {
      return [
        _item(1, 'livestock_musinnah'),
        _item(1, 'livestock_tabi'),
      ];
    }
    if (count <= 89) {
      return [_item(2, 'livestock_musinnah')];
    }
    if (count <= 99) {
      return [_item(3, 'livestock_tabi')];
    }
    if (count <= 109) {
      return [
        _item(1, 'livestock_musinnah'),
        _item(2, 'livestock_tabi'),
      ];
    }
    if (count <= 119) {
      return [
        _item(2, 'livestock_musinnah'),
        _item(1, 'livestock_tabi'),
      ];
    }
    if (count <= 129) {
      return [_item(4, 'livestock_tabi')];
    }
    if (count <= 139) {
      return [
        _item(3, 'livestock_musinnah'),
        _item(1, 'livestock_tabi'),
      ];
    }
    if (count <= 149) {
      return [
        _item(2, 'livestock_musinnah'),
        _item(2, 'livestock_tabi'),
      ];
    }
    if (count <= 159) {
      return [
        _item(3, 'livestock_musinnah'),
        _item(2, 'livestock_tabi'),
      ];
    }
    if (count <= 169) {
      return [_item(4, 'livestock_musinnah')];
    }
    if (count <= 179) {
      return [_item(5, 'livestock_tabi')];
    }
    if (count <= 189) {
      return [
        _item(3, 'livestock_musinnah'),
        _item(3, 'livestock_tabi'),
      ];
    }
    if (count <= 199) {
      return [
        _item(4, 'livestock_musinnah'),
        _item(1, 'livestock_tabi'),
      ];
    }

    // 200+: one tabi per 30 head (rounded per standard incremental tables).
    final int tabi = count ~/ 30;
    return [_item(tabi, 'livestock_tabi')];
  }

  // ── Goats / Sheep (Adhi) ────────────────────────────────────────────────

  static List<LivestockDueItem> _calculateGoatsSheep(int count) {
    if (count < 40) return const [];

    if (count <= 120) {
      return [_item(1, 'livestock_sheep_or_goat')];
    }
    if (count <= 200) {
      return [_item(2, 'livestock_sheep_or_goat')];
    }
    if (count <= 399) {
      return [_item(3, 'livestock_sheep_or_goat')];
    }
    if (count <= 499) {
      return [_item(4, 'livestock_sheep_or_goat')];
    }

    // 500+: one sheep/goat for every 100 (minimum 5 at 500).
    final int due = count ~/ 100;
    return [_item(due, 'livestock_sheep_or_goat')];
  }

  static LivestockDueItem _item(int quantity, String descriptionKey) {
    return LivestockDueItem(
      quantity: quantity,
      descriptionKey: descriptionKey,
    );
  }
}
