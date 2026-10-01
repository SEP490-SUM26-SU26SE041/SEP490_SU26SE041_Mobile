import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/rag_models.dart';

/// ─── Local Storage cho Conversation History ───────────────────────────────────
///
/// Spec mục 4.1: Mobile PHẢI tự quản lý conversation history vì
/// BE không lưu session (mục 1.2).
///
/// Dùng SharedPreferences + JSON cho mỗi role:
///   - Key conversations: `rag_conversations_<scope>` (list metadata)
///   - Key messages:      `rag_messages_<conversationId>` (list messages)
///
/// Mỗi role (student / technician) có danh sách conversation RIÊNG BIỆT
/// nhờ scope riêng.
class RagConversationStorage {
  RagConversationStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _kConversationsPrefix = 'rag_conversations_';
  static const String _kMessagesPrefix = 'rag_messages_';
  static const String _kLastOpenedPrefix = 'rag_last_opened_';
  static const String _kHealthCachePrefix = 'rag_health_cache_';

  // ─── Conversations ──────────────────────────────────────────────────────

  Future<List<RagConversation>> loadConversations(RagScope scope) async {
    final raw = _prefs.getString('$_kConversationsPrefix${scope.value}');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => RagConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveConversations(
      RagScope scope, List<RagConversation> conversations) async {
    final raw = jsonEncode(conversations.map((c) => c.toJson()).toList());
    await _prefs.setString('$_kConversationsPrefix${scope.value}', raw);
  }

  Future<void> upsertConversation(RagConversation conv) async {
    final list = await loadConversations(conv.scope);
    final idx = list.indexWhere((c) => c.id == conv.id);
    if (idx >= 0) {
      list[idx] = conv;
    } else {
      list.insert(0, conv);
    }
    await saveConversations(conv.scope, list);
  }

  Future<void> deleteConversation(RagScope scope, String id) async {
    final list = await loadConversations(scope);
    list.removeWhere((c) => c.id == id);
    await saveConversations(scope, list);
    await _prefs.remove('$_kMessagesPrefix$id');
    final last = _prefs.getString('$_kLastOpenedPrefix${scope.value}');
    if (last == id) {
      await _prefs.remove('$_kLastOpenedPrefix${scope.value}');
    }
  }

  Future<void> deleteAllConversations(RagScope scope) async {
    final list = await loadConversations(scope);
    for (final c in list) {
      await _prefs.remove('$_kMessagesPrefix${c.id}');
    }
    await _prefs.remove('$_kConversationsPrefix${scope.value}');
    await _prefs.remove('$_kLastOpenedPrefix${scope.value}');
  }

  // ─── Messages ───────────────────────────────────────────────────────────

  Future<List<RagStoredMessage>> loadMessages(String conversationId) async {
    final raw = _prefs.getString('$_kMessagesPrefix$conversationId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => RagStoredMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessages(
      String conversationId, List<RagStoredMessage> messages) async {
    final raw = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _prefs.setString('$_kMessagesPrefix$conversationId', raw);
  }

  Future<void> appendMessage(String conversationId, RagStoredMessage msg) async {
    final list = await loadMessages(conversationId);
    // Auto-increment ID nếu msg.id == 0.
    final nextId = list.isEmpty
        ? 1
        : (list.map((m) => m.id).reduce((a, b) => a > b ? a : b)) + 1;
    final saved = RagStoredMessage(
      id: msg.id == 0 ? nextId : msg.id,
      conversationId: msg.conversationId,
      role: msg.role,
      content: msg.content,
      ts: msg.ts,
      sources: msg.sources,
    );
    list.add(saved);
    await saveMessages(conversationId, list);
  }

  // ─── Last opened (auto-restore) ────────────────────────────────────────

  Future<String?> getLastOpened(RagScope scope) async =>
      _prefs.getString('$_kLastOpenedPrefix${scope.value}');

  Future<void> setLastOpened(RagScope scope, String conversationId) async {
    await _prefs.setString('$_kLastOpenedPrefix${scope.value}', conversationId);
  }

  // ─── Health cache (30s TTL) ─────────────────────────────────────────────

  Future<void> cacheHealth(bool online, {int? nVectors}) async {
    await _prefs.setString(
      _kHealthCachePrefix,
      jsonEncode({
        'online': online,
        'ts': DateTime.now().toIso8601String(),
        'nVectors': nVectors,
      }),
    );
  }

  ({bool online, DateTime ts, int? nVectors})? getCachedHealth() {
    final raw = _prefs.getString(_kHealthCachePrefix);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        online: json['online'] as bool? ?? false,
        ts: DateTime.parse(json['ts'] as String),
        nVectors: json['nVectors'] as int?,
      );
    } catch (_) {
      return null;
    }
  }
}
