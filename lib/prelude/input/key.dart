import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/realm.dart';
import 'package:flutter/services.dart';

enum BackboneKeyState { justPressed, pressed, justReleased, dead }

class BackboneKey {
  final LogicalKeyboardKey key;
  BackboneKeyState state = BackboneKeyState.justPressed;
  int pressedOnFrame = -1;
  int releasedOnFrame = -1;

  BackboneKey(this.key);

  bool get isJustPressed => state == BackboneKeyState.justPressed;
  bool get isPressed => state == BackboneKeyState.pressed || isJustPressed;
  bool get isJustReleased => state == BackboneKeyState.justReleased;
  bool get isDead => state == BackboneKeyState.dead;

  void updateState(BackboneKeyState newState) {
    state = newState;
  }
}

/// Performs maintenance on the [BackboneKey]s.
void keyboardSystem(Realm realm) {
  final frame = realm.frame;
  final input = realm.getResource<Input>();

  // 1. Make sure to fill out the `pressedOnFrame` property.
  for (final key in input.keys()) {
    if (key.pressedOnFrame == -1 && key.isPressed) {
      key.pressedOnFrame = frame;
    }
  }

  // 2. Make sure to fill out the `releasedOnFrame` property.
  for (final key in input.keys()) {
    if (key.releasedOnFrame == -1 && key.isJustReleased) {
      key.releasedOnFrame = frame;
    }
  }

  // 3. Mark keys that are dead.
  for (final key in input.keys()) {
    if (key.isJustReleased && frame - key.releasedOnFrame > 1) {
      key.updateState(BackboneKeyState.dead);
    }
  }

  // 4. Move keys to `pressed` after one frame of `justPressed`.
  for (final key in input.keys()) {
    if (key.isJustPressed && frame - key.pressedOnFrame > 1) {
      key.updateState(BackboneKeyState.pressed);
    }
  }
}
