// ignore_for_file: must_call_super

import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/realm.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// Notes about the Flame input system:
// * TapDown is always first before LongTapDown
// * TapDown and TapCancel are always before DragStart
// * TapDown and DragStart have different pointerIds, but same positions
// * While drag is happening, hover events are not sent
// * Hover events use a device identifier, that can be reused

// So, how do we track things?
// 1. When tap down happens, we search for a hover with the same position and update it as a tapdown, otherwise create a new one
// 2. LongTapDown just updates the state of the pointer with the same pointerId
// 3. DragStart searches for pointer with cancelled state and exact same position, then updates it

// Longest lifecycle of a pointer looks like this:
// HoverEnter -> Hover -> TapDown -> TapCancel -> LongTapDown -> DragStart -> DragUpdate -> DragEnd

/// A mixin that allows you to add a SINGLE [Realm] to your [FlameGame].
/// It automatically hooks up the input events to the [Realm].
mixin HasRealm on KeyboardEvents {
  late Realm realm;
  bool realmReady = false;

  @override
  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (realmReady) {
      realm.getResource<Input>().onKeyEvent(event, keysPressed);
    }
    super.onKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }
}
