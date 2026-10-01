import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/rag_models.dart';
import '../providers/rag_providers.dart';
import 'widgets/conversation_drawer.dart';
import 'widgets/knowledge_group_filter.dart';
import 'widgets/rag_input_bar.dart';
import 'widgets/rag_message_bubble.dart';
import 'widgets/retrieval_only_toggle.dart';
import 'widgets/typing_indicator.dart';

/// Main RAG Chat Screen — dùng chung cho Student + Technician.
///
/// Scope được truyền vào để tách conversation history theo role
/// (mỗi role có danh sách conversation RIÊNG).
class RagChatScreen extends ConsumerStatefulWidget {
  const RagChatScreen({super.key, required this.scope});

  final RagScope scope;

  @override
  ConsumerState<RagChatScreen> createState() => _RagChatScreenState();
}

class _RagChatScreenState extends ConsumerState<RagChatScreen> {
  final _scrollController = ScrollController();
  String? _lastSeenConvId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(maxScroll);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ragChatProvider(widget.scope));
    final notifier = ref.read(ragChatProvider(widget.scope).notifier);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final healthAsync = ref.watch(ragHealthProvider);

    // Auto-scroll khi conversation đổi hoặc có message mới.
    final convId = state.currentConversationId;
    if (convId != _lastSeenConvId) {
      _lastSeenConvId = convId;
      _scrollToBottom(animate: false);
    } else if (state.messages.isNotEmpty) {
      _scrollToBottom();
    }

    final isStudent = widget.scope == RagScope.student;
    final hintText = isStudent
        ? 'Hỏi về kỹ thuật canh tác, bệnh cây, cách đo chỉ số...'
        : 'Hỏi về phương pháp tưới, phân bón, cảm biến, bệnh cây...';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: ConversationDrawer(scope: widget.scope),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🌾 ${isStudent ? "AI Student" : "AI Technician"}',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: AppSpacing.sm),
                healthAsync.when(
                  data: (h) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: h.online ? AppColors.success : AppColors.error,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  error: (_, _) => Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              isStudent
                  ? 'Hỏi đáp nông nghiệp · context Student'
                  : 'Tra cứu kỹ thuật · context Technician',
              style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128)),
            ),
          ],
        ),
        backgroundColor: cs.surface,
        actions: [
          IconButton(
            tooltip: 'Cuộc hội thoại mới',
            onPressed: () => notifier.createNewConversation(),
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Context banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: (isStudent ? AppColors.primary : AppColors.info)
                  .withAlpha(15),
              border: Border(
                bottom: BorderSide(
                  color:
                      (isStudent ? AppColors.primary : AppColors.info).withAlpha(40),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isStudent ? AppColors.primary : AppColors.info).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isStudent
                            ? Icons.school_rounded
                            : Icons.handyman_rounded,
                        size: 14,
                        color: isStudent ? AppColors.primary : AppColors.info,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isStudent ? 'Student' : 'Technician',
                        style: tt.labelSmall?.copyWith(
                          color: isStudent ? AppColors.primary : AppColors.info,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isStudent
                        ? '🌱 Tra cứu tài liệu nông nghiệp, học tập & ghi chép'
                        : '🔧 Tra cứu kỹ thuật canh tác & vận hành',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(153),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Cold-start warning
          healthAsync.maybeWhen(
            data: (h) {
              if (!h.online) {
                return _WarningBanner(
                  text:
                      '⚠️ Server đang ngủ (Render free plan). Request đầu tiên có thể mất 30-60s.',
                  color: AppColors.warning,
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
          // Knowledge group filter
          const SizedBox(height: AppSpacing.xs),
          KnowledgeGroupFilter(
            selected: state.knowledgeGroup,
            onChanged: notifier.setKnowledgeGroup,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Retrieval-only toggle
          RetrievalOnlyToggle(
            value: state.retrievalOnly,
            onChanged: notifier.setRetrievalOnly,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Error banner
          if (state.error != null)
            _WarningBanner(
              text: state.error!,
              color: AppColors.error,
              onClose: notifier.clearError,
            ),
          // Messages
          Expanded(
            child: state.messages.isEmpty
                ? _WelcomeView(tt: tt, cs: cs, isStudent: isStudent)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: state.messages.length + (state.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.isSending && index == state.messages.length) {
                        return const RagTypingIndicator();
                      }
                      final m = state.messages[index];
                      if (m.role == 'user') {
                        return RagUserBubble(message: m);
                      }
                      return RagAssistantBubble(
                        message: m,
                        isRetrievalOnly: state.retrievalOnly,
                      );
                    },
                  ),
          ),
          RagInputBar(
            onSend: notifier.sendMessage,
            isSending: state.isSending,
            hintText: hintText,
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.text,
    required this.color,
    this.onClose,
  });

  final String text;
  final Color color;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        onClose != null ? AppSpacing.xs : AppSpacing.md,
        AppSpacing.sm,
      ),
      color: color.withAlpha(20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: tt.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 16, color: color),
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({
    required this.tt,
    required this.cs,
    required this.isStudent,
  });

  final TextTheme tt;
  final ColorScheme cs;
  final bool isStudent;

  @override
  Widget build(BuildContext context) {
    final suggestions = isStudent
        ? const ['Cách phòng bệnh đạo ôn?', 'Chiều cao cây tiêu chuẩn?', 'Cách đo đường kính thân?', 'Phân bón cho cà chua?']
        : const ['Phương pháp tưới nhỏ giọt?', 'Cảm biến độ ẩm đất?', 'Triệu chứng bệnh héo xanh?', 'Bón phân NPK cho lúa?'];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isStudent ? 'AI Student Assistant' : 'AI Technician Assistant',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isStudent
                  ? 'Tra cứu tài liệu nông nghiệp từ RAG knowledge base.\nHỗ trợ citation đầy đủ.'
                  : 'Tra cứu kỹ thuật canh tác & vận hành cảm biến.\nCó trích dẫn nguồn PDF.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                for (final s in suggestions)
                  _SuggestionChip(label: s, tt: tt),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.tt});
  final String label;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Text(
        label,
        style: tt.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
