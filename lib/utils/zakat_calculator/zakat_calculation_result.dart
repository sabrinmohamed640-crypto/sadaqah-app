// Shared result types for cash and livestock Zakat calculations.

enum ZakatCalculatorMode { currency, livestock }

enum LivestockCategory { camels, cattle, goatsSheep }

/// A single payable livestock item (e.g. "2 × 2-year-old she-camel").
class LivestockDueItem {
  final int quantity;
  final String descriptionKey;
  final String? descriptionArgs;

  const LivestockDueItem({
    required this.quantity,
    required this.descriptionKey,
    this.descriptionArgs,
  });

  @override
  String toString() => '$quantity × $descriptionKey';
}

class CashZakatResult {
  final double totalWealth;
  final double goldPricePerGram;
  final double nisabThreshold;
  final double zakatDue;
  final bool isMandatory;

  const CashZakatResult({
    required this.totalWealth,
    required this.goldPricePerGram,
    required this.nisabThreshold,
    required this.zakatDue,
    required this.isMandatory,
  });
}

class LivestockZakatResult {
  final LivestockCategory category;
  final int count;
  final bool isMandatory;
  final List<LivestockDueItem> dueItems;

  const LivestockZakatResult({
    required this.category,
    required this.count,
    required this.isMandatory,
    required this.dueItems,
  });
}
