import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_store.dart';

class MotionSettings extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(initialSnapshotProvider).settings['reduceMotion'] == 'true';
  void setReduced(bool value) {
    state = value;
    persistSetting(ref, 'reduceMotion', '$value');
  }
}

final reduceMotionProvider = NotifierProvider<MotionSettings, bool>(
  MotionSettings.new,
);
