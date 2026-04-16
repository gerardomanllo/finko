import '../firestore_map_utils.dart';

/// `forexRates/{yyyy-mm-dd}` — global daily quotes into **MXN** (main).
///
/// Functions store only **USD** and **EUR** vs MXN (`rates.USD` / `rates.EUR`:
/// quote per 1 MXN). Cross-rates use MXN as hub.
///
/// [rates] + [extra] preserve unknown keys from older docs.
/// Not codegen: unknown top-level keys are merged into [extra].
class ForexRatesDoc {
  const ForexRatesDoc({
    required this.dateKey,
    this.base,
    this.rates = const {},
    this.extra = const {},
  });

  /// Same key as document id, aligned with `transactionDate` / `yyyy-mm-dd`.
  final String dateKey;
  final String? base;
  final Map<String, double> rates;
  final Map<String, dynamic> extra;

  factory ForexRatesDoc.fromFirestore(
    String dateKey,
    Map<String, dynamic> data,
  ) {
    final ratesRaw = data['rates'];
    final rates = <String, double>{};
    if (ratesRaw is Map) {
      for (final e in ratesRaw.entries) {
        final k = e.key;
        final v = e.value;
        if (k is! String) continue;
        if (v is num) {
          rates[k] = v.toDouble();
        }
      }
    }
    const known = {'rates', 'base', 'date'};
    final extra = <String, dynamic>{};
    for (final e in data.entries) {
      if (!known.contains(e.key)) {
        extra[e.key] = e.value;
      }
    }
    return ForexRatesDoc(
      dateKey: readString(data, 'date', defaultValue: dateKey),
      base: readStringOrNull(data, 'base'),
      rates: rates,
      extra: extra,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': dateKey,
      if (base != null) 'base': base,
      if (rates.isNotEmpty) 'rates': rates,
      ...extra,
    };
  }
}
