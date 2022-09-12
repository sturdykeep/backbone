import 'package:flutter/services.dart';

enum BackboneKeyState { justPressed, pressed, justReleased }

class BackboneKey {
  final LogicalKeyboardKey key;
  BackboneKeyState state = BackboneKeyState.justPressed;

  BackboneKey(this.key);

  bool get isJustPressed => state == BackboneKeyState.justPressed;
  bool get isPressed => state == BackboneKeyState.pressed;
  bool get isJustReleased => state == BackboneKeyState.justReleased;

  void updateState(BackboneKeyState newState) {
    state = newState;
  }
}
