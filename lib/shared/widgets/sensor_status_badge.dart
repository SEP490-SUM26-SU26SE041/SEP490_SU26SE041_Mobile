import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum SensorStatus { online, offline, warning, idle }

class SensorStatusBadge extends StatelessWidget {
  const SensorStatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.size = SensorBadgeSize.medium,
  });

  final SensorStatus status;
  final bool showLabel;
  final SensorBadgeSize size;

  Color get _color => switch (status) {
    SensorStatus.online  => AppColors.sensorOnline,
    SensorStatus.offline => AppColors.sensorOffline,
    SensorStatus.warning => AppColors.sensorWarning,
    SensorStatus.idle   => AppColors.sensorIdle,
  };

  String get _label => switch (status) {
    SensorStatus.online  => 'Online',
    SensorStatus.offline => 'Offline',
    SensorStatus.warning => 'Warning',
    SensorStatus.idle   => 'Idle',
  };

  double get _dotSize => switch (size) {
    SensorBadgeSize.small  => AppSpacing.xs,
    SensorBadgeSize.medium => AppSpacing.sm,
    SensorBadgeSize.large  => AppSpacing.md,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sensor status: $_label',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SensorStatus.online)
            _PulsingDot(color: _color, size: _dotSize)
          else
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
          if (showLabel) ...[
            SizedBox(width: AppSpacing.xs),
            Text(
              _label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum SensorBadgeSize { small, medium, large }

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
