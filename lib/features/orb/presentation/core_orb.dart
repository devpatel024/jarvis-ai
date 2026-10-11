import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/aurora_background.dart';
import '../../../core/developer/performance_settings.dart';
import '../domain/orb_state.dart';

class CoreOrb extends StatefulWidget {
  const CoreOrb({
    super.key,
    required this.state,
    required this.reduceMotion,
    this.tier = OrbTier.balanced,
    this.size = AppTheme.orbSize,
    this.microphoneLevel = 0,
  });
  final OrbState state;
  final bool reduceMotion;
  final OrbTier tier;
  final double size, microphoneLevel;
  @override
  State<CoreOrb> createState() => _CoreOrbState();
}

class _CoreOrbState extends State<CoreOrb> {
  final _clock = MotionClock();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CoreOrb old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state ||
        old.reduceMotion != widget.reduceMotion ||
        old.tier != widget.tier) {
      _sync();
    }
  }

  void _sync() => _clock.start(
    widget.state == OrbState.error
        ? AppTheme.errorFlicker
        : widget.tier == OrbTier.lite || widget.state == OrbState.idle
        ? AppTheme.orbCycle
        : AppTheme.activeOrbCycle,
    widget.tier,
    widget.reduceMotion ||
        MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled,
    once: widget.state == OrbState.error,
  );
  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced =
        widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    final painting = CustomPaint(
      painter: _OrbPainter(
        _clock,
        widget.state,
        widget.tier,
        reduced,
        JarvisColors.of(context).stateColors(widget.state.name),
      ),
    );
    return Semantics(
      container: true,
      label: 'Core orb: ${widget.state.name}',
      image: true,
      child: Transform.scale(
        scale: widget.state == OrbState.listening && !reduced
            ? 1 + widget.microphoneLevel * .15
            : 1,
        child: RepaintBoundary(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: widget.tier == OrbTier.lite && !reduced
                ? AnimatedBuilder(
                    animation: _clock,
                    child: RepaintBoundary(child: painting),
                    builder: (context, child) => Transform.scale(
                      scale: 1 + math.sin(_clock.value * math.pi * 2) * .015,
                      child: child,
                    ),
                  )
                : painting,
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.clock, this.state, this.tier, this.reduced, this.colors)
    : super(repaint: tier == OrbTier.lite ? null : clock);
  final MotionClock clock;
  final OrbState state;
  final OrbTier tier;
  final bool reduced;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final t = reduced || tier == OrbTier.lite ? 0.0 : clock.value;
    final active = !reduced && tier != OrbTier.lite;
    final errorProgress = state == OrbState.error ? t : 1.0;
    final shake = active && state == OrbState.error
        ? math.sin(t * math.pi * 8) * (1 - t) * size.width * .009
        : 0.0;
    final center = size.center(Offset(shake, 0));
    final pulse = reduced ? 0.0 : math.sin(t * math.pi * 2);
    final radius = size.width * (.22 + pulse * .008);
    final outer = size.width * .49;
    canvas.drawCircle(
      center,
      outer,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colors.first.withValues(alpha: AppTheme.glowAlpha),
            colors.last.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: outer)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.45),
          radius: 1.2,
          colors: [
            Color.lerp(colors.first, AppTheme.white, .65)!,
            colors.first,
            colors.last,
            Color.lerp(colors.last, AppTheme.black, .55)!,
          ],
          stops: const [0, .25, .6, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-radius * .25, -radius * .42),
        width: radius * .8,
        height: radius * .28,
      ),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppTheme.white.withValues(alpha: .5),
                AppTheme.white.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: center + Offset(-radius * .25, -radius * .42),
                radius: radius * .5,
              ),
            ),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppTheme.hairline * 1.5;
    for (var i = 0; i < 3; i++) {
      final ringRadius =
          size.width * (.31 + i * .047) +
          (state == OrbState.listening && active
              ? pulse * size.width * .012
              : 0);
      final rect = Rect.fromCenter(
        center: center,
        width: ringRadius * 2,
        height: ringRadius * (i == 1 ? 1.6 : 2),
      );
      paint.shader = SweepGradient(
        colors: [
          colors.first.withValues(alpha: .1),
          colors[i % colors.length],
          colors.last.withValues(alpha: .25),
          colors.first.withValues(alpha: .1),
        ],
        transform: GradientRotation(
          active ? t * math.pi * 2 * (i.isEven ? 1 : -1) : 0,
        ),
      ).createShader(rect);
      canvas.drawOval(rect, paint);
      if (active && state == OrbState.thinking) {
        canvas.drawArc(
          rect,
          t * math.pi * 2 * (i.isEven ? 1 : -1),
          .7,
          false,
          paint,
        );
      }
    }
    if (active && state == OrbState.speaking) {
      for (var i = 0; i < 2; i++) {
        final ripple = (t + i * .5) % 1;
        paint
          ..shader = null
          ..color = colors[i % colors.length].withValues(
            alpha: (1 - ripple) * .55,
          );
        canvas.drawCircle(center, size.width * (.25 + ripple * .2), paint);
      }
      canvas.drawCircle(
        center + Offset(radius * .65, radius * .6),
        size.width * .018,
        Paint()..color = AppTheme.amber,
      );
    }
    if (active && tier == OrbTier.ultra) {
      for (var i = 0; i < 24; i++) {
        final angle = i * math.pi / 12 + t * math.pi * 2;
        canvas.drawCircle(
          center +
              Offset(math.cos(angle), math.sin(angle)) *
                  size.width *
                  (.43 + .018 * math.sin(i + t * 6)),
          size.width * .004,
          Paint()..color = colors[i % colors.length].withValues(alpha: .55),
        );
      }
    }
    if (state == OrbState.error && errorProgress < 1) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppTheme.error.first.withValues(
            alpha: (1 - errorProgress) * .16,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.state != state ||
      old.tier != tier ||
      old.reduced != reduced ||
      old.colors != colors;
}
