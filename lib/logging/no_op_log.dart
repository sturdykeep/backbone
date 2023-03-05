import 'package:backbone/logging/log.dart';

class NoOpLog extends Log {
  @override
  void addEvent(String event, {String? payload, int? frame}) {
    // Do nothing
  }

  @override
  void addSample(String key, int milliseconds, {int? frame}) {
    // Do nothing
  }

  @override
  void endTrace(String trace, {int? frame}) {
    // Do nothing
  }

  @override
  void startTrace(String trace) {
    // Do nothing
  }
}
