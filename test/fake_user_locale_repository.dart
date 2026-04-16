import 'package:flutter/material.dart';

import 'package:finko/core/locale/locale_support.dart';
import 'package:finko/core/user_profile/user_locale_repository.dart';

/// Test double: no Firebase; optional [initial] locale for `loadEffectiveLocale`.
class FakeUserLocaleRepository implements UserLocaleRepository {
  FakeUserLocaleRepository({this.initial = kDefaultAppLocale});

  final Locale initial;

  @override
  Future<Locale> loadEffectiveLocale() async => initial;

  @override
  Future<void> cacheLocaleLocally(Locale locale) async {}

  @override
  Future<void> persistLocale(Locale locale) async {}

  @override
  Stream<Locale?> get remoteLocaleUpdates => const Stream.empty();
}
