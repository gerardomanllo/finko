import 'package:intl/intl.dart';

import 'spending_date_math.dart';
import 'spending_granularity.dart';
import 'spending_period_descriptor.dart';

/// Bottom label for a period card (locale tag, e.g. `en` or `es-MX`).
String spendingPeriodCardLabel(String localeTag, SpendingPeriodDescriptor d) {
  switch (d.granularity) {
    case SpendingGranularity.week:
      final u = parseYyyyMmDd(d.startYyyyMmDd);
      final cal = DateTime(u.year, u.month, u.day);
      return DateFormat.yMMMd(localeTag).format(cal);
    case SpendingGranularity.month:
      final u = parseYyyyMmDd(d.startYyyyMmDd);
      final cal = DateTime(u.year, u.month, u.day);
      return DateFormat.yMMMM(localeTag).format(cal);
    case SpendingGranularity.quarter:
      final u = parseYyyyMmDd(d.startYyyyMmDd);
      final q = quarterForMonth(u.month);
      return 'Q$q ${u.year}';
    case SpendingGranularity.year:
      final u = parseYyyyMmDd(d.startYyyyMmDd);
      final cal = DateTime(u.year, u.month, u.day);
      return DateFormat.y(localeTag).format(cal);
  }
}
