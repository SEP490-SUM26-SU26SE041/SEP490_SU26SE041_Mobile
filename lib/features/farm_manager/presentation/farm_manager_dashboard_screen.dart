import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/agritech_environment_background.dart';
import '../../../shared/widgets/alert_banner.dart';
import '../../../shared/widgets/kpi_tile.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../mock/mock_farm.dart';
import '../../../mock/mock_experiments.dart';

class FarmManagerDashboardScreen extends StatelessWidget {
  const FarmManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pendingRequests = _getPendingRequests();

    return Scaffold(
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.dashboard,
        accentColor: AppColors.warning,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, tt),
                      const SizedBox(height: AppSpacing.lg),
                      if (pendingRequests.isNotEmpty) ...[
                        AlertBanner(
                          message: '${pendingRequests.length} yêu cầu thí nghiệm cần xem xét',
                          level: AlertLevel.info,
                          onTap: () => context.push('/fm/requests'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    _buildKPIGrid(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildQuickActions(context, tt, pendingRequests.isNotEmpty),
                    const SizedBox(height: AppSpacing.xl),
                    _buildActiveBatches(context, tt),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme tt) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chào buổi sáng', style: tt.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Quản lý Trại',
                style: tt.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
        const ProfileButton(),
      ],
    );
  }

  Widget _buildKPIGrid(BuildContext context) {
    final activeExperiments = mockExperiments
        .where((e) => e.status.name == 'active')
        .length;
    final availableBeds = _getAvailableBeds();
    final onlineSensors = _getOnlineSensors();
    final pendingRequests = _getPendingRequests().length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.2,
      children: [
        KPITile(
          label: 'Thí nghiệm đang chạy',
          value: activeExperiments.toString(),
          unit: 'exp',
          icon: Icons.science_rounded,
        ),
        KPITile(
          label: 'Luống trống',
          value: availableBeds.toString(),
          unit: 'beds',
          icon: Icons.grid_view_rounded,
        ),
        KPITile(
          label: 'Cảm biến online',
          value: onlineSensors.toString(),
          unit: 'sensors',
          icon: Icons.sensors_rounded,
          trend: '+3',
        ),
        KPITile(
          label: 'Yêu cầu chờ duyệt',
          value: pendingRequests.toString(),
          unit: 'req',
          icon: Icons.pending_actions_rounded,
          isAlert: pendingRequests > 0,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, TextTheme tt, bool hasPendingRequests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('Thao tác nhanh', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.assignment_turned_in_rounded,
                label: 'Duyệt yêu cầu',
                color: hasPendingRequests ? AppColors.primary : AppColors.info,
                onTap: hasPendingRequests
                    ? () => context.push('/fm/requests')
                    : null,
                badge: hasPendingRequests ? _getPendingRequests().length.toString() : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.check_circle_outlined,
                label: 'Đã duyệt',
                color: AppColors.primary,
                onTap: () => context.push('/fm/experiments'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.map_rounded,
                label: 'Bản đồ',
                color: AppColors.success,
                onTap: () => context.push('/fm/farm-map'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveBatches(BuildContext context, TextTheme tt) {
    final batches = _getActiveBatches();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.grass_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Lô cây đang hoạt động', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/fm/farm-map'),
              child: const Text('Xem bản đồ'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (batches.isEmpty)
          SNMSCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(Icons.grass_outlined,
                        size: 48, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Không có lô cây đang hoạt động',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: batches.map((batch) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _BatchOverviewCard(batch: batch),
            )).toList(),
          ),
      ],
    );
  }

  List<_PendingRequest> _getPendingRequests() {
    return [
      _PendingRequest(
        id: 'req-001',
        title: 'Thí nghiệm tưới nhỏ giọt mới',
        researcherName: 'TS. Nguyễn Minh Khoa',
        cropVariety: 'Cà chua bi',
        expectedStart: DateTime(2024, 7, 1),
        expectedEnd: DateTime(2024, 9, 30),
      ),
      _PendingRequest(
        id: 'req-002',
        title: 'So sánh giống ớt chuông',
        researcherName: 'TS. Trần Thị Lan',
        cropVariety: 'Ớt chuông',
        expectedStart: DateTime(2024, 8, 1),
        expectedEnd: DateTime(2024, 10, 31),
      ),
    ];
  }

  int _getAvailableBeds() {
    int count = 0;
    for (final area in mockFarm.areas) {
      for (final zone in area.zones) {
        for (final bed in zone.beds) {
          if (bed.status.name == 'available') {
            count++;
          }
        }
      }
    }
    return count;
  }

  int _getOnlineSensors() {
    int count = 0;
    for (final area in mockFarm.areas) {
      for (final zone in area.zones) {
        for (final bed in zone.beds) {
          for (final sensor in bed.sensors) {
            if (sensor.status.name == 'online') {
              count++;
            }
          }
        }
      }
    }
    return count;
  }

  List<_BatchOverview> _getActiveBatches() {
    return [
      _BatchOverview(
        batchCode: 'BATCH-CTRL-01',
        experimentTitle: 'So sánh phương pháp tưới',
        zoneName: 'Khu trồng cà chua',
        bedCode: 'B01',
        healthScore: 85,
        plantCount: 30,
      ),
      _BatchOverview(
        batchCode: 'BATCH-TRT-01',
        experimentTitle: 'So sánh phương pháp tưới',
        zoneName: 'Khu trồng cà chua',
        bedCode: 'B02',
        healthScore: 92,
        plantCount: 30,
      ),
    ];
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (badge != null)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                    child: Text(
                      badge!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BatchOverviewCard extends StatelessWidget {
  const _BatchOverviewCard({required this.batch});

  final _BatchOverview batch;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${batch.healthScore}',
                style: tt.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.batchCode,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  batch.experimentTitle,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(153),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: cs.onSurface.withAlpha(128)),
                    const SizedBox(width: 2),
                    Text(
                      '${batch.zoneName} - ${batch.bedCode}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withAlpha(128),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.eco_outlined,
                        size: 12, color: cs.onSurface.withAlpha(128)),
                    const SizedBox(width: 2),
                    Text(
                      '${batch.plantCount} cây',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getHealthColor(batch.healthScore).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getHealthLabel(batch.healthScore),
                  style: tt.labelSmall?.copyWith(
                    color: _getHealthColor(batch.healthScore),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _getHealthLabel(int score) {
    if (score >= 80) return 'Tốt';
    if (score >= 50) return 'Trung bình';
    return 'Kém';
  }
}

class _PendingRequest {
  const _PendingRequest({
    required this.id,
    required this.title,
    required this.researcherName,
    required this.cropVariety,
    required this.expectedStart,
    required this.expectedEnd,
  });

  final String id;
  final String title;
  final String researcherName;
  final String cropVariety;
  final DateTime expectedStart;
  final DateTime expectedEnd;
}

class _BatchOverview {
  const _BatchOverview({
    required this.batchCode,
    required this.experimentTitle,
    required this.zoneName,
    required this.bedCode,
    required this.healthScore,
    required this.plantCount,
  });

  final String batchCode;
  final String experimentTitle;
  final String zoneName;
  final String bedCode;
  final int healthScore;
  final int plantCount;
}
