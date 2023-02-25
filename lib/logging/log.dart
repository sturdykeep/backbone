abstract class Log {
  void startTrace(String trace);
  void endTrace(String trace);
  void addSample(String key, double milliseconds);
  void addEvent(String event, {String? payload});
}
