import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'frame_metrics.dart';
import '../storage/local_store.dart';
export 'frame_metrics.dart';

final frameDiagnosticsProvider = Provider((ref) => FrameDiagnostics());

class QualityChoice {
  const QualityChoice({this.manual, this.automatic = OrbTier.lite});
  final OrbTier? manual;
  final OrbTier automatic;
  OrbTier get tier => manual ?? automatic;
}

class QualitySettings extends Notifier<QualityChoice> {
  QualityGovernor _governor = QualityGovernor();
  @override
  QualityChoice build() =>
      QualityChoice(manual: savedEnum(ref, 'quality', OrbTier.values));
  void select(OrbTier? tier) {
    _governor = QualityGovernor();
    state = QualityChoice(manual: tier);
    persistSetting(ref, 'quality', tier?.name ?? 'auto');
  }

  void record(OrbTier actual, int build, int raster, {bool reduced = false}) {
    ref.read(frameDiagnosticsProvider).record(actual, build, raster);
    if (state.manual == null && !reduced && _governor.add(build, raster)) {
      state = QualityChoice(automatic: _governor.tier);
    }
  }
}

final qualityProvider = NotifierProvider<QualitySettings, QualityChoice>(
  QualitySettings.new,
);

class OverlaySettings extends Notifier<bool> {
  @override
  bool build() => false;
  void setEnabled(bool enabled) => state = enabled;
}

final performanceOverlayProvider = NotifierProvider<OverlaySettings, bool>(
  OverlaySettings.new,
);
