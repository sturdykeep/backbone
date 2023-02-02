import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:prefmon/core/debouncer.dart';
import 'package:prefmon/core/settings.dart';
import 'package:prefmon/globals.dart';
import 'package:prefmon/widget/statistics.dart';

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

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _pathController.text = _settings.pathToProject ?? '';
    _cmdController.text = _settings.flutterCommand ?? '';

    super.initState();
  }

  void _toggleState() {
    if (_isRunning) {
      _animationController.reverse();
      Globals.worker.stop();
    } else {
      _animationController.forward();
      Globals.worker.start();
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Backbone Performance Monitor'),
          actions: [
            IconButton(
              onPressed: () {
                if (_settings.flutterCommand != null &&
                    _settings.pathToProject != null) {
                  //TODO parse yaml file
                  //TODO start project via isolat
                  //TODO render times for system and messages
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
        ));
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
