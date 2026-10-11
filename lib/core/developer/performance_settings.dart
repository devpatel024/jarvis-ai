import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OrbTier { animated, simple }

/// Bounded engine samples for the whole app while the chat orb is mounted.
/// Recording does not notify listeners or schedule frames.
class TierSamples {
  final List<({int build, int raster})> _frames = [];
  int get count => _frames.length;
  void add(int build, int raster) {
    _frames.add((build: build, raster: raster));
    if (_frames.length > 120) _frames.removeAt(0);
  }

  double? mean({required bool raster}) => _frames.isEmpty
      ? null
      : _frames
                .map((f) => raster ? f.raster : f.build)
                .reduce((a, b) => a + b) /
            _frames.length /
            1000;

  double? p95({required bool raster}) {
    if (_frames.isEmpty) return null;
    final values = _frames.map((f) => raster ? f.raster : f.build).toList()
      ..sort();
    return values[(values.length * .95).ceil() - 1] / 1000;
  }

  int get budgetMisses =>
      _frames.where((f) => f.build > 16667 || f.raster > 16667).length;
}

class FrameDiagnostics {
  final tiers = {for (final tier in OrbTier.values) tier: TierSamples()};
  void record(OrbTier tier, int build, int raster) =>
      tiers[tier]!.add(build, raster);
  void reset() {
    for (final tier in OrbTier.values) {
      tiers[tier] = TierSamples();
    }
  }
}

final frameDiagnosticsProvider = Provider((ref) => FrameDiagnostics());

class OverlaySettings extends Notifier<bool> {
  @override
  bool build() => false;
  void setEnabled(bool enabled) => state = enabled;
}

final performanceOverlayProvider = NotifierProvider<OverlaySettings, bool>(
  OverlaySettings.new,
);
