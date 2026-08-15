import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// CTA card "Cần hỗ trợ từ chuyên gia?" với background gradient
/// giống section cuối trang web demo.
class ExpertAdvisoryCard extends StatelessWidget {
  const ExpertAdvisoryCard({super.key, required this.onRequestPressed});
  final VoidCallback onRequestPressed;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF154212),
            Color(0xFF1F5C18),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Glow blob top-right
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(50),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cần hỗ trợ từ chuyên gia?',
                style: tt.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Kết nối trực tiếp với kỹ sư nông nghiệp để nhận tư vấn chi tiết cho lô hàng này.',
                style: tt.bodyMedium?.copyWith(color: Colors.white.withAlpha(204)),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: onRequestPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Gửi yêu cầu ngay',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}