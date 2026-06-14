import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class TechnicianChatScreen extends StatefulWidget {
  const TechnicianChatScreen({super.key});

  @override
  State<TechnicianChatScreen> createState() => _TechnicianChatScreenState();
}

class _TechnicianChatScreenState extends State<TechnicianChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = _initialMessages;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trợ lý Kỹ thuật', style: tt.titleMedium),
            Text(
              'Tư vấn chăm sóc cây & vận hành cảm biến',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: cs.outline.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Nhập câu hỏi của bạn...',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        id: 'msg-${_messages.length + 1}',
        role: 'user',
        content: text,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            id: 'msg-${_messages.length + 1}',
            role: 'assistant',
            content: _getAssistantResponse(text),
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
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

  String _getAssistantResponse(String question) {
    final q = question.toLowerCase();
    if (q.contains('tưới') || q.contains('nước')) {
      return 'Về phương pháp tưới cho cây cà chua:\n\n• Giai đoạn vườn ươm: Tưới phun sương 2-3 lần/ngày, 100-150ml/cây.\n• Giai đoạn cây con: Tưới nhỏ giọt hoặc tưới rãnh, 200-300ml/cây/ngày.\n• Giai đoạn ra hoa quả: Tưới đều đặn, tránh để đất khô hoặc úng nước.\n\n💡 Mẹo: Cảm biến độ ẩm đất nên duy trì ở mức 60-70% cho cà chua.';
    } else if (q.contains('phân') || q.contains('bón')) {
      return 'Về bón phân cho cà chua bi:\n\n• Giai đoạn cây con: NPK 20-20-20, 5g/cây, 7-10 ngày/lần.\n• Giai đoạn ra hoa: Tăng Kali (NPK 15-15-30), hỗ trợ ra hoa và đậu quả.\n• Giai đoạn quả non: Bổ sung Canxi để tránh nứt trái.\n\n⚠️ Lưu ý: Không bón phân khi đất quá khô.';
    } else if (q.contains('cảm biến') || q.contains('sensor')) {
      return 'Về vận hành cảm biến:\n\n🌡️ **Nhiệt độ**: Mức tối ưu 22-28°C, cảnh báo >32°C hoặc <18°C.\n\n💧 **Độ ẩm**: Duy trì 60-75%, cảnh báo <50% hoặc >85%.\n\n🌱 **Độ ẩm đất**: 60-70%, tưới khi <50%.\n\n📊 Kiểm tra định kỳ: Lau sensor, kiểm tra pin, hiệu chuẩn 1 tháng/lần.';
    } else if (q.contains('bệnh') || q.contains('sâu')) {
      return 'Về các bệnh phổ biến trên cà chua:\n\n🦠 **Bệnh héo xanh vi khuẩn**: Lá héo từ dưới lên, cắt thân có dòng trắng đục. Loại bỏ cây bệnh, khử trùng dụng cụ.\n\n🍂 **Bệnh xoắn đầu**: Do thiếu Canxi hoặc tưới không đều. Bổ sung Canxi, điều chỉnh tưới.\n\n🕷️ **Nhện đỏ**: Xuất hiện trên mặt dưới lá, sợi tơ nhện. Phun nước xà phòng hoặc dầu neem.';
    } else {
      return 'Cảm ơn bạn đã hỏi! Để được tư vấn chi tiết hơn, bạn có thể hỏi về:\n\n• Phương pháp tưới nước\n• Kỹ thuật bón phân\n• Vận hành cảm biến\n• Nhận diện & xử lý bệnh cây\n\nTôi sẵn sàng hỗ trợ bạn 24/7! 🌱';
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: (isUser ? AppColors.primary : cs.outline).withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Trợ lý Kỹ thuật',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isUser ? Colors.white : cs.onSurface,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatTime(message.timestamp),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isUser
                        ? Colors.white.withAlpha(179)
                        : cs.onSurface.withAlpha(128),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
}

final _initialMessages = [
  _ChatMessage(
    id: 'msg-001',
    role: 'assistant',
    content: 'Xin chào! Tôi là Trợ lý Kỹ thuật của SNMS.\n\nTôi có thể hỗ trợ bạn về:\n• Phương pháp tưới tiêu\n• Kỹ thuật bón phân\n• Vận hành cảm biến\n• Nhận diện bệnh cây\n\nBạn cần tư vấn về vấn đề gì hôm nay? 🌱',
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
];
