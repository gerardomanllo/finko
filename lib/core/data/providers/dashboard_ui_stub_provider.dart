import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub series for net worth sparkline until `monthlyTotals.days` / history backs the chart.
final netWorthSparklineStubProvider = Provider<List<double>>((ref) {
  return List<double>.generate(30, (int i) {
    return 1000000 + i * 4200 + (i % 5) * 1300;
  });
});
