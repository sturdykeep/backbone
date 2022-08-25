import 'dart:collection';

import 'package:flame/input.dart';
import 'package:flutter/services.dart';

/// Resource which contains all the input data for the current frame.
class Input {
  Set<LogicalKeyboardKey> keysPressed = {};
  PointerHoverInfo? pointerMove;
  Vector2 mousePosition = Vector2.zero();
  HashMap<int, TapDownInfo> taps = HashMap();
  HashSet<int> tapUps = HashSet();
  HashSet<int> tapCancels = HashSet();
}
