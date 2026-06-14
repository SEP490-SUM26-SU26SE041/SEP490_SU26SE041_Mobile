import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class StudentChatMessage {
  const StudentChatMessage({required this.text, required this.isUser, required this.time});
  final String text;
  final bool isUser;
  final DateTime time;
}

final studentChatProvider = StateProvider<List<StudentChatMessage>>((ref) => []);

class StudentChatScreen extends ConsumerStatefulWidget {
  const StudentChatScreen({super.key});

  @override
  ConsumerState<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends ConsumerState<StudentChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      ref.read(studentChatProvider.notifier).state = [
        ...ref.read(studentChatProvider),
        StudentChatMessage(text: text, isUser: true, time: DateTime.now()),
      ];
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        ref.read(studentChatProvider.notifier).state = [
          ...ref.read(studentChatProvider),
          StudentChatMessage(
            text: _getBotReply(text),
            isUser: false,
            time: DateTime.now(),
          ),
        ];
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getBotReply(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('cà chua') || lower.contains('tomato') || lower.contains('cherry')) {
      return 'Cà chua bi Cherry 101 là giống cây trồng phù hợp với khí hậu Việt Nam. Nhiệt độ lý tưởng: 22-28°C, độ ẩm: 60-70%. Bạn cần tư vấn thêm về cách chăm sóc không?';
    }
    if (lower.contains('tưới') || lower.contains('nước') || lower.contains('độ ẩm')) {
      return 'Nên tưới nước vào sáng sớm (6-8h) hoặc chiều muộn (17-19h) để giảm thiểu bay hơi. Lượng nước phụ thuộc vào giai đoạn sinh trưởng - giai đoạn cây con cần ít nước hơn giai đoạn ra hoa.';
    }
    if (lower.contains('phân') || lower.contains('bón') || lower.contains('npk')) {
      return 'Phân bón NPK tỷ lệ 20-20-20 phù hợp cho giai đoạn phát triển. Giai đoạn ra hoa cần bổ sung phân có hàm lượng P cao hơn. Giai đoạn quả non cần bổ sung K để quả to và ngọt hơn.';
    }
    if (lower.contains('lá') || lower.contains('vàng') || lower.contains('sâu') || lower.contains('bệnh')) {
      return 'Lá vàng có thể do thiếu dinh dưỡng, tưới quá nhiều nước, hoặc bệnh nấm. Bạn nên kiểm tra: 1) Màu lá vàng từ đâu? 2) Có đốm nấm không? 3) Đất có bị úng nước không? Hãy mô tả thêm để tôi tư vấn chính xác hơn.';
    }
    if (lower.contains('chiều cao') || lower.contains('tăng trưởng') || lower.contains('đo')) {
      return 'Để đo chiều cao cây, dùng thước đo từ gốc đến đỉnh ngọn. Nên đo vào buổi sáng, cùng một thời điểm mỗi ngày để đảm bảo tính chính xác. Ghi nhận kết quả vào nhật ký tăng trưởng để theo dõi sự phát triển.';
    }
    return 'Cảm ơn bạn đã hỏi! Là sinh viên, bạn có thể hỏi về cách quan sát cây, ghi chép dữ liệu, nhận biết bệnh thông thường trên cây trồng. Bạn muốn tìm hiểu thêm về chủ đề nào?';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final messages = ref.watch(studentChatProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Assistant', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(
              'Context: Student - Crop Observation',
              style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128)),
            ),
          ],
        ),
        backgroundColor: cs.surface,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                ref.read(studentChatProvider.notifier).state = [];
              });
            },
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Xóa cuộc trò chuyện',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              border: Border(
                bottom: BorderSide(color: AppColors.primary.withAlpha(30)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Student',
                        style: tt.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Tư vấn về quan sát cây trồng, ghi chép dữ liệu, nhận biết bệnh thông thường',
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? _WelcomeView(tt: tt, cs: cs)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == messages.length) {
                        return _TypingIndicator();
                      }
                      return _StudentMessageBubble(
                        message: messages[index],
                        tt: tt,
                        cs: cs,
                      );
                    },
                  ),
          ),
          _StudentInputBar(
            controller: _controller,
            onSend: _send,
            tt: tt,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.tt, required this.cs});
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
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
              'AI Student Assistant',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tư vấn về quan sát cây trồng,\nghi chép dữ liệu, và nhận biết bệnh',
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                _QuickChip(label: 'Quan sát cây', tt: tt),
                _QuickChip(label: 'Chiều cao', tt: tt),
                _QuickChip(label: 'Bệnh lá', tt: tt),
                _QuickChip(label: 'Ghi chép', tt: tt),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.tt});
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

class _StudentMessageBubble extends StatelessWidget {
  const _StudentMessageBubble({required this.message, required this.tt, required this.cs});
  final StudentChatMessage message;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.outline.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: tt.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.time),
                    style: tt.labelSmall?.copyWith(
                      color: (isUser ? Colors.white : cs.onSurface).withAlpha(128),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.outline.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(i)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot(this.index);
  final int index;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((100 + 100 * _controller.value).toInt()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _StudentInputBar extends StatelessWidget {
  const _StudentInputBar({
    required this.controller,
    required this.onSend,
    required this.tt,
    required this.cs,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outline.withAlpha(51)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outline.withAlpha(77)),
              ),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: tt.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Hỏi về quan sát cây trồng...',
                  hintStyle: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withAlpha(77),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: IconButton(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
