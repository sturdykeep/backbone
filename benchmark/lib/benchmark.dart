import 'package:flutter/material.dart';

typedef BenchmarkFunction = int Function();

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({Key? key, required this.module, required this.setup})
      : super(key: key);

  final String module;
  final BenchmarkFunction Function() setup;

  @override
  State<StatefulWidget> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  // Screen with a button that launches the benchmark
  // which runs a given function as many times as possible
  // in a span of 2 seconds, then displays the average time

  // Results
  bool _displayResults = false;
  int _runs = 0;
  double _totalTime = 0.0;
  double _totalSetupTime = 0.0;

  void _startBenchmark() {
    _runs = 0;
    _totalTime = 0.0;
    _displayResults = false;

    // Start benchmark
    final Stopwatch setupStopwatch = Stopwatch();
    setupStopwatch.start();

    final benchmarkFunction = widget.setup();
    _totalSetupTime = setupStopwatch.elapsedMilliseconds.toDouble();
    setupStopwatch.stop();
    final Stopwatch stopwatch = Stopwatch();
    stopwatch.start();
    while (stopwatch.elapsedMilliseconds < 2000) {
      final runResult = benchmarkFunction();
      setState(() {
        _runs += 1;
      });
      debugPrint('Result $runResult');
    }
    _totalTime = stopwatch.elapsedMilliseconds.toDouble();
    stopwatch.stop();
    setState(() {
      _displayResults = true;
    });
  }

  Widget buildStartButton(BuildContext context) {
    return OutlinedButton(
      child: const Text('Start'),
      onPressed: () {
        setState(() {
          _runs = 0;
          _totalTime = 0.0;
        });
        _startBenchmark();
      },
    );
  }

  Widget buildResults(BuildContext context) {
    // Result screen with a button to run the benchmark again
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Average time: ${(_totalTime / _runs).toStringAsFixed(2)}ms',
          style: Theme.of(context).textTheme.headline4,
        ),
        Text(
          'Runs: $_runs',
          style: Theme.of(context).textTheme.headline5,
        ),
        Text(
          'Total time: $_totalTime ms',
          style: Theme.of(context).textTheme.headline5,
        ),
        Text(
          'Total setup time: $_totalSetupTime ms',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          child: const Text('Run again'),
          onPressed: () {
            setState(() {
              _displayResults = false;
            });
            _startBenchmark();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Benchmark for ${widget.module}"),
      ),
      body: Center(
        child:
            _displayResults ? buildResults(context) : buildStartButton(context),
      ),
    );
  }
}
