enum OrbState { idle, listening, thinking, speaking, error }

/// A bounded rolling window. Switches permanently to simple mode for this visit
/// after at least 12 of 60 measured frames miss the 60 Hz build/raster budget.
class FrameHealth {
  final List<int> _samples = [];
  bool simplified = false;
  int get count => _samples.length;
  double? get meanMs => _samples.isEmpty
      ? null
      : _samples.reduce((a, b) => a + b) / _samples.length / 1000;
  double? get p95Ms {
    if (_samples.isEmpty) return null;
    final sorted = [..._samples]..sort();
    return sorted[((sorted.length * .95).ceil() - 1)] / 1000;
  }

  void add({required int buildMicros, required int rasterMicros}) {
    _samples.add(buildMicros > rasterMicros ? buildMicros : rasterMicros);
    if (_samples.length > 60) _samples.removeAt(0);
    if (_samples.length == 60 &&
        _samples.where((v) => v > 16667).length >= 12) {
      simplified = true;
    }
  }
}
