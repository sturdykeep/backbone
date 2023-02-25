import 'package:backbone/logging/log.dart';

class NoOpLog extends Log {
  @override
  void addSample(String key, int milliseconds) {
    //Do nothing
  }

  @override
  void endTrace(String trace) {
    //Do nothing
  }

  @override
  void startTrace(String trace) {
    //Do nothing
  }

  @override
  void addEvent(String event, {String? payload}) {
    //Do nothing
  }
}
