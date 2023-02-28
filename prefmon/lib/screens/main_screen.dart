import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:prefmon/core/backbone_worker.dart';
import 'package:prefmon/core/debouncer.dart';
import 'package:prefmon/core/debug_data_model.dart';
import 'package:prefmon/core/prefmon_data_mapper.dart';
import 'package:prefmon/core/settings.dart';
import 'package:prefmon/globals.dart';
import 'package:prefmon/model/prefmon_events.dart';
import 'package:prefmon/widget/statistics.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final _pathController = TextEditingController();
  final _cmdController = TextEditingController();
  final _settings = Settings();
  bool _isRunning = false;
  final _cmdDebouncer = Debouncer(milliseconds: 350);
  var _webSocketActive = false;
  HttpServer? server;
  StreamSubscription<WebSocket>? subscription;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _pathController.text = _settings.pathToProject ?? '';
    _cmdController.text = _settings.flutterCommand ?? '';

    Globals.worker = BackboneWorker(context.read<DebugDataHandler>());
    super.initState();
  }

  void _toggleState() {
    final model = context.read<DebugDataHandler>();
    if (_isRunning) {
      _animationController.reverse();
      Globals.worker.stop();

      if (model.source == DataSource.console) {
        model.source = DataSource.unkown;
      }
    } else {
      _animationController.forward();
      Globals.worker.start();
      if (model.source == DataSource.unkown) {
        model.source = DataSource.console;
      }
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  final port = 8080;

  Future<void> _startWebSocketServer() async {
    final dataHandler = context.read<DebugDataHandler>();
    dataHandler.source = DataSource.tcp;
    var webSocketTransformer = WebSocketTransformer();
    server ??= await HttpServer.bind(InternetAddress.anyIPv4, port);
    if (subscription == null) {
      final stream = server!.transform(webSocketTransformer);
      subscription = stream.listen((WebSocket webSocket) {
        if (dataHandler.source != DataSource.tcp) {
          return;
        }
        debugPrint('WebSocket client connected');
        for (final callback in dataHandler.callbacks) {
          callback.call(Starting());
        }
        webSocket.listen((data) {
          final event = PrefmonDataMapper.parse(data?.toString() ?? "");
          if (event != null) {
            for (final callback in dataHandler.callbacks) {
              callback.call(event);
            }
          }
        }, onError: (err) {
          debugPrint(err);
        }, onDone: () {
          debugPrint('WebSocket client closed');
          for (final callback in dataHandler.callbacks) {
            callback.call(Stopped());
          }
        });
      });
    }
  }

  Future<void> _stopWebsocketServer() async {
    context.read<DebugDataHandler>().source = DataSource.unkown;
  }

  @override
  Widget build(BuildContext context) {
    final currentSource =
        context.select<DebugDataHandler, DataSource>((d) => d.source);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: currentSource == DataSource.console
              ? null
              : () {
                  if (_webSocketActive == false) {
                    _startWebSocketServer();
                  } else {
                    _stopWebsocketServer();
                  }

                  setState(() {
                    _webSocketActive = !_webSocketActive;
                  });
                },
          icon: Icon(
            _webSocketActive == false
                ? Icons.signal_wifi_connected_no_internet_4_rounded
                : Icons.wifi,
            semanticLabel: 'Websocket server',
          ),
        ),
        title: const Text('Backbone Performance Monitor'),
        actions: [
          IconButton(
            onPressed: () {
              if (_settings.flutterCommand != null &&
                  _settings.pathToProject != null) {
                _toggleState();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Select the YAML and Flutter command to lunch',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _animationController,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Project path'),
                      subtitle: TextField(
                        controller: _pathController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          helperText: 'Path to the pubspec.yaml of your game',
                        ),
                      ),
                      trailing: IconButton(
                          onPressed: () {
                            _selectProjectFolder();
                          },
                          icon: const Icon(
                            Icons.folder,
                          )),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Flutter cmd'),
                      subtitle: TextField(
                        controller: _cmdController,
                        decoration: const InputDecoration(
                          helperText: 'e.g flutter run --release -d macos',
                        ),
                        onChanged: (_) {
                          _cmdDebouncer.run(() {
                            _settings.flutterCommand = _cmdController.text;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Card(
                child: Statistics(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectProjectFolder() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'yaml',
      ],
    );

    String? folder;
    if (result != null) {
      File file = File(result.files.single.path!);
      if (file.path.endsWith('pubspec.yaml')) {
        folder = file.path;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Select the pubspec.yaml file of your game',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    if (folder != null) {
      _settings.pathToProject = folder;
      _pathController.text = folder;
    }
  }
}
