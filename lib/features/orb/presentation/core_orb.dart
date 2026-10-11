import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/design/app_theme.dart';
import '../domain/orb_state.dart';

class CoreOrb extends StatefulWidget {
  const CoreOrb({super.key, required this.state, required this.reduceMotion});
  final OrbState state;
  final bool reduceMotion;
  @override
  State<CoreOrb> createState() => _CoreOrbState();
}

class _CoreOrbState extends State<CoreOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  final _health = FrameHealth();
  bool _disabled = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: AppTheme.orbCycle);
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    // Do not let timing labels themselves schedule a perpetual render loop
    // after falling back to a static orb or enabling reduced motion.
    if (!mounted || timings.isEmpty || _disabled) return;
    for (final timing in timings) {
      _health.add(
        buildMicros: timing.buildDuration.inMicroseconds,
        rasterMicros: timing.rasterDuration.inMicroseconds,
      );
    }
    setState(() {});
    _syncAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(CoreOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation(restart: oldWidget.state != widget.state);
  }

  void _syncAnimation({bool restart = false}) {
    _disabled =
        widget.reduceMotion ||
        MediaQuery.disableAnimationsOf(context) ||
        _health.simplified ||
        !TickerMode.valuesOf(context).enabled;
    if (_disabled) {
      _animation.stop();
      _animation.value = 0;
    } else if (widget.state == OrbState.error) {
      if (restart || !_animation.isAnimating && _animation.value == 0) {
        _animation.duration = AppTheme.errorFlicker;
        _animation.forward(from: 0);
      }
    } else if (restart || !_animation.isAnimating) {
      _animation.duration = widget.state == OrbState.idle
          ? AppTheme.orbCycle
          : AppTheme.activeOrbCycle;
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.state == OrbState.error
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Semantics(
          label: 'Core orb: ${widget.state.name}',
          image: true,
          child: RepaintBoundary(
            child: SizedBox(
              width: AppTheme.orbSize,
              height: AppTheme.orbSize,
              child: CustomPaint(
                painter: _OrbPainter(
                  animation: _animation,
                  state: widget.state,
                  color: color,
                  simple: _disabled,
                ),
              ),
            ),
          ),
        ),
        Text('Orb: ${widget.state.name}', key: const ValueKey('orb-state')),
        Text(
          _health.count == 0
              ? (_disabled
                    ? 'Frame monitoring paused: motion disabled'
                    : 'Frame timing: waiting for engine samples')
              : 'Build/raster max: mean ${_health.meanMs!.toStringAsFixed(1)} ms • '
                    'p95 ${_health.p95Ms!.toStringAsFixed(1)} ms (${_health.count} frames)',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        Text(
          _health.simplified
              ? 'Simple orb: frame budget exceeded'
              : _disabled
              ? 'Simple orb: motion disabled'
              : 'Lightweight animated orb',
          key: const ValueKey('orb-mode'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.animation,
    required this.state,
    required this.color,
    required this.simple,
  }) : super(repaint: animation);
  final Animation<double> animation;
  final OrbState state;
  final Color color;
  final bool simple;
  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final center = size.center(Offset.zero);
    final pulse = simple ? 0.0 : math.sin(t * math.pi * 2);
    final radius =
        size.shortestSide *
        (.22 + pulse * (state == OrbState.speaking ? .04 : .015));
    final flicker = !simple && state == OrbState.error && t < 1
        ? .85 + .15 * math.cos(t * math.pi * 2)
        : 1.0;
    final paint = Paint()..color = color.withValues(alpha: .18 * flicker);
    canvas.drawCircle(center, radius + 8, paint);
    paint.color = color.withValues(alpha: .85 * flicker);
    canvas.drawCircle(center, radius, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, size.shortestSide * .34, paint);
    if (!simple) {
      final rotation = t * math.pi * 2;
      for (var i = 0; i < 3; i++) {
        canvas.drawArc(
          Rect.fromCircle(
            center: center,
            radius: size.shortestSide * (.39 + i * .035),
          ),
          rotation + i * 2.1,
          state == OrbState.thinking ? 1.2 : .55,
          false,
          paint,
        );
      }
      if (state == OrbState.listening) {
        paint.style = PaintingStyle.fill;
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          canvas.drawCircle(
            center +
                Offset(math.cos(angle), math.sin(angle)) *
                    (size.shortestSide * .43 + pulse * 3),
            2,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.color != color ||
      oldDelegate.simple != simple;
}
