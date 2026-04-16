import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/firebase_auth_providers.dart';
import '../core/data/providers/finko_stream_providers.dart';
import '../core/upcoming/materialize_upcoming_provider.dart';

/// After login, calls `materializeDueUpcoming` once per day (docs/data-contract.md §11).
class MaterializeDueUpcomingListener extends ConsumerStatefulWidget {
  const MaterializeDueUpcomingListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<MaterializeDueUpcomingListener> createState() =>
      _MaterializeDueUpcomingListenerState();
}

class _MaterializeDueUpcomingListenerState
    extends ConsumerState<MaterializeDueUpcomingListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _schedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(authUidProvider, (previous, next) {
      _schedule();
    });
    ref.listen(userProfileStreamProvider, (previous, next) {
      final previousTz = previous?.valueOrNull?.timezone;
      final nextTz = next.valueOrNull?.timezone;
      if (previousTz != nextTz) {
        _schedule();
      }
    });
    return widget.child;
  }

  void _schedule() {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    final timezone = ref.read(userProfileStreamProvider).valueOrNull?.timezone;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(materializeUpcomingServiceProvider)
          .runOncePerDayIfSignedIn(uid, timezone: timezone);
    });
  }
}
