import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/rag_api_client.dart';
import '../data/rag_models.dart';
import '../storage/conversation_storage.dart';

/// ─── Riverpod Providers cho RAG Chat ──────────────────────────────────────────

final _uuid = const Uuid();

/// API client singleton.
final ragApiClientProvider = Provider<RagApiClient>((ref) => RagApiClient());

/// SharedPreferences cần được override ở root (app.dart).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

/// Storage layer.
final ragStorageProvider = Provider<RagConversationStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RagConversationStorage(prefs);
});

/// Health state (cache 30s).
final ragHealthProvider = FutureProvider<RagHealth>((ref) async {
  final storage = ref.watch(ragStorageProvider);
  final cached = storage.getCachedHealth();
  if (cached != null && DateTime.now().difference(cached.ts).inSeconds < 30) {
    return RagHealth(
      online: cached.online,
      indexLoaded: cached.online,
      nVectors: cached.nVectors ?? 0,
    );
  }
  final api = ref.watch(ragApiClientProvider);
  final health = await api.checkHealth();
  await storage.cacheHealth(health.online, nVectors: health.nVectors);
  return health;
});

/// ─── Chat State cho 1 scope ──────────────────────────────────────────────────

class RagChatState {
  RagChatState({
    this.currentConversationId,
    this.conversations = const [],
    this.messages = const [],
    this.knowledgeGroup,
    this.retrievalOnly = true,
    this.isSending = false,
    this.error,
  });

  final String? currentConversationId;
  final List<RagConversation> conversations;
  final List<RagStoredMessage> messages;
  final String? knowledgeGroup;
  final bool retrievalOnly;
  final bool isSending;
  final String? error;

  RagConversation? get currentConversation {
    if (currentConversationId == null) return null;
    try {
      return conversations.firstWhere((c) => c.id == currentConversationId);
    } catch (_) {
      return null;
    }
  }

  RagChatState copyWith({
    String? currentConversationId,
    bool resetCurrent = false,
    List<RagConversation>? conversations,
    List<RagStoredMessage>? messages,
    String? knowledgeGroup,
    bool? retrievalOnly,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return RagChatState(
      currentConversationId: resetCurrent
          ? null
          : (currentConversationId ?? this.currentConversationId),
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      knowledgeGroup: knowledgeGroup ?? this.knowledgeGroup,
      retrievalOnly: retrievalOnly ?? this.retrievalOnly,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Per-scope notifier: mỗi role có 1 instance riêng (qua family).
class RagChatNotifier extends StateNotifier<RagChatState> {
  RagChatNotifier({
    required this.scope,
    required this.ref,
  }) : super(RagChatState()) {
    _bootstrap();
  }

  final RagScope scope;
  final Ref ref;

  Future<void> _bootstrap() async {
    final storage = ref.read(ragStorageProvider);
    final conversations = await storage.loadConversations(scope);
    final lastId = await storage.getLastOpened(scope);
    String? currentId;
    List<RagStoredMessage> messages = const [];

    if (lastId != null && conversations.any((c) => c.id == lastId)) {
      currentId = lastId;
      messages = await storage.loadMessages(lastId);
    } else if (conversations.isNotEmpty) {
      // Fallback: chọn conversation mới nhất.
      currentId = conversations.first.id;
      messages = await storage.loadMessages(currentId);
    }

    state = state.copyWith(
      conversations: conversations,
      currentConversationId: currentId,
      messages: messages,
    );
  }

  // ─── Conversation management ───────────────────────────────────────────

  Future<String> createNewConversation() async {
    final storage = ref.read(ragStorageProvider);
    final now = DateTime.now();
    final conv = RagConversation(
      id: _uuid.v4(),
      title: 'Cuộc hội thoại mới',
      createdAt: now,
      updatedAt: now,
      scope: scope,
      knowledgeGroup: state.knowledgeGroup,
      retrievalOnly: state.retrievalOnly,
    );
    await storage.upsertConversation(conv);
    await storage.setLastOpened(scope, conv.id);
    final conversations = await storage.loadConversations(scope);
    state = state.copyWith(
      currentConversationId: conv.id,
      conversations: conversations,
      messages: const [],
      clearError: true,
    );
    return conv.id;
  }

  Future<void> switchConversation(String id) async {
    final storage = ref.read(ragStorageProvider);
    final messages = await storage.loadMessages(id);
    await storage.setLastOpened(scope, id);
    state = state.copyWith(
      currentConversationId: id,
      messages: messages,
      clearError: true,
    );
  }

  Future<void> renameConversation(String id, String newTitle) async {
    final storage = ref.read(ragStorageProvider);
    final conv = state.conversations.firstWhere((c) => c.id == id);
    conv.title = newTitle;
    conv.updatedAt = DateTime.now();
    await storage.upsertConversation(conv);
    final conversations = await storage.loadConversations(scope);
    state = state.copyWith(conversations: conversations);
  }

  Future<void> deleteConversation(String id) async {
    final storage = ref.read(ragStorageProvider);
    await storage.deleteConversation(scope, id);
    final conversations = await storage.loadConversations(scope);
    String? newCurrentId;
    List<RagStoredMessage> newMessages = const [];
    if (state.currentConversationId == id) {
      if (conversations.isNotEmpty) {
        newCurrentId = conversations.first.id;
        newMessages = await storage.loadMessages(newCurrentId);
        await storage.setLastOpened(scope, newCurrentId);
      } else {
        await storage.setLastOpened(scope, '');
      }
    } else {
      newCurrentId = state.currentConversationId;
      newMessages = state.messages;
    }
    state = state.copyWith(
      currentConversationId: newCurrentId,
      conversations: conversations,
      messages: newMessages,
    );
  }

  Future<void> clearAllConversations() async {
    final storage = ref.read(ragStorageProvider);
    await storage.deleteAllConversations(scope);
    state = state.copyWith(
      resetCurrent: true,
      conversations: const [],
      messages: const [],
    );
  }

  // ─── Settings ──────────────────────────────────────────────────────────

  void setKnowledgeGroup(String? value) {
    state = state.copyWith(knowledgeGroup: value);
    // Update current conversation's group.
    final conv = state.currentConversation;
    if (conv != null) {
      conv.knowledgeGroup = value;
      ref.read(ragStorageProvider).upsertConversation(conv);
    }
  }

  void setRetrievalOnly(bool value) {
    state = state.copyWith(retrievalOnly: value);
    final conv = state.currentConversation;
    if (conv != null) {
      conv.retrievalOnly = value;
      ref.read(ragStorageProvider).upsertConversation(conv);
    }
  }

  // ─── Send message ──────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    // Đảm bảo có conversation hiện tại.
    String currentId = state.currentConversationId ?? '';
    if (currentId.isEmpty) {
      currentId = await createNewConversation();
    }

    final storage = ref.read(ragStorageProvider);

    // 1. Append user message (optimistic).
    final userMsg = RagStoredMessage(
      id: 0, // auto
      conversationId: currentId,
      role: 'user',
      content: trimmed,
      ts: DateTime.now(),
    );
    await storage.appendMessage(currentId, userMsg);
    final messagesAfterUser = await storage.loadMessages(currentId);

    // Auto-title từ câu đầu tiên (mục 4.1).
    final conv = state.conversations.firstWhere((c) => c.id == currentId);
    if (conv.title == 'Cuộc hội thoại mới' ||
        conv.title.startsWith('Cuộc hội thoại')) {
      conv.title = trimmed.length > 60 ? '${trimmed.substring(0, 57)}...' : trimmed;
      conv.updatedAt = DateTime.now();
      await storage.upsertConversation(conv);
    } else {
      conv.updatedAt = DateTime.now();
      await storage.upsertConversation(conv);
    }
    final conversationsAfterUser = await storage.loadConversations(scope);

    state = state.copyWith(
      conversations: conversationsAfterUser,
      messages: messagesAfterUser,
      isSending: true,
      clearError: true,
    );

    // 2. Build history (12 messages gần nhất theo spec).
    final history = <RagHistoryItem>[];
    for (final RagStoredMessage m in messagesAfterUser) {
      history.add(RagHistoryItem(role: m.role, content: m.content));
    }

    // 3. Gọi API.
    final api = ref.read(ragApiClientProvider);
    try {
      final result = await api.chat(
        question: trimmed,
        history: history.sublist(0, history.length - 1), // bỏ câu hiện tại đã là question
        knowledgeGroup: state.knowledgeGroup,
        retrievalOnly: state.retrievalOnly,
      );

      // 4. Append assistant message.
      final assistantMsg = RagStoredMessage(
        id: 0,
        conversationId: currentId,
        role: 'assistant',
        content: result.success ? result.answer : (result.error ?? 'Đã có lỗi xảy ra.'),
        ts: DateTime.now(),
        sources: result.sources,
      );
      await storage.appendMessage(currentId, assistantMsg);
      final messagesAfterAssistant = await storage.loadMessages(currentId);

      // Invalidate health cache nếu lỗi để force refresh lần sau.
      if (!result.success) {
        ref.invalidate(ragHealthProvider);
      }

      state = state.copyWith(
        messages: messagesAfterAssistant,
        isSending: false,
        error: result.success ? null : (result.error ?? 'Lỗi không xác định'),
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Lỗi kết nối: $e',
      );
    }
  }

  /// Stop typing + bỏ error.
  void clearError() => state = state.copyWith(clearError: true);
}

/// Per-scope notifier (mỗi role có 1 instance riêng).
final ragChatProvider =
    StateNotifierProvider.family<RagChatNotifier, RagChatState, RagScope>(
  (ref, scope) => RagChatNotifier(scope: scope, ref: ref),
);
