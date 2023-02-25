abstract class Log {
  void startTrace(String trace);
  void endTrace(String trace, {int? frame});
  void addSample(String key, int milliseconds, {int? frame});
  void addEvent(String event, {String? payload, int? frame});
}
