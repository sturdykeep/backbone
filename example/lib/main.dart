import 'package:example/game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() async {
  // Spin up Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Start the actual app
  runApp(
    GameWidget(
      game: MainGame(),
    ),
  );
}
