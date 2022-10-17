import 'dart:convert';
import 'dart:io';

import 'package:prefmon/core/settings.dart';

abstract class PrefMonEvent {}

class PrefMonDataEvent extends PrefMonEvent {
  final String category;
  final String data;

  PrefMonDataEvent(this.category, this.data);

  @override
  String toString() {
    return "$category->$data";
  }
}

class Starting extends PrefMonEvent {}

class Stopped extends PrefMonEvent {}

typedef PrefMonMessageCallback = void Function(PrefMonEvent event);
typedef LogCallback = void Function(String message);

class BackboneWorker {
  final _settings = Settings();
  late Process _flutterRunner;
  PrefMonMessageCallback? callback;
  LogCallback? logCallback;
  static const String startTag = 'prefmon:';
  static const String endTag = ':prefmon';

  BackboneWorker();

  void start() async {
    final pathToYaml = File(_settings.pathToProject!);
    final workingDir = pathToYaml.parent.path;
    final cmd = _settings.flutterCommand!;
    final cmdParts = cmd.split(" ");
    _flutterRunner = await Process.start(
      "flutter",
      cmdParts.sublist(1),
      workingDirectory: workingDir,
      runInShell: Platform.isWindows,
    );
    _flutterRunner.exitCode.then((value) => callback?.call(Stopped()));
    final encoding = utf8.decoder;
    callback?.call(Starting());
    _flutterRunner.stdout.listen((event) {
      final messages = encoding.convert(event);
      LineSplitter ls = const LineSplitter();
      for (var message in ls.convert(messages)) {
        final start = message.indexOf(startTag);
        if (start >= 0) {
          final end = message.lastIndexOf(endTag);
          if (end >= 0) {
            final prefMonData = message.substring(start + startTag.length, end);
            final parts = prefMonData.split('->');
            final category = parts.first;
            final data = parts.last;
            callback?.call(PrefMonDataEvent(category, data));
          }
        } else {
          logCallback?.call(message);
        }
      }
    });
    _flutterRunner.stderr.listen((event) {
      final message = encoding.convert(event);
      logCallback?.call('ERROR:$message');
    });
  }

  void stop() {
    _flutterRunner.kill();
    callback?.call(Stopped());
  }
}
