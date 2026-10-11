enum OrbTier { ultra, balanced, lite }

extension TierLabel on OrbTier {
  String get label => switch (this) {
    OrbTier.ultra => 'Ultra',
    OrbTier.balanced => 'Balanced',
    OrbTier.lite => 'Lite',
  };
}

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
            count /
            1000;
  double? p95({required bool raster}) {
    if (_frames.isEmpty) return null;
    final values = _frames.map((f) => raster ? f.raster : f.build).toList()
      ..sort();
    return values[(count * .95).ceil() - 1] / 1000;
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

/// Two bad windows downgrade; three good windows upgrade. Threshold separation
/// and a fresh window after transitions prevent boundary oscillation.
class QualityGovernor {
  QualityGovernor({this.tier = OrbTier.lite});
  OrbTier tier;
  final _samples = <int>[];
  int _bad = 0, _good = 0;
  bool add(int build, int raster) {
    _samples.add(build > raster ? build : raster);
    if (_samples.length < 60) return false;
    _samples.sort();
    final p95 = _samples[56];
    _samples.clear();
    final budget = tier == OrbTier.ultra ? 16667 : 33333;
    _bad = p95 > budget ? _bad + 1 : 0;
    _good = p95 < (tier == OrbTier.lite ? 18000 : 12000) ? _good + 1 : 0;
    if (_bad >= 2 && tier != OrbTier.lite) {
      tier = OrbTier.values[tier.index + 1];
      _bad = _good = 0;
      return true;
    }
    if (_good >= 3 && tier != OrbTier.ultra) {
      tier = OrbTier.values[tier.index - 1];
      _bad = _good = 0;
      return true;
    }
    return false;
  }
}
