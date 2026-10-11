import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/core/developer/performance_settings.dart';

void main() {
  test(
    'Hysteresis downgrades only after two bad windows and recovers after three',
    () {
      final governor = QualityGovernor(tier: OrbTier.balanced);
      for (var i = 0; i < 60; i++) {
        governor.add(1000, 40000);
      }
      expect(governor.tier, OrbTier.balanced);
      for (var i = 0; i < 60; i++) {
        governor.add(1000, 40000);
      }
      expect(governor.tier, OrbTier.lite);
      for (var i = 0; i < 120; i++) {
        governor.add(1000, 10000);
      }
      expect(governor.tier, OrbTier.lite);
      for (var i = 0; i < 60; i++) {
        governor.add(1000, 10000);
      }
      expect(governor.tier, OrbTier.balanced);
      for (var i = 0; i < 180; i++) {
        governor.add(1000, 10000);
      }
      expect(governor.tier, OrbTier.ultra);
    },
  );
  test('Mixed threshold windows do not oscillate quality', () {
    final governor = QualityGovernor(tier: OrbTier.balanced);
    for (var window = 0; window < 10; window++) {
      for (var i = 0; i < 60; i++) {
        governor.add(1000, window.isEven ? 40000 : 24000);
      }
    }
    expect(governor.tier, OrbTier.balanced);
  });
}
