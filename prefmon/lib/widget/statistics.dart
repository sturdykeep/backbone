import 'dart:async';
import 'dart:math';

import 'package:charts_painter/chart.dart';
import 'package:flutter/material.dart';
import 'package:prefmon/core/backbone_worker.dart';
import 'package:prefmon/globals.dart';
import 'package:prefmon/widget/simple_state.dart';

class Statistics extends StatefulWidget {
  const Statistics({Key? key}) : super(key: key);

  @override
  State<Statistics> createState() => _StatisticsState();
}

enum RunState {
  starting,
  running,
  stopped,
}

class SystemData {
  final String column;
  final String? parent;
  final List<int> values = [];

  SystemData(this.column, this.parent);
}

class ProcessedSystemData {
  final String column;
  final String? parent;
  final int value;

  ProcessedSystemData(this.column, this.value, {this.parent});

  @override
  String toString() {
    if (parent != null) {
      return "$parent->$column";
    } else {
      return column;
    }
  }
}

class _StatisticsState extends State<Statistics> {
  RunState _runState = RunState.stopped;
  final List<SystemData> _systemData = [];
  List<ProcessedSystemData> _lastData = [];
  final List<int> _updateTimes = [];
  final List<int> _renderTimes = [];
  @override
  void initState() {
    Globals.worker.callback = _events;
    Globals.worker.logCallback = _logs;
    super.initState();
  }

  void _logs(String message) {
    debugPrint(message);
  }

  List<ProcessedSystemData> _avgTimesBySystem() {
    // Proccess _systemData into a list of ProcessedSystemData
    // which aggregates the values received over time.
    final result = <ProcessedSystemData>[];
    final systemData = _systemData;
    for (var data in systemData) {
      final values = data.values;
      final sum =
          values.fold(0, (previousValue, element) => previousValue + element);
      final avg = sum / values.length;
      result.add(
          ProcessedSystemData(data.column, avg.toInt(), parent: data.parent));
    }
    _lastData = result..sort((a, b) => a.toString().compareTo(b.toString()));
    return _lastData;
  }

  void _updateChart(Timer t) {
    if (_runState == RunState.stopped) {
      t.cancel();
    } else {
      if (_systemData.isEmpty) return;

      setState(() {
        //Refresh the chart?
      });
    }
  }

  void _events(PrefMonEvent event) {
    if (event is PrefMonDataEvent) {
      if (event.category == "Running") {
        setState(() {
          _runState = RunState.running;
        });
        Timer.periodic(const Duration(milliseconds: 300), _updateChart);
      } else {
        // parse different categories update view
        if (event.category == "Systems") {
          final elements = event.data.split(',');
          final column = elements[0];
          final parent = elements[1] == "null" ? null : elements[1];
          final value = int.parse(elements[2]);

          SystemData systemData;
          if (_systemData
              .any((sd) => sd.column == column && sd.parent == parent))
            systemData = _systemData
                .firstWhere((sd) => sd.column == column && sd.parent == parent);
          else {
            systemData = SystemData(column, parent);
            _systemData.add(systemData);
          }

          systemData.values.add(value);
        } else if (event.category == "Update") {
          _updateTimes.add(int.parse(event.data));
        } else if (event.category == "Render") {
          _renderTimes.add(int.parse(event.data));
        }
      }
    } else if (event is Starting) {
      setState(() {
        _runState = RunState.starting;
      });
    } else if (event is Stopped) {
      _systemData.clear();
      _updateTimes.clear();
      setState(() {
        _runState = RunState.stopped;
      });
    }
  }

  int _getAvgUpdateTime() {
    return _updateTimes.fold<int>(
            0, (previousValue, element) => previousValue += element) ~/
        max(_updateTimes.length, 1);
  }

  int _getAvgRenderTime() {
    return _renderTimes.fold<int>(
            0, (previousValue, element) => previousValue += element) ~/
        max(_renderTimes.length, 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_runState == RunState.stopped) {
      return const SimpleState.stopped();
    }
    if (_runState == RunState.starting) {
      return const SimpleState.starting();
    }
    if (_systemData.isEmpty) {
      return const SimpleState(
          text: 'Waiting for data', icon: Icons.build_sharp);
    }
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Chart<ProcessedSystemData>(
            state: ChartState(
              ChartData.fromList(
                  _avgTimesBySystem()
                      .map((e) => ChartItem<ProcessedSystemData>(
                          e, 0, e.value.toDouble()))
                      .toList(),
                  axisMin: 0,
                  axisMax: _lastData
                          .reduce((value, element) =>
                              value.value > element.value ? value : element)
                          .value +
                      1),
              itemOptions: BarItemOptions(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                radius: const BorderRadius.vertical(
                  top: Radius.circular(32.0),
                ),
                colorForKey: (item, index) =>
                    item.value.parent == null ? Colors.red : Colors.grey,
              ),
              backgroundDecorations: [
                GridDecoration(
                  verticalAxisStep: 1,
                  showHorizontalValues: true,
                  showVerticalValues: true,
                  verticalAxisValueFromIndex: (index) {
                    return _lastData[index].toString();
                  },
                  textStyle: Theme.of(context).textTheme.bodySmall,
                  horizontalAxisStep: 10,
                ),
              ],
              foregroundDecorations: [
                BorderDecoration(borderWidth: 5.0),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 5, right: 5),
            child: Text("Update time(avg): ${_getAvgUpdateTime()} ms"),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 5, left: 5),
            child: Text("Render time(avg): ${_getAvgRenderTime()} ms"),
          ),
        )
      ],
    );
  }
}
