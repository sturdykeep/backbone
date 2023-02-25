abstract class Log {
  void startTrace(String trace);
  void endTrace(String trace);
  void addSample(String key, int milliseconds);
  void addEvent(String event, {String? payload});
}
