/// Defaults for the in-app agent (`users/{uid}.agentPreferences`).
/// Legacy Firestore field `telegramBotPreferences` is read as fallback.
class AgentPreferences {
  const AgentPreferences({
    this.defaultAccountId,
    this.defaultExpenseCategoryId,
    this.defaultIncomeCategoryId,
    this.localeOverride,
  });

  final String? defaultAccountId;
  final String? defaultExpenseCategoryId;
  final String? defaultIncomeCategoryId;

  /// Forces agent copy to `es` or `en`.
  final String? localeOverride;

  factory AgentPreferences.fromJson(Map<String, dynamic> json) {
    return AgentPreferences(
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

AgentPreferences? agentPreferencesFromJson(Object? json) {
  if (json == null || json is! Map) return null;
  return AgentPreferences.fromJson(Map<String, dynamic>.from(json));
}

Map<String, dynamic>? agentPreferencesToJson(AgentPreferences? p) {
  if (p == null) return null;
  final m = p.toJson();
  return m.isEmpty ? null : m;
}

/// Reads `agentPreferences` or legacy `telegramBotPreferences`.
AgentPreferences? agentPreferencesFromProfileJson(Map<String, dynamic> json) {
  final direct = agentPreferencesFromJson(json['agentPreferences']);
  if (direct != null) return direct;
  return agentPreferencesFromJson(json['telegramBotPreferences']);
}
