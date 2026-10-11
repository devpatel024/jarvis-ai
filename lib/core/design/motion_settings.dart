import 'package:flutter_riverpod/flutter_riverpod.dart';

class MotionSettings extends Notifier<bool> {
  @override
  bool build() => false;
  void setReduced(bool value) => state = value;
}

final reduceMotionProvider = NotifierProvider<MotionSettings, bool>(
  MotionSettings.new,
);
