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
  final String label;
  final int value;

  SystemData(this.label, this.value);
}

class _StatisticsState extends State<Statistics> {
  RunState _runState = RunState.stopped;
  final Map<String, List<int>> _systemData = {};
  final RegExp systemMatcher = RegExp('\'(.*?)\'');
  List<SystemData> _lastData = [];
  final List<int> _updateTimes = [];
  @override
  void initState() {
    Globals.worker.callback = _events;
    Globals.worker.logCallback = _logs;
    super.initState();
  }

  void _logs(String message) {
    debugPrint(message);
  }

  List<SystemData> _avgTimesBySystem() {
    _lastData = _systemData.entries
        .map((e) => SystemData(
            e.key,
            e.value.fold(0, (total, element) => total + element) ~/
                max(e.value.length, 0)))
        .toList()
      ..sort(
        (a, b) => a.label.compareTo(b.label),
      );
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
        Timer.periodic(const Duration(seconds: 1), _updateChart);
      } else {
        // parse different categories update view
        if (event.category == "Systems") {
          final elements = event.data.split(',');
          final systemName =
              systemMatcher.firstMatch(elements.first)!.group(0)!;
          _systemData[systemName] ??= [];
          _systemData[systemName]!.add(int.parse(elements.last));
        } else if (event.category == "Update") {
          _updateTimes.add(int.parse(event.data));
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
          child: Chart<void>(
            state: ChartState(
              ChartData.fromList(
                  _avgTimesBySystem()
                      .map((e) => BarValue<String>.withValue(
                          e.label, e.value.toDouble()))
                      .toList(),
                  axisMin: 0,
                  axisMax: _lastData
                          .reduce((value, element) =>
                              value.value > element.value ? value : element)
                          .value +
                      1),
              itemOptions: const BarItemOptions(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                radius: BorderRadius.vertical(
                  top: Radius.circular(32.0),
                ),
                color: Colors.red,
              ),
              backgroundDecorations: [
                GridDecoration(
                  verticalAxisStep: 1,
                  showHorizontalValues: true,
                  showVerticalValues: true,
                  verticalAxisValueFromIndex: (index) {
                    return _lastData[index].label;
                  },
                  textStyle: Theme.of(context).textTheme.bodySmall,
                  horizontalAxisStep: 1,
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
        )
      ],
    );
  }
}
