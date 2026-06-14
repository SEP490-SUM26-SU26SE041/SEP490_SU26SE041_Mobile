import 'package:flutter/material.dart';
import '../../core/theme/app_animation.dart';

/// Wraps a list of children with staggered entry animations.
/// Each child fades in and slides up from `offset` with a `staggerDelay` between items.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.offset = const Offset(0, 18),
    this.controller,
    this.duration,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration staggerDelay;
  final Offset offset;
  final AnimationController? controller;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return _StaggeredItem(
          key: ValueKey('stagger_$index'),
          index: index,
          staggerDelay: staggerDelay,
          offset: offset,
          controller: controller,
          duration: duration,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Same as StaggeredColumn but for Row (horizontal stagger).
class StaggeredRow extends StatelessWidget {
  const StaggeredRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.offset = const Offset(18, 0),
    this.controller,
    this.duration,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration staggerDelay;
  final Offset offset;
  final AnimationController? controller;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return _StaggeredItem(
          key: ValueKey('stagger_row_$index'),
          index: index,
          staggerDelay: staggerDelay,
          offset: offset,
          controller: controller,
          duration: duration,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Wraps a single child with a fade + slide entry animation.
/// Uses a default AnimationController if no controller is provided.
class StaggeredItem extends StatefulWidget {
  const StaggeredItem({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration,
    this.offset = const Offset(0, 18),
    this.curve,
    this.controller,
  });

  final Widget child;
  final Duration delay;
  final Duration? duration;
  final Offset offset;
  final Curve? curve;
  final AnimationController? controller;

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _disposedLocalController = false;

  @override
  void initState() {
    super.initState();
    final dur = widget.duration ?? AppDuration.normal;

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _disposedLocalController = true;
      _controller = AnimationController(vsync: this, duration: dur);
    }

    final curve = widget.curve ?? AppCurve.enter;
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );
    _slideAnim = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );

    Future.delayed(widget.delay, () {
      if (mounted && !_disposedLocalController) {
        _controller.forward();
      }
    });

    if (widget.controller != null) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    if (_disposedLocalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(
            offset: _slideAnim.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Internal implementation used by StaggeredColumn/Row
class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({
    super.key,
    required this.index,
    required this.staggerDelay,
    required this.offset,
    required this.child,
    this.controller,
    this.duration,
  });

  final int index;
  final Duration staggerDelay;
  final Offset offset;
  final Widget child;
  final AnimationController? controller;
  final Duration? duration;

  @override
  State<_StaggeredItem> createState() => __StaggeredItemState();
}

class __StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _disposedLocalController = false;

  @override
  void initState() {
    super.initState();
    final dur = widget.duration ?? AppDuration.normal;

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _disposedLocalController = true;
      _controller = AnimationController(vsync: this, duration: dur);
    }

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppCurve.enter),
    );
    _slideAnim = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppCurve.enter),
    );

    Future.delayed(widget.staggerDelay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });

    if (widget.controller != null) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    if (_disposedLocalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(
            offset: _slideAnim.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
