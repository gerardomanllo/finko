import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/firebase_auth_providers.dart';
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
    extends ConsumerState<MaterializeDueUpcomingListener> {
  @override
  void initState() {
    super.initState();
    _schedule(ref.read(authUidProvider));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(authUidProvider, (previous, next) {
      _schedule(next);
    });
    return widget.child;
  }

  void _schedule(String? uid) {
    if (uid == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(materializeUpcomingServiceProvider)
          .runOncePerDayIfSignedIn(uid);
    });
  }
}
