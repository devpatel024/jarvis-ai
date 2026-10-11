import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/features/orb/domain/orb_state.dart';

void main() {
  test('Isolated slow startup frames do not trigger fallback', () {
    final health = FrameHealth();
    health.add(buildMicros: 40000, rasterMicros: 1000);
    for (var i = 0; i < 59; i++) {
      health.add(buildMicros: 1000, rasterMicros: 2000);
    }
    expect(health.simplified, isFalse);
    expect(health.count, 60);
    expect(health.p95Ms, 2);
  });
  test('Sustained build or raster budget misses latch a bounded fallback', () {
    final health = FrameHealth();
    for (var i = 0; i < 60; i++) {
      health.add(buildMicros: 1000, rasterMicros: i < 12 ? 20000 : 2000);
    }
    expect(health.simplified, isTrue);
    for (var i = 0; i < 120; i++) {
      health.add(buildMicros: 1000, rasterMicros: 2000);
    }
    expect(health.count, 60);
    expect(health.simplified, isTrue);
    expect(health.meanMs, 2);
    expect(health.p95Ms, 2);
  });
}
