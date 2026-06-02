import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'agent_catalog_snapshot.dart';

String agentCatalogPrefKey(String uid) => 'finko_agent_catalog_$uid';

Future<AgentCatalogSnapshot> readAgentCatalogSnapshot(String uid) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(agentCatalogPrefKey(uid));
  if (raw == null || raw.isEmpty) return AgentCatalogSnapshot.empty;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return AgentCatalogSnapshot.empty;
    return AgentCatalogSnapshot.fromJson(Map<String, dynamic>.from(decoded));
  } catch (_) {
    return AgentCatalogSnapshot.empty;
  }
}

Future<void> writeAgentCatalogSnapshot(
  String uid,
  AgentCatalogSnapshot snapshot,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    agentCatalogPrefKey(uid),
    jsonEncode(snapshot.toJson()),
  );
}

Future<void> clearAgentCatalogSnapshot(String uid) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(agentCatalogPrefKey(uid));
}
