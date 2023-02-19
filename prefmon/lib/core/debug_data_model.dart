import 'package:flutter/material.dart';
import 'package:prefmon/model/prefmon_events.dart';

enum DataSource {
  console,
  tcp,
  unkown,
}

class DebugDataHandler extends ChangeNotifier {
  DataSource _source = DataSource.unkown;
  DataSource get source => _source;
  set source(DataSource value) {
    _source = value;
    notifyListeners();
  }

  List<PrefMonMessageCallback> callbacks = [];
}
