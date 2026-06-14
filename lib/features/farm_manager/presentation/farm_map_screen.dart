import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/snms_card.dart';
import '../../../shared/widgets/sensor_status_badge.dart';
import '../../../shared/models/farm_model.dart';
import '../../../mock/mock_farm.dart';
import '../../../mock/mock_experiments.dart';

class FarmMapScreen extends StatelessWidget {
  const FarmMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FarmOverview();
  }
}

class _FarmOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Bản đồ Trại', style: tt.titleLarge),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FarmCard(farm: mockFarm),
            const SizedBox(height: AppSpacing.xl),
            Text('Khu vực', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            ...mockFarm.areas.map((area) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _AreaCard(area: area),
            )),
          ],
        ),
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  const _FarmCard({required this.farm});

  final FarmModel farm;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.agriculture_rounded,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farm.farmName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(farm.farmCode,
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  farm.statusLabel,
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: cs.onSurface.withAlpha(153)),
              const SizedBox(width: AppSpacing.xs),
              Text(farm.location,
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Khu vực', value: farm.totalAreas.toString()),
              _StatItem(label: 'Vùng', value: farm.totalZones.toString()),
              _StatItem(label: 'Luống', value: farm.totalBeds.toString()),
              _StatItem(label: 'Trống', value: farm.availableBeds.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: tt.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(153)),
        ),
      ],
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area});

  final AreaModel area;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      onTap: () => context.push('/farm-manager/farm-map/area/${area.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.grid_view_rounded,
                    color: AppColors.info, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(area.areaName,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(area.environmentType,
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
                  ],
                ),
              ),
              _buildStatusBadge(context, area.statusLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.straighten_rounded,
                  size: 14, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${area.totalArea.toStringAsFixed(0)} m²',
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(153)),
              ),
              const SizedBox(width: AppSpacing.lg),
              Icon(Icons.layers_rounded,
                  size: 14, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${area.totalZones} vùng',
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(153)),
              ),
              const SizedBox(width: AppSpacing.lg),
              Icon(Icons.grid_view_rounded,
                  size: 14, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${area.availableBeds}/${area.totalBeds} luống trống',
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(153)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Xem chi tiết',
                style: tt.labelSmall?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String label) {
    final color = label == 'In Use'
        ? AppColors.success
        : label == 'Maintenance'
            ? AppColors.warning
            : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class AreaDetailScreen extends StatelessWidget {
  const AreaDetailScreen({super.key, required this.areaId});

  final String areaId;

  @override
  Widget build(BuildContext context) {
    final area = mockFarm.areas.firstWhere((a) => a.id == areaId);
    final tt = Theme.of(context).textTheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(area.areaName, style: tt.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AreaInfoCard(area: area),
            const SizedBox(height: AppSpacing.xl),
            Text('Vùng trồng', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.3,
              ),
              itemCount: area.zones.length,
              itemBuilder: (context, index) {
                final zone = area.zones[index];
                return _ZoneCard(zone: zone);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaInfoCard extends StatelessWidget {
  const _AreaInfoCard({required this.area});

  final AreaModel area;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Thông tin khu vực', style: tt.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Mã khu vực', value: area.areaCode),
          _InfoRow(label: 'Loại môi trường', value: area.environmentType),
          _InfoRow(label: 'Diện tích', value: '${area.totalArea.toStringAsFixed(0)} m²'),
          _InfoRow(label: 'Tổng vùng', value: '${area.totalZones} vùng'),
          _InfoRow(label: 'Tổng luống', value: '${area.totalBeds} luống'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
          Text(value, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone});

  final ZoneModel zone;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      onTap: () => context.push('/farm-manager/farm-map/zone/${zone.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(zone.zoneCode,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  _buildStatusBadge(context, zone.statusLabel),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                zone.zoneName,
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.grass_outlined, size: 12, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                zone.soilType,
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128)),
              ),
              const Spacer(),
              Icon(Icons.grid_view_rounded,
                  size: 12, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${zone.availableBeds}/${zone.totalBeds}',
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String label) {
    final color = label == 'In Use'
        ? AppColors.success
        : label == 'Maintenance'
            ? AppColors.warning
            : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}

class ZoneDetailScreen extends StatelessWidget {
  const ZoneDetailScreen({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context) {
    final zone = _findZone(zoneId);
    if (zone == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không tìm thấy')),
        body: const Center(child: Text('Vùng không tồn tại')),
      );
    }

    final tt = Theme.of(context).textTheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(zone.zoneName, style: tt.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ZoneInfoCard(zone: zone),
            const SizedBox(height: AppSpacing.xl),
            Text('Luống trồng', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.2,
              ),
              itemCount: zone.beds.length,
              itemBuilder: (context, index) {
                final bed = zone.beds[index];
                return _BedCard(bed: bed);
              },
            ),
          ],
        ),
      ),
    );
  }

  ZoneModel? _findZone(String zoneId) {
    for (final area in mockFarm.areas) {
      for (final zone in area.zones) {
        if (zone.id == zoneId) return zone;
      }
    }
    return null;
  }
}

class _ZoneInfoCard extends StatelessWidget {
  const _ZoneInfoCard({required this.zone});

  final ZoneModel zone;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Thông tin vùng', style: tt.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Mã vùng', value: zone.zoneCode),
          _InfoRow(label: 'Tên vùng', value: zone.zoneName),
          _InfoRow(label: 'Loại đất', value: zone.soilType),
          _InfoRow(label: 'Diện tích', value: '${zone.areaSize.toStringAsFixed(0)} m²'),
          _InfoRow(label: 'Tổng luống', value: '${zone.totalBeds} luống'),
          _InfoRow(label: 'Luống trống', value: '${zone.availableBeds} luống'),
        ],
      ),
    );
  }
}

class _BedCard extends StatelessWidget {
  const _BedCard({required this.bed});

  final BedModel bed;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      onTap: () => context.push('/farm-manager/farm-map/bed/${bed.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bed.bedCode,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  _buildStatusBadge(context, bed.statusLabel),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${bed.length}x${bed.width} m',
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.sensors_rounded, size: 12, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${bed.sensors.length} cảm biến',
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(128)),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String label) {
    final color = label == 'In Use'
        ? AppColors.success
        : label == 'Maintenance'
            ? AppColors.warning
            : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}

class BedDetailScreen extends StatelessWidget {
  const BedDetailScreen({super.key, required this.bedId});

  final String bedId;

  @override
  Widget build(BuildContext context) {
    final bed = _findBed(bedId);
    if (bed == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không tìm thấy')),
        body: const Center(child: Text('Luống không tồn tại')),
      );
    }

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final experiment = bed.experimentId != null
        ? mockExperiments.firstWhere(
            (e) => e.id == bed.experimentId,
            orElse: () => mockExperiments.first,
          )
        : null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Luống ${bed.bedCode}', style: tt.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BedInfoCard(bed: bed),
            const SizedBox(height: AppSpacing.xl),
            if (experiment != null) ...[
              _ExperimentAssignmentCard(experiment: experiment),
              const SizedBox(height: AppSpacing.xl),
            ],
            Text('Cảm biến (${bed.sensors.length})',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            if (bed.sensors.isEmpty)
              SNMSCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(Icons.sensors_off_rounded,
                            size: 48, color: cs.onSurface.withAlpha(77)),
                        const SizedBox(height: AppSpacing.md),
                        Text('Không có cảm biến', style: tt.bodyMedium),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...bed.sensors.map((sensor) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _SensorCard(sensor: sensor),
              )),
          ],
        ),
      ),
    );
  }

  BedModel? _findBed(String bedId) {
    for (final area in mockFarm.areas) {
      for (final zone in area.zones) {
        for (final bed in zone.beds) {
          if (bed.id == bedId) return bed;
        }
      }
    }
    return null;
  }
}

class _BedInfoCard extends StatelessWidget {
  const _BedInfoCard({required this.bed});

  final BedModel bed;

  @override
  Widget build(BuildContext context) {
    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text('Thông tin luống', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Mã luống', value: bed.bedCode),
          _InfoRow(label: 'Kích thước', value: '${bed.length}x${bed.width} m (${bed.area.toStringAsFixed(1)} m²)'),
          _InfoRow(label: 'Trạng thái', value: bed.statusLabel),
          if (bed.batchId != null) _InfoRow(label: 'Batch', value: bed.batchId!),
        ],
      ),
    );
  }
}

class _ExperimentAssignmentCard extends StatelessWidget {
  const _ExperimentAssignmentCard({required this.experiment});

  final dynamic experiment;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.science_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thí nghiệm hiện tại',
                        style: tt.labelSmall?.copyWith(color: cs.onSurface.withAlpha(153))),
                    const SizedBox(height: AppSpacing.xs),
                    Text(experiment.title,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.category_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(experiment.cropVariety,
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.sensor});

  final SensorModel sensor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final status = _convertStatus(sensor.status);

    return SNMSCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _getSensorColor(sensor.status).withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getSensorIcon(sensor.sensorType),
              color: _getSensorColor(sensor.status),
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sensor.sensorCode,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  sensor.sensorTypeLabel,
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (sensor.latestValue != null)
                RichText(
                  text: TextSpan(
                    text: sensor.latestValue!.toStringAsFixed(1),
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _getSensorColor(sensor.status),
                    ),
                    children: [
                      TextSpan(
                        text: ' ${sensor.unit}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'No data',
                  style: tt.bodySmall?.copyWith(color: AppColors.error),
                ),
              const SizedBox(height: AppSpacing.xs),
              SensorStatusBadge(status: status),
            ],
          ),
        ],
      ),
    );
  }

  SensorStatus _convertStatus(SensorStatusType status) {
    return switch (status) {
      SensorStatusType.online => SensorStatus.online,
      SensorStatusType.offline => SensorStatus.offline,
      SensorStatusType.warning => SensorStatus.warning,
      SensorStatusType.idle => SensorStatus.idle,
    };
  }

  Color _getSensorColor(SensorStatusType status) {
    return switch (status) {
      SensorStatusType.online => AppColors.sensorOnline,
      SensorStatusType.offline => AppColors.sensorOffline,
      SensorStatusType.warning => AppColors.sensorWarning,
      SensorStatusType.idle => AppColors.sensorIdle,
    };
  }

  IconData _getSensorIcon(SensorType type) {
    return switch (type) {
      SensorType.temperature => Icons.thermostat_rounded,
      SensorType.humidity => Icons.water_drop_rounded,
      SensorType.soilMoisture => Icons.grass_rounded,
      SensorType.light => Icons.wb_sunny_rounded,
      SensorType.co2 => Icons.cloud_outlined,
    };
  }
}
