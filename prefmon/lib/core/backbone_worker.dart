import 'dart:convert';
import 'dart:io';

import 'package:prefmon/core/debug_data_model.dart';
import 'package:prefmon/core/prefmon_data_mapper.dart';
import 'package:prefmon/core/settings.dart';
import 'package:prefmon/model/prefmon_events.dart';

class BackboneWorker {
  final _settings = Settings();
  late Process _flutterRunner;
  LogCallback? logCallback;
  static const String startTag = 'prefmon:';
  static const String endTag = ':prefmon';
  final DebugDataHandler dataHandler;

  BackboneWorker(this.dataHandler);

  void start() async {
    final pathToYaml = File(_settings.pathToProject!);
    final workingDir = pathToYaml.parent.path;
    final cmd = _settings.flutterCommand!;
    final cmdParts = cmd.split(" ");
    _flutterRunner = await Process.start(
      "flutter",
      cmdParts.sublist(1),
      workingDirectory: workingDir,
      runInShell: Platform.isWindows || Platform.isLinux,
    );
    _flutterRunner.exitCode.then((value) {
      for (var callback in dataHandler.callbacks) {
        callback.call(Stopped());
      }
    });
    final encoding = utf8.decoder;
    log(Starting(), force: true);
    _flutterRunner.stdout.listen((event) {
      final messages = encoding.convert(event);
      final dataEvent = PrefmonDataMapper.parse(messages);
      if (dataEvent != null) {
        log(dataEvent);
      }
    });
    _flutterRunner.stderr.listen((event) {
      final message = encoding.convert(event);
      logCallback?.call('ERROR: $message');
    });
  }

  void log(PrefMonEvent data, {bool force = false}) {
    if (force || dataHandler.source == DataSource.console) {
      for (var callback in dataHandler.callbacks) {
        callback.call(data);
      }
    }
  }

  void stop() {
    _flutterRunner.kill();
    log(Stopped(), force: true);
  }
}
