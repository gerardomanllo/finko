import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../json/json_converters.dart';
import 'finko_enums.dart';
import 'monthly_totals.dart';
import 'agent_preferences.dart';

part 'user_profile.g.dart';

/// Default profile currency per [docs/data-model.md] §3.
const String kDefaultMainCurrency = 'MXN';

/// `users/{uid}` — profile + settings.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UserProfile {
  const UserProfile({
    required this.uid,
    this.displayName = '',
    this.photoUrl,
    this.mainCurrency = kDefaultMainCurrency,
    this.timezone = '',
    this.locale = '',
    this.themePreference,
    this.onboardingCompleted = false,
    this.createdAt,
    this.updatedAt,
    this.ledgerVersion,
    this.integrations = const UserIntegrations(),
    this.budgets = const {},
    this.aggregateLastCompletedAt,
    this.ledgerSourcesLastChangedAt,
    this.agentPreferences,
  });

  @JsonKey(includeToJson: false)
  final String uid;

  @JsonKey(defaultValue: '')
  final String displayName;

  final String? photoUrl;

  @JsonKey(defaultValue: kDefaultMainCurrency)
  final String mainCurrency;

  @JsonKey(defaultValue: '')
  final String timezone;

  @JsonKey(defaultValue: '')
  final String locale;

  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ThemePreference? themePreference;

  @JsonKey(defaultValue: false)
  final bool onboardingCompleted;

  @FirestoreNullableUtcDateTimeConverter()
  final DateTime? createdAt;

  @FirestoreNullableUtcDateTimeConverter()
  final DateTime? updatedAt;

  final int? ledgerVersion;

  @JsonKey(fromJson: _userIntegrationsFromJson)
  final UserIntegrations integrations;

  /// Per-category targets in main currency (same for every month).
  @JsonKey(
    fromJson: budgetMapFromFirestoreJson,
    toJson: budgetMapToFirestoreJson,
  )
  final Map<String, MonthlyBudgetEntry> budgets;

  /// Server-only: last time ledger aggregates finished applying (Cloud Functions).
  @FirestoreNullableUtcDateTimeConverter()
  final DateTime? aggregateLastCompletedAt;

  /// Server-only: last time transactions / categories / accounts changed in a
  /// ledger-relevant way (Cloud Functions).
  @FirestoreNullableUtcDateTimeConverter()
  final DateTime? ledgerSourcesLastChangedAt;

  /// Defaults for the in-app agent (`users/{uid}.agentPreferences`).
  @JsonKey(
    fromJson: agentPreferencesFromJson,
    toJson: agentPreferencesToJson,
    name: 'agentPreferences',
  )
  final AgentPreferences? agentPreferences;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    if (copy['agentPreferences'] == null &&
        copy['telegramBotPreferences'] != null) {
      copy['agentPreferences'] = copy['telegramBotPreferences'];
    }
    return _$UserProfileFromJson(copy);
  }

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile.fromJson({...data, 'uid': uid});
  }

  /// Merge-friendly map for client updates (omit server-controlled fields as needed).
  Map<String, dynamic> toFirestore({bool includeServerTimestamps = false}) {
    return {
      if (displayName.isNotEmpty) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'mainCurrency': mainCurrency,
      if (timezone.isNotEmpty) 'timezone': timezone,
      if (locale.isNotEmpty) 'locale': locale,
      if (themePreference != null) 'themePreference': themePreference!.wireName,
      'onboardingCompleted': onboardingCompleted,
      if (ledgerVersion != null) 'ledgerVersion': ledgerVersion,
      if (integrations.hasAny) 'integrations': integrations.toJson(),
      if (includeServerTimestamps) 'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UserIntegrations {
  const UserIntegrations({this.whatsapp, this.telegram});

  final WhatsAppIntegration? whatsapp;
  final TelegramAppIntegration? telegram;

  bool get hasAny => whatsapp != null || telegram != null;

  factory UserIntegrations.fromJson(Map<String, dynamic> json) =>
      _$UserIntegrationsFromJson(json);

  Map<String, dynamic> toJson() => _$UserIntegrationsToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class WhatsAppIntegration {
  const WhatsAppIntegration({required this.phoneE164, this.verifiedAt});

  final String phoneE164;

  @FirestoreNullableUtcDateTimeConverter()
  final DateTime? verifiedAt;

  factory WhatsAppIntegration.fromJson(Map<String, dynamic> json) =>
      _$WhatsAppIntegrationFromJson(json);

  Map<String, dynamic> toJson() => _$WhatsAppIntegrationToJson(this);
}

/// Telegram channel row (`integrations.telegram`).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TelegramAppIntegration {
  const TelegramAppIntegration({
    required this.username,
    this.chatId,
    this.verifiedAt,
  });

  final String username;

  /// Telegram `chat_id` (string) for bot messaging; server-written only.
  final String? chatId;

  @FirestoreNullableUtcDateTimeConverter()
  final DateTime? verifiedAt;

  factory TelegramAppIntegration.fromJson(Map<String, dynamic> json) =>
      _$TelegramAppIntegrationFromJson(json);

  Map<String, dynamic> toJson() => _$TelegramAppIntegrationToJson(this);
}

UserIntegrations _userIntegrationsFromJson(Object? json) {
  if (json is! Map) {
    return const UserIntegrations();
  }
  return UserIntegrations.fromJson(Map<String, dynamic>.from(json));
}
