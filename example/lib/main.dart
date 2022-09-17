import 'package:example/game.dart';
import 'package:flutter/material.dart';
import 'package:backbone/widget.dart';

void main() async {
  // Spin up Flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Start the actual app
  runApp(
    BackboneGameWidget(
      game: MainGame()..debugMode = true,
    ),
  );
}
