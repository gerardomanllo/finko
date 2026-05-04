/// Optional defaults for the Telegram DM bot (`users/{uid}.telegramBotPreferences`).
/// Server reads these in Cloud Functions; client may merge-update when linked.
class TelegramBotPreferences {
  const TelegramBotPreferences({
    this.defaultAccountId,
    this.defaultExpenseCategoryId,
    this.defaultIncomeCategoryId,
    this.localeOverride,
  });

  final String? defaultAccountId;
  final String? defaultExpenseCategoryId;
  final String? defaultIncomeCategoryId;

  /// Forces bot copy to `es` or `en`; omit so replies follow Telegram `language_code`.
  final String? localeOverride;

  factory TelegramBotPreferences.fromJson(Map<String, dynamic> json) {
    return TelegramBotPreferences(
      defaultAccountId: json['defaultAccountId'] as String?,
      defaultExpenseCategoryId: json['defaultExpenseCategoryId'] as String?,
      defaultIncomeCategoryId: json['defaultIncomeCategoryId'] as String?,
      localeOverride: json['localeOverride'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (defaultAccountId != null && defaultAccountId!.trim().isNotEmpty)
      'defaultAccountId': defaultAccountId!.trim(),
    if (defaultExpenseCategoryId != null &&
        defaultExpenseCategoryId!.trim().isNotEmpty)
      'defaultExpenseCategoryId': defaultExpenseCategoryId!.trim(),
    if (defaultIncomeCategoryId != null &&
        defaultIncomeCategoryId!.trim().isNotEmpty)
      'defaultIncomeCategoryId': defaultIncomeCategoryId!.trim(),
    if (localeOverride != null && localeOverride!.trim().isNotEmpty)
      'localeOverride': localeOverride!.trim().toLowerCase(),
  };
}

TelegramBotPreferences? telegramBotPreferencesFromJson(Object? json) {
  if (json == null || json is! Map) return null;
  return TelegramBotPreferences.fromJson(Map<String, dynamic>.from(json));
}

Map<String, dynamic>? telegramBotPreferencesToJson(TelegramBotPreferences? p) {
  if (p == null) return null;
  final m = p.toJson();
  return m.isEmpty ? null : m;
}
