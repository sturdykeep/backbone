import 'dart:collection';

import 'package:backbone/realm.dart';
import 'package:backbone/system.dart';
import 'package:flutter/widgets.dart';

class SystemPerformanceLog {
  final String column;
  final String? parent;
  int value;

  SystemPerformanceLog(this.column, this.parent, this.value);
}

class ProcessedSystemPerformanceLog {
  final String column;
  final String? parent;
  int value;

  ProcessedSystemPerformanceLog(this.column, this.value, {this.parent});
}

class LogStopwatch {
  final DateTime startTime = DateTime.now();
  int stop() => DateTime.now().difference(startTime).inMicroseconds;
}

class Log {
  // Specific metrics for low-cost logging
  static int transformQueryTime = 0;
  static int transformBodyTime = 0;

  // Performance logging
  static HashMap<String, SystemPerformanceLog> _systemPerformanceLog =
      HashMap();

  static void logPerformance(String category, String value) {
    debugPrint('prefmon:$category->$value:prefmon');
  }

  static void logSystemPerformance(
      String column, String? parentColumn, int value,
      {int? frame}) {
    final key = "$parentColumn->$column";
    final existing = _systemPerformanceLog[key];
    if (existing != null) {
      existing.value += value;
    } else {
      _systemPerformanceLog[key] =
          SystemPerformanceLog(column, parentColumn, value);
    }
  }

  static void processPerformanceLogs() {
    // Gather everything up
    final processed = <String, ProcessedSystemPerformanceLog>{};
    for (final log in _systemPerformanceLog.values) {
      final key = "${log.parent}->${log.column}";
      if (processed.containsKey(key)) {
        processed[key]!.value += log.value;
      } else {
        processed[key] = ProcessedSystemPerformanceLog(log.column, log.value,
            parent: log.parent);
      }
    }

    // Turn specific metrics into the same format
    processed["transformSystem->query"] = ProcessedSystemPerformanceLog(
        "query", transformQueryTime,
        parent: "transformSystem");
    processed["transformSystem->body"] = ProcessedSystemPerformanceLog(
        "body", transformBodyTime,
        parent: "transformSystem");

    // Send it
    for (final log in processed.values) {
      logPerformance("Systems",
          "${log.column},${log.parent},${log.value},${Realm.globalFrame}");
    }

    // Clear
    _systemPerformanceLog = HashMap();
    transformQueryTime = 0;
    transformBodyTime = 0;
  }
}
