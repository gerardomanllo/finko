// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  uid: json['uid'] as String,
  displayName: json['displayName'] as String? ?? '',
  photoUrl: json['photoUrl'] as String?,
  mainCurrency: json['mainCurrency'] as String? ?? 'MXN',
  timezone: json['timezone'] as String? ?? '',
  locale: json['locale'] as String? ?? '',
  themePreference: $enumDecodeNullable(
    _$ThemePreferenceEnumMap,
    json['themePreference'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
  createdAt: const FirestoreNullableUtcDateTimeConverter().fromJson(
    json['createdAt'],
  ),
  updatedAt: const FirestoreNullableUtcDateTimeConverter().fromJson(
    json['updatedAt'],
  ),
  ledgerVersion: (json['ledgerVersion'] as num?)?.toInt(),
  integrations: json['integrations'] == null
      ? const UserIntegrations()
      : _userIntegrationsFromJson(json['integrations']),
  budgets: json['budgets'] == null
      ? const {}
      : budgetMapFromFirestoreJson(json['budgets']),
  aggregateLastCompletedAt: const FirestoreNullableUtcDateTimeConverter()
      .fromJson(json['aggregateLastCompletedAt']),
  ledgerSourcesLastChangedAt: const FirestoreNullableUtcDateTimeConverter()
      .fromJson(json['ledgerSourcesLastChangedAt']),
  telegramBotPreferences: telegramBotPreferencesFromJson(
    json['telegramBotPreferences'],
  ),
);

Map<String, dynamic> _$UserProfileToJson(
  UserProfile instance,
) => <String, dynamic>{
  'displayName': instance.displayName,
  'photoUrl': ?instance.photoUrl,
  'mainCurrency': instance.mainCurrency,
  'timezone': instance.timezone,
  'locale': instance.locale,
  'themePreference': ?_$ThemePreferenceEnumMap[instance.themePreference],
  'onboardingCompleted': instance.onboardingCompleted,
  'createdAt': ?const FirestoreNullableUtcDateTimeConverter().toJson(
    instance.createdAt,
  ),
  'updatedAt': ?const FirestoreNullableUtcDateTimeConverter().toJson(
    instance.updatedAt,
  ),
  'ledgerVersion': ?instance.ledgerVersion,
  'integrations': instance.integrations.toJson(),
  'budgets': budgetMapToFirestoreJson(instance.budgets),
  'aggregateLastCompletedAt': ?const FirestoreNullableUtcDateTimeConverter()
      .toJson(instance.aggregateLastCompletedAt),
  'ledgerSourcesLastChangedAt': ?const FirestoreNullableUtcDateTimeConverter()
      .toJson(instance.ledgerSourcesLastChangedAt),
  'telegramBotPreferences': ?telegramBotPreferencesToJson(
    instance.telegramBotPreferences,
  ),
};

const _$ThemePreferenceEnumMap = {
  ThemePreference.light: 'light',
  ThemePreference.dark: 'dark',
  ThemePreference.system: 'system',
};

UserIntegrations _$UserIntegrationsFromJson(Map<String, dynamic> json) =>
    UserIntegrations(
      whatsapp: json['whatsapp'] == null
          ? null
          : WhatsAppIntegration.fromJson(
              json['whatsapp'] as Map<String, dynamic>,
            ),
      telegram: json['telegram'] == null
          ? null
          : TelegramAppIntegration.fromJson(
              json['telegram'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$UserIntegrationsToJson(UserIntegrations instance) =>
    <String, dynamic>{
      'whatsapp': ?instance.whatsapp?.toJson(),
      'telegram': ?instance.telegram?.toJson(),
    };

WhatsAppIntegration _$WhatsAppIntegrationFromJson(Map<String, dynamic> json) =>
    WhatsAppIntegration(
      phoneE164: json['phoneE164'] as String,
      verifiedAt: const FirestoreNullableUtcDateTimeConverter().fromJson(
        json['verifiedAt'],
      ),
    );

Map<String, dynamic> _$WhatsAppIntegrationToJson(
  WhatsAppIntegration instance,
) => <String, dynamic>{
  'phoneE164': instance.phoneE164,
  'verifiedAt': ?const FirestoreNullableUtcDateTimeConverter().toJson(
    instance.verifiedAt,
  ),
};

TelegramAppIntegration _$TelegramAppIntegrationFromJson(
  Map<String, dynamic> json,
) => TelegramAppIntegration(
  username: json['username'] as String,
  chatId: json['chatId'] as String?,
  verifiedAt: const FirestoreNullableUtcDateTimeConverter().fromJson(
    json['verifiedAt'],
  ),
);

Map<String, dynamic> _$TelegramAppIntegrationToJson(
  TelegramAppIntegration instance,
) => <String, dynamic>{
  'username': instance.username,
  'chatId': ?instance.chatId,
  'verifiedAt': ?const FirestoreNullableUtcDateTimeConverter().toJson(
    instance.verifiedAt,
  ),
};
