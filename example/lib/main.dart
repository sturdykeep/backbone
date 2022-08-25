import 'dart:async';

import 'package:example/game.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

void main() async {
  // Spin up Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Start the actual app
  runApp(
    const GameScreen(),
  );
}
