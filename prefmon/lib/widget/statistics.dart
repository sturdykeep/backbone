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
  final int frame;

  SystemData(this.column, this.parent, this.frame);
}

class ProcessedFrameSystemData {
  final String column;
  final String? parent;
  int value;
  final int frame;

  ProcessedFrameSystemData(this.column, this.value, this.frame, {this.parent});
}

class ProcessedSystemData {
  final String column;
  final String? parent;
  final List<int> values;
  int count;

  int get avg => values.reduce((value, element) => value + element) ~/ count;

  ProcessedSystemData(this.column, this.values, this.count, {this.parent});

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
    // which averages the sums of data received over time for different
    // frames.
    final systemData = _systemData;
    // Sort data into frame "buckets"
    final systemDataByFrame = <int, List<SystemData>>{};
    for (var data in systemData) {
      final frameData = systemDataByFrame[data.frame] ?? [];
      frameData.add(data);
      systemDataByFrame[data.frame] = frameData;
    }
    // Process data into ProcessedFrameSystemData with a sum of all values
    // for that column and parent during one frame.
    final processedFrameData = <int, List<ProcessedFrameSystemData>>{};
    for (var frame in systemDataByFrame.keys) {
      final frameData = systemDataByFrame[frame]!;
      final frameProcessed = processedFrameData[frame] ?? [];
      for (var data in frameData) {
        final existing = frameProcessed
            .cast<ProcessedFrameSystemData?>()
            .firstWhere(
                (processed) =>
                    processed!.column == data.column &&
                    processed.parent == data.parent,
                orElse: () => null);
        if (existing != null) {
          existing.value += data.values.reduce((a, b) => a + b);
        } else {
          frameProcessed.add(ProcessedFrameSystemData(
              data.column, data.values.reduce((a, b) => a + b), frame,
              parent: data.parent));
        }
      }
      // make sure to add the data to the list
      processedFrameData[frame] = frameProcessed;
    }
    // Average out the data over multiple frames
    final processedData = <ProcessedSystemData>[];
    for (var frame in processedFrameData.keys) {
      final frameData = processedFrameData[frame]!;
      for (var data in frameData) {
        final existing = processedData.cast<ProcessedSystemData?>().firstWhere(
            (processed) =>
                processed!.column == data.column &&
                processed.parent == data.parent,
            orElse: () => null);
        if (existing != null) {
          existing.values.add(data.value);
          existing.count++;
        } else {
          processedData.add(ProcessedSystemData(data.column, [data.value], 1,
              parent: data.parent));
        }
      }
    }
    _lastData = processedData
      ..sort((a, b) => a.toString().compareTo(b.toString()));
    return _lastData;
  }

  bool _noData() =>
      _systemData.isEmpty && _renderTimes.isEmpty && _updateTimes.isEmpty;

  void _updateChart(Timer t) {
    if (_runState == RunState.stopped) {
      t.cancel();
    } else {
      if (_noData()) {
        return;
      }

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
          final frame = int.parse(elements[3]);

          SystemData systemData;
          if (_systemData.any((sd) =>
              sd.column == column &&
              sd.parent == parent &&
              sd.frame == frame)) {
            systemData = _systemData.firstWhere((sd) =>
                sd.column == column &&
                sd.parent == parent &&
                sd.frame == frame);
          } else {
            systemData = SystemData(column, parent, frame);
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
    if (_noData()) {
      return const SimpleState(
          text: 'Waiting for data', icon: Icons.build_sharp);
    }
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: _systemData.isEmpty
              ? const Center(
                  child: Text('No system data received'),
                )
              : Chart<ProcessedSystemData>(
                  state: ChartState(
                    ChartData.fromList(
                        _avgTimesBySystem()
                            .map((e) => ChartItem<ProcessedSystemData>(
                                e, 0, e.avg.toDouble()))
                            .toList(),
                        axisMin: 0,
                        axisMax: _lastData
                                .reduce((value, element) =>
                                    value.avg > element.avg ? value : element)
                                .avg +
                            10),
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
            child: Text("Update time(avg): ${_getAvgUpdateTime() / 1000} ms"),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 5, left: 5),
            child: Text("Render time(avg): ${_getAvgRenderTime() / 1000} ms"),
          ),
        )
      ],
    );
  }
}
