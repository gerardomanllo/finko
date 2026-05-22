import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/firestore_paths.dart';
import '../domain/agent_message.dart';

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return AgentRepository(
    firestore: ref.watch(firestoreProvider),
    functions: FirebaseFunctions.instance,
    storage: FirebaseStorage.instance,
  );
});

final agentMessagesStreamProvider = StreamProvider<List<AgentMessage>>((ref) {
  final uid = ref.watch(authUidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(agentRepositoryProvider).watchMessages(uid);
});

class AgentRepository {
  AgentRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _functions = functions,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  Stream<List<AgentMessage>> watchMessages(String uid) {
    return _firestore
        .collection(FirestorePaths.agentMessagesCollection(uid))
        .orderBy('createdAt')
        .snapshots()
        .map((snap) {
          final all = snap.docs.map(AgentMessage.fromFirestore).toList();
          return _visibleMessages(all);
        });
  }

  static List<AgentMessage> _visibleMessages(List<AgentMessage> all) {
    DateTime? latestCompleteAt;
    for (final m in all.reversed) {
      if (m.isAssistant && m.status == AgentMessageStatus.complete) {
        latestCompleteAt = m.createdAt;
        break;
      }
    }
    return all.where((m) {
      if (m.status == AgentMessageStatus.superseded) return false;
      if (m.isFailed && m.isDismissed) return false;
      if (m.isFailed &&
          latestCompleteAt != null &&
          m.createdAt != null &&
          m.createdAt!.isBefore(latestCompleteAt)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> sendText({
    required String uid,
    required String text,
    String? clientMessageId,
  }) async {
    final callable = _functions.httpsCallable('sendAgentMessage');
    await callable.call<Map<String, dynamic>>({
      'text': text,
      'kind': 'text',
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
    });
  }

  Future<void> sendImageFile({
    required String uid,
    required File file,
    String? caption,
    String? clientMessageId,
  }) async {
    final id = _firestore.collection(FirestorePaths.agentMessagesCollection(uid)).doc().id;
    final path = 'users/$uid/agentMedia/$id';
    await _storage.ref(path).putFile(file);
    final callable = _functions.httpsCallable('sendAgentMessage');
    await callable.call<Map<String, dynamic>>({
      if (caption != null && caption.trim().isNotEmpty) 'text': caption.trim(),
      'storagePath': path,
      'kind': 'image',
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
    });
  }

  Future<void> sendVoiceFile({
    required String uid,
    required File file,
    String? clientMessageId,
  }) async {
    final id = _firestore.collection(FirestorePaths.agentMessagesCollection(uid)).doc().id;
    final path = 'users/$uid/agentMedia/$id.ogg';
    await _storage.ref(path).putFile(file);
    final callable = _functions.httpsCallable('sendAgentMessage');
    await callable.call<Map<String, dynamic>>({
      'storagePath': path,
      'kind': 'voice',
      if (clientMessageId != null) 'clientMessageId': clientMessageId,
    });
  }

  Future<void> submitAction(String callbackCode) async {
    final callable = _functions.httpsCallable('submitAgentAction');
    await callable.call<Map<String, dynamic>>({'callbackCode': callbackCode});
  }

  Future<void> dismissMessage(String messageId) async {
    final callable = _functions.httpsCallable('dismissAgentMessage');
    await callable.call<Map<String, dynamic>>({'messageId': messageId});
  }
}
