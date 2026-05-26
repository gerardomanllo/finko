import 'package:finko/core/formatting/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nonNegativeMinor keeps positive minor units', () {
    expect(nonNegativeMinor(14356582), 14356582);
    expect(nonNegativeMinor(-5), 0);
    expect(nonNegativeMinor(0), 0);
  });

  test('atLeastMinor floors at min for bar denominators', () {
    expect(atLeastMinor(594673, 1), 594673);
    expect(atLeastMinor(0, 1), 1);
    expect(atLeastMinor(-100, 1), 1);
  });
}
