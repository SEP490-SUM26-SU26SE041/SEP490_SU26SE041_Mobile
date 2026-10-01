import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/rag_models.dart';
import '../../providers/rag_providers.dart';
import 'conversation_list_section.dart';

/// Drawer hiển thị danh sách conversation, group theo ngày
/// (mục 4.1: Hôm nay / Hôm qua / Tuần này / Cũ hơn).
class ConversationDrawer extends ConsumerWidget {
  const ConversationDrawer({super.key, required this.scope});

  final RagScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ragChatProvider(scope));
    final notifier = ref.read(ragChatProvider(scope).notifier);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    // Group conversations theo bucket.
    final grouped = <ConversationDayBucket, List<RagConversation>>{};
    for (final c in state.conversations) {
      final b = bucketForDay(c.updatedAt);
      grouped.putIfAbsent(b, () => []).add(c);
    }
    // Sort từng bucket theo updatedAt desc.
    for (final list in grouped.values) {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return Drawer(
      backgroundColor: cs.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lịch sử hội thoại',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          scope == RagScope.student
                              ? '🌱 Student RAG'
                              : '🔧 Technician RAG',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // New chat button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: () async {
                    await notifier.createNewConversation();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Cuộc hội thoại mới'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            // List grouped
            Expanded(
              child: state.conversations.isEmpty
                  ? _emptyState(cs, tt)
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      children: [
                        for (final bucket in [
                          ConversationDayBucket.today,
                          ConversationDayBucket.yesterday,
                          ConversationDayBucket.thisWeek,
                          ConversationDayBucket.older,
                        ])
                          if (grouped[bucket] != null &&
                              grouped[bucket]!.isNotEmpty)
                            ConversationListSection(
                              title: bucket.label,
                              conversations: grouped[bucket]!,
                              selectedId: state.currentConversationId,
                              onTap: (id) async {
                                await notifier.switchConversation(id);
                                if (context.mounted) Navigator.of(context).pop();
                              },
                              onDelete: (id) async {
                                final confirmed = await _confirmDelete(context, tt);
                                if (confirmed == true) {
                                  await notifier.deleteConversation(id);
                                }
                              },
                              onRename: (id, current) async {
                                final newTitle = await _promptRename(
                                    context, tt, current);
                                if (newTitle != null && newTitle.trim().isNotEmpty) {
                                  await notifier.renameConversation(id, newTitle.trim());
                                }
                              },
                            ),
                      ],
                    ),
            ),
            // Footer: Clear all
            if (state.conversations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirmed = await _confirmClearAll(context, tt);
                      if (confirmed == true) {
                        await notifier.clearAllConversations();
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16,
                        color: AppColors.error),
                    label: const Text(
                      'Xóa tất cả',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: cs.onSurface.withAlpha(80)),
            const SizedBox(height: AppSpacing.md),
            Text('Chưa có cuộc hội thoại',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Bắt đầu bằng cách bấm nút "Cuộc hội thoại mới" ở trên',
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, TextTheme tt) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🗑️  ', style: TextStyle(fontSize: 22)),
            Text('Xóa cuộc hội thoại?'),
          ],
        ),
        content: const Text(
          'Cuộc hội thoại sẽ bị xóa vĩnh viễn.\nKhông thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmClearAll(BuildContext context, TextTheme tt) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🗑️  ', style: TextStyle(fontSize: 22)),
            Text('Xóa tất cả?'),
          ],
        ),
        content: const Text(
          'Toàn bộ lịch sử hội thoại sẽ bị xóa.\nKhông thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptRename(
      BuildContext context, TextTheme tt, String current) {
    final c = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đổi tên cuộc hội thoại'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tên mới...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(c.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
