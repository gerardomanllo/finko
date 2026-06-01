import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/datetime/user_calendar_date.dart';

/// Whether the drawer should show **Show tutorial** (first 15 calendar days).
final showTutorialInDrawerProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;
  final createdAt = profile?.createdAt;
  if (profile == null || createdAt == null) return false;

  final today = ref.watch(todayYyyyMmDdProvider);
  final timezone = profile.timezone;
  final createdYmd = userCalendarDateYyyyMmDd(
    utcNow: createdAt.toUtc(),
    ianaTimezone: timezone.isEmpty ? null : timezone,
  );
  final daysSinceCreation = daysBetweenYyyyMmDd(createdYmd, today);
  return daysSinceCreation >= 0 && daysSinceCreation <= 14;
});
