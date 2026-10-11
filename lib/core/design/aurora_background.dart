import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../developer/performance_settings.dart';
import 'app_theme.dart';

/// Bounded repaint clock: Balanced never repaints its animation above 30 Hz.
class MotionClock extends ValueNotifier<double> {
  MotionClock() : super(0);
  Timer? _timer;
  void start(Duration cycle, OrbTier tier, bool reduced, {bool once = false}) {
    _timer?.cancel();
    value = 0;
    if (reduced) return;
    final watch = Stopwatch()..start();
    _timer = Timer.periodic(
      Duration(
        milliseconds: switch (tier) {
          OrbTier.ultra => 17,
          OrbTier.balanced => 34,
          OrbTier.lite => 100,
        },
      ),
      (timer) {
        final fraction = watch.elapsedMicroseconds / cycle.inMicroseconds;
        value = once ? fraction.clamp(0, 1) : fraction % 1;
        if (once && fraction >= 1) timer.cancel();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.tier,
    required this.reduced,
    required this.child,
  });
  final OrbTier tier;
  final bool reduced;
  final Widget child;
  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> {
  final _clock = MotionClock();
  void _sync() => _clock.start(
    AppTheme.auroraCycle,
    OrbTier.balanced,
    widget.reduced || widget.tier != OrbTier.ultra,
  );
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(AuroraBackground old) {
    super.didUpdateWidget(old);
    if (old.tier != widget.tier || old.reduced != widget.reduced) _sync();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _AuroraPainter(JarvisColors.of(context), _clock),
          ),
        ),
      ),
      widget.child,
    ],
  );
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.colors, this.clock) : super(repaint: clock);
  final JarvisColors colors;
  final MotionClock clock;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.background);
    final drift = math.sin(clock.value * math.pi * 2) * .06;
    for (var i = 0; i < 3; i++) {
      final center = Offset(
        size.width * ([.12, .94, .45][i] + drift),
        size.height * [.05, .42, 1.0][i],
      );
      final radius = size.longestSide * .65;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              colors.accents[i].withValues(alpha: colors.dark ? .15 : .10),
              colors.accents[i].withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.colors != colors;
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.user = false});
  final Widget child;
  final bool user;
  @override
  Widget build(BuildContext context) {
    final c = JarvisColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: c.accentGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.hairline),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: user ? c.bubbleGradient : c.glassGradient,
            borderRadius: BorderRadius.circular(
              AppTheme.radius - AppTheme.hairline,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
