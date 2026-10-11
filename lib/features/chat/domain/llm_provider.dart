import 'dart:async';

enum MessageRole { user, assistant }

class LlmMessage {
  const LlmMessage(this.role, this.text);
  final MessageRole role;
  final String text;
}

enum LlmErrorCode { cancelled, timeout, unavailable, invalidRequest }

class LlmFailure {
  const LlmFailure(this.code, this.message);
  final LlmErrorCode code;
  final String message;
}

sealed class LlmEvent {
  const LlmEvent();
}

class TextDelta extends LlmEvent {
  const TextDelta(this.text);
  final String text;
}

class LlmCompleted extends LlmEvent {
  const LlmCompleted();
}

class LlmFailed extends LlmEvent {
  const LlmFailed(this.failure);
  final LlmFailure failure;
}

/// Cooperative cancellation, including interruption of an in-flight delay.
class CancellationToken {
  final _signal = Completer<void>();
  bool get isCancelled => _signal.isCompleted;
  void cancel() {
    if (!isCancelled) _signal.complete();
  }

  Future<bool> wait(Duration duration) async {
    if (isCancelled) return false;
    final elapsed = Completer<void>();
    final timer = Timer(duration, elapsed.complete);
    try {
      await Future.any([elapsed.future, _signal.future]);
      return !isCancelled;
    } finally {
      timer.cancel();
    }
  }
}

abstract interface class LlmProvider {
  String get label;
  bool get isDemo;
  Stream<LlmEvent> respond(
    List<LlmMessage> messages, {
    required CancellationToken cancellation,
  });
}
