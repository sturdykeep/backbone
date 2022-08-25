import 'package:benchmark/benchmark.dart';
import 'package:benchmark/setups/backbone.dart';
import 'package:benchmark/setups/oxygen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void navigateToBenchmark(
      String module, BenchmarkFunction Function() function) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BenchmarkScreen(
          module: module,
          setup: function,
        ),
      ),
    );
  }

  Widget buildBenchmarkButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OutlinedButton(
            child: const Text('Benchmark backbone'),
            onPressed: () {
              navigateToBenchmark('backbone', backbonePureMillion);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OutlinedButton(
            child: const Text('Benchmark oxygen'),
            onPressed: () {
              navigateToBenchmark('oxygen', oxygenPureMillion);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Module Benchmarks"),
      ),
      body: Center(
        child: buildBenchmarkButtons(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
