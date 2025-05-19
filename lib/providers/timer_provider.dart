import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recordingTimerProvider =
    NotifierProvider<RecordingTimerNotifier, Duration>(
      RecordingTimerNotifier.new,
    );

class RecordingTimerNotifier extends Notifier<Duration> {
  Timer? _timer;

  @override
  Duration build() {
    return Duration.zero;
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state + const Duration(seconds: 1);
    });
  }

  void pause() {
    _timer?.cancel();
  }

  void reset() {
    _timer?.cancel();
    state = Duration.zero;
  }

  void dispose() {
    _timer?.cancel();
  }
}
