import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/mock_ai_scan.dart';
import 'providers/ai_scan_provider.dart';
import 'widgets/scan_hero_section.dart';
import 'widgets/scan_result_bento.dart';
import 'widgets/treatments_section.dart';
import 'widgets/detection_overlay.dart';
import 'widgets/detection_list_section.dart';

/// Màn hình AI Scan — kết nối 2 API backend:
///   • Tab 1: Chẩn đoán bệnh lá cà chua (NhanDangBenhLaCaChua)
///   • Tab 2: Chẩn đoán sâu bệnh (Argo_Pest)
///
/// Flow: pick image → loading → show result (bento + treatments).
class AiScanScreen extends ConsumerStatefulWidget {
  const AiScanScreen({super.key});

  @override
  ConsumerState<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends ConsumerState<AiScanScreen>
    with TickerProviderStateMixin {
  late final TabController _tab;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _showImageSourceSheet(String plantType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(
        onCamera: () => _pickImage(ImageSource.camera, plantType),
        onGallery: () => _pickImage(ImageSource.gallery, plantType),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, String plantType) async {
    Navigator.pop(context);
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // Reset state của plantType hiện tại trước khi scan (tránh hiển thị kết quả cũ).
        ref.read(aiScanProvider.notifier).reset(plantType);
        await ref.read(aiScanProvider.notifier).scanImage(
              File(image.path),
              plantType: plantType,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _AiScanTopBar(user: user),
            Container(
              color: cs.surface,
              child: TabBar(
                controller: _tab,
                labelStyle: tt.titleSmall,
                unselectedLabelStyle: tt.titleSmall,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: cs.onSurface.withAlpha(128),
                tabs: const [
                  Tab(text: 'Chẩn đoán lá cà chua'),
                  Tab(text: 'Chẩn đoán sâu bệnh'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _ScanTab(
                    plantType: 'tomato',
                    onScanPressed: () => _showImageSourceSheet('tomato'),
                    accentIcon: Icons.eco_rounded,
                    accentColor: AppColors.primary,
                  ),
                  _ScanTab(
                    plantType: 'pest',
                    onScanPressed: () => _showImageSourceSheet('pest'),
                    accentIcon: Icons.bug_report_rounded,
                    accentColor: AppColors.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Image Source Bottom Sheet ────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Chọn nguồn ảnh',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _SourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Chụp ảnh',
                    subtitle: 'Dùng camera để chụp lá cây',
                    onTap: onCamera,
                  ),
                  const SizedBox(height: 12),
                  _SourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Chọn từ thư viện',
                    subtitle: 'Chọn ảnh đã lưu trên thiết bị',
                    onTap: onGallery,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon, required this.label,
    required this.subtitle, required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab content: Scan (hero + result + treatments) ──────────────────────────
class _ScanTab extends ConsumerWidget {
  const _ScanTab({
    required this.plantType,
    required this.onScanPressed,
    required this.accentIcon,
    required this.accentColor,
  });

  final String plantType;
  final VoidCallback onScanPressed;
  final IconData accentIcon;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mỗi tab watch state RIÊNG theo plantType → tab tomato lỗi không ảnh hưởng tab pest.
    final scanState = ref.watch(aiScanStateProvider(plantType));

    return switch (scanState) {
      AiScanLoading() => _ScanLoadingView(plantType: plantType, accentColor: accentColor),
      AiScanError(message: final msg) => _ScanErrorView(
          message: msg,
          onRetry: onScanPressed,
          accentColor: accentColor,
        ),
      AiScanSuccess(result: final result) => _ScanResultView(
          result: result,
          onScanAgain: onScanPressed,
        ),
      AiScanInitial() => _ScanInitialView(
          onScanPressed: onScanPressed,
          plantType: plantType,
          accentIcon: accentIcon,
          accentColor: accentColor,
        ),
    };
  }
}

class _ScanInitialView extends StatelessWidget {
  const _ScanInitialView({
    required this.onScanPressed,
    required this.plantType,
    required this.accentIcon,
    required this.accentColor,
  });

  final VoidCallback onScanPressed;
  final String plantType;
  final IconData accentIcon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final title = plantType == 'tomato'
        ? 'Chẩn đoán bệnh lá cà chua'
        : 'Chẩn đoán sâu bệnh cây trồng';
    final subtitle = plantType == 'tomato'
        ? 'Chụp ảnh hoặc tải lên ảnh lá cà chua để AI phát hiện bệnh và đưa ra hướng xử lý.'
        : 'Chụp ảnh hoặc tải lên ảnh lá/cây để AI phát hiện sâu bệnh và đưa ra khuyến nghị.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScanHeroSection(
            imageUrl: MockAiScan.currentResult.scanImageUrl,
            onScanPressed: onScanPressed,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentColor.withAlpha(60), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(accentIcon, color: accentColor, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanLoadingView extends StatelessWidget {
  const _ScanLoadingView({required this.plantType, required this.accentColor});
  final String plantType;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = plantType == 'tomato'
        ? 'Đang phân tích lá cà chua...'
        : 'Đang phát hiện sâu bệnh...';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64, height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI đang xử lý ảnh để phân tích.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(153),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanErrorView extends StatelessWidget {
  const _ScanErrorView({
    required this.message,
    required this.onRetry,
    required this.accentColor,
  });

  final String message;
  final VoidCallback onRetry;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Không thể phân tích ảnh',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(153),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(backgroundColor: accentColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanResultView extends StatelessWidget {
  const _ScanResultView({required this.result, required this.onScanAgain});
  final DiseaseResult result;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final accentColor =
        result.plantType == 'pest' ? AppColors.warning : AppColors.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ảnh scan + bbox overlay (nếu có detections).
          // Stack để overlay bbox/chữ "Khoanh vùng" lên trên ảnh gốc.
          Stack(
            children: [
              ScanHeroSection(
                imageUrl: result.scanImageUrl,
                isResult: true,
                onScanPressed: () {},
              ),
              if (result.hasAnnotatedImage ||
                  result.detections.any((d) => d.box != null))
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: DetectionOverlay(
                      detections: result.detections,
                      imageWidth: result.imageWidth,
                      imageHeight: result.imageHeight,
                      annotatedImageBytes: result.annotatedImageBytes,
                      borderColor: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Caption: loại ảnh đã xem (annotated từ server, hoặc do client paint).
          if (result.hasAnnotatedImage)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    'Ảnh đã được AI khoanh vùng sẵn',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurface.withAlpha(178)),
                  ),
                ],
              ),
            )
          else if (result.detections.any((d) => d.box != null))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.center_focus_strong_rounded,
                      size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    'Vùng nghi ngờ đã được khoanh trên ảnh',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurface.withAlpha(178)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          ScanResultBento(result: result),
          const SizedBox(height: 16),
          if (result.detections.isNotEmpty)
            DetectionListSection(
              detections: result.detections,
              imageWidth: result.imageWidth,
              imageHeight: result.imageHeight,
              accentColor: accentColor,
            ),
          if (result.detections.isNotEmpty && result.probabilities.isNotEmpty)
            const SizedBox(height: 16),
          if (result.probabilities.isNotEmpty)
            ProbabilitiesSection(
              probabilities: result.probabilities,
              accentColor: accentColor,
            ),
          if (result.detections.isNotEmpty ||
              result.probabilities.isNotEmpty)
            const SizedBox(height: 16),
          if (result.treatments.isNotEmpty)
            TreatmentsSection(items: result.treatments),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Chụp / chọn ảnh khác'),
          ),
        ],
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────
class _AiScanTopBar extends StatelessWidget {
  const _AiScanTopBar({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(230),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(40),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Icon(Icons.eco_rounded,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nong Lam Smart',
              style: tt.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              final role = user?.role;
              if (role == UserRole.researcher) {
                context.go('/notifications');
              } else if (role == UserRole.student) {
                context.go('/student/chat');
              } else {
                context.go('/tech/chat');
              }
            },
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Thông báo',
          ),
        ],
      ),
    );
  }
}