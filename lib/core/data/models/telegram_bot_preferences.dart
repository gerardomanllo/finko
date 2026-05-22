import 'agent_preferences.dart';

export 'agent_preferences.dart';

/// @deprecated Use [AgentPreferences].
typedef TelegramBotPreferences = AgentPreferences;

/// @deprecated Use [agentPreferencesFromJson].
AgentPreferences? telegramBotPreferencesFromJson(Object? json) =>
    agentPreferencesFromJson(json);

/// @deprecated Use [agentPreferencesToJson].
Map<String, dynamic>? telegramBotPreferencesToJson(AgentPreferences? p) =>
    agentPreferencesToJson(p);
