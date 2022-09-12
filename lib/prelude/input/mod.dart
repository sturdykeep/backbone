import 'package:backbone/builders.dart';
import 'package:backbone/prelude/input/plugins/drag.dart';
import 'package:backbone/prelude/input/key.dart';
import 'package:backbone/prelude/input/plugins/hoverable.dart';
import 'package:backbone/prelude/input/plugins/taps.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart' as ex;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

// References
// https://docs.rs/bevy/latest/bevy/input/struct.Input.html
// https://bevy-cheatbook.github.io/input.html

void inputPlugin(RealmBuilder builder) {
  // Taps
  builder
    ..withTrait(TappableTrait)
    ..withSystem(tappableSystem);

  // Hover
  builder
    ..withTrait(HoverableTrait)
    ..withSystem(hoverableSystem);

  // Drag
  builder
    ..withTrait(DraggableTrait)
    ..withTrait(DragReceiverTrait)
    ..withSystem(draggableSystem)
    ..withSystem(dragReceiverSystem);
}

/// Resource which contains all the input data for the current frame.
class Input {
  // Raw interaction data
  final _tapDowns = <ex.TapDownEvent>[];
  final _longTapDowns = <ex.TapDownEvent>[];
  final _tapUps = <ex.TapUpEvent>[];
  final _tapCancels = <ex.TapCancelEvent>[];
  final _dragStarts = <ex.DragStartEvent>[];
  final _dragUpdates = <ex.DragUpdateEvent>[];
  final _dragEnds = <ex.DragEndEvent>[];
  final _hoverEvents = <PointerHoverInfo>[];

  // Processed data
  final _keyStates = <BackboneKey>[];
  int _lastPointerId = 0;
  final _pointers = <Pointer>[];

  // Input hooks
  void onTapDown(ex.TapDownEvent event) {
    _tapDowns.add(event);

    // Update or create a pointer
    // First search for hovering pointer with the same position
    final hoveringPointer = _pointers.firstWhereOrNull(
      (pointer) =>
          pointer.isHovering &&
          pointer.position == event.canvasPosition &&
          pointer.kind == event.deviceKind,
    );
    if (hoveringPointer != null) {
      hoveringPointer.pushState(PointerStateDown(event));
      debugPrint(
          "Hover:${hoveringPointer.id} (${(hoveringPointer.history.last as PointerStateHover).raw.eventPosition.global}) -> Down (${hoveringPointer.position})");
    } else {
      final newPointer = Pointer.fromTapDownEvent(_lastPointerId++, event);
      _pointers.add(newPointer);
      debugPrint("New Down:${newPointer.id} (${event.canvasPosition})");
    }
  }

  void onLongTapDown(ex.TapDownEvent event) {
    _longTapDowns.add(event);

    // Update existing pointer or throw if not found
    final pointer = _pointers.firstWhere(
      (pointer) =>
          pointer.state is PointerStateDown &&
          pointer.device == event.pointerId,
      orElse: () => throw Exception(
          "Long tap down event received for a pointer that is not already registered as down"),
    );
    pointer.pushState(PointerStateLongDown(event));
    debugPrint("Down:${pointer.id} -> LongDown (${event.canvasPosition})");
  }

  void onTapUp(ex.TapUpEvent event) {
    _tapUps.add(event);

    // Update existing pointer or throw if not found
    final pointer = _pointers.firstWhere(
      (pointer) =>
          (pointer.state is PointerStateDown &&
              pointer.device == event.pointerId) ||
          (pointer.state is PointerStateLongDown &&
              pointer.device == event.pointerId),
      orElse: () => throw Exception(
          "Tap up event received for a pointer that is not already registered as down"),
    );
    pointer.pushState(PointerStateUp(event));
    debugPrint(
        "${pointer.history.last is PointerStateDown ? "Down" : "LongDown"}:${pointer.id} -> Up (${event.canvasPosition})");
  }

  void onTapCancel(ex.TapCancelEvent event) {
    _tapCancels.add(event);

    // Update existing pointer or throw if not found
    final pointer = _pointers.firstWhere(
      (pointer) =>
          (pointer.state is PointerStateDown &&
              pointer.device == event.pointerId) ||
          (pointer.state is PointerStateLongDown &&
              pointer.device == event.pointerId),
      orElse: () => throw Exception(
          "Tap cancel event received for a pointer that is not already registered as down"),
    );
    pointer.pushState(PointerStateCancelled(event));
    debugPrint(
        "${pointer.history.last is PointerStateDown ? "Down" : "LongDown"}:${pointer.id} -> Cancelled (${pointer.position})");
  }

  void onDragStart(ex.DragStartEvent event) {
    _dragStarts.add(event);

    // Update an existing cancelled pointer or throw if not found
    final pointer = _pointers.firstWhere(
      (pointer) =>
          pointer.state is PointerStateCancelled &&
          pointer.position == event.canvasPosition,
      orElse: () => throw Exception(
          "Drag start event received for a pointer that is not already registered as cancelled"),
    );
    pointer.pushState(PointerStateDragStart(event));
    debugPrint(
        "Cancelled:${pointer.id} -> DragStart (${event.canvasPosition})");
  }

  void onDragUpdate(ex.DragUpdateEvent event) {
    _dragUpdates.add(event);

    // Update an existing pointer or throw if not found
    final pointer = _pointers.firstWhere(
      (pointer) =>
          (pointer.state is PointerStateDragStart ||
              pointer.state is PointerStateDragUpdate) &&
          pointer.device == event.pointerId,
      orElse: () => throw Exception(
          "Drag update event received for a pointer that is not already registered as drag-started or drag-updated"),
    );
    pointer.pushState(PointerStateDragUpdate(event));
    debugPrint(
        "${pointer.history.last is PointerStateDragStart ? "DragStart" : "DragUpdate"}:${pointer.id} -> DragUpdate (${pointer.position})");
  }

  void onDragEnd(ex.DragEndEvent event) {
    _dragEnds.add(event);

    // Update an existing pointer or throw if not found
    final pointer = _pointers.firstWhere(
      (pointer) =>
          (pointer.state is PointerStateDragStart ||
              pointer.state is PointerStateDragUpdate) &&
          pointer.device == event.pointerId,
      orElse: () => throw Exception(
          "Drag end event received for a pointer that is not already registered as drag-started or drag-updated"),
    );
    pointer.pushState(PointerStateDragEnd(event));
    debugPrint(
        "${pointer.history.last is PointerStateDragStart ? "DragStart" : "DragUpdate"}:${pointer.id} -> DragEnd (${pointer.position})");
  }

  void onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Check `event` to create or update the key state
    final logicalKey = event.logicalKey;
    final containsEventKey = _keyStates.any((key) => key.key == logicalKey);
    if (containsEventKey == false) {
      _keyStates.add(BackboneKey(logicalKey));
    }
    final keyState = event is RawKeyDownEvent
        ? BackboneKeyState.justPressed
        : event is RawKeyUpEvent
            ? BackboneKeyState.justReleased
            : BackboneKeyState.pressed;
    final existingKey = _keyStates.firstWhere((key) => key.key == logicalKey);
    existingKey.updateState(keyState);
    debugPrint("Key (${existingKey.key.debugName}) -> $keyState");

    // Check `keysPressed` to set the rest of keys to pressed
    for (final key in keysPressed) {
      if (key == logicalKey) {
        continue;
      }
      final containsPressedKey = _keyStates.any((key) => key.key == logicalKey);
      if (containsPressedKey == false) {
        _keyStates.add(BackboneKey(key));
      }
      _keyStates.firstWhere((key) => key.key == logicalKey).updateState(
            BackboneKeyState.pressed,
          );
    }
  }

  void onHover(PointerHoverInfo event) {
    _hoverEvents.add(event);

    // Update an existing pointer or create a new one
    final hoveringPointer = _pointers.firstWhereOrNull((pointer) =>
        pointer.state is PointerStateHover &&
        pointer.device == event.raw.device);

    if (hoveringPointer != null) {
      hoveringPointer.pushState(PointerStateHover(event));
      debugPrint(
          "Hover:${hoveringPointer.id} -> Hover (${hoveringPointer.position})");
    } else {
      final newPointer = Pointer.fromHoverEvent(_lastPointerId++, event);
      _pointers.add(newPointer);
      debugPrint("New Hover:${newPointer.id} (${newPointer.position})");
    }
  }

  void clear() {
    _tapDowns.clear();
    _longTapDowns.clear();
    _tapUps.clear();
    _tapCancels.clear();
    _dragStarts.clear();
    _dragUpdates.clear();
    _dragEnds.clear();
    _hoverEvents.clear();
  }

  // Keyboard API
  bool justPressed(LogicalKeyboardKey key) {
    if (_keyStates.any((keyState) => keyState.key == key) == false) {
      return false;
    }
    final keyState = _keyStates.firstWhere((keyState) => keyState.key == key);
    return keyState.isJustPressed;
  }

  bool justPressedAny(List<LogicalKeyboardKey> keys) {
    for (final key in keys) {
      if (justPressed(key)) {
        return true;
      }
    }
    return false;
  }

  bool justPressedAll(List<LogicalKeyboardKey> keys) {
    for (final key in keys) {
      if (justPressed(key) == false) {
        return false;
      }
    }
    return true;
  }

  bool pressed(LogicalKeyboardKey key) {
    if (_keyStates.any((keyState) => keyState.key == key) == false) {
      return false;
    }
    final keyState = _keyStates.firstWhere((keyState) => keyState.key == key);
    return keyState.isPressed;
  }

  bool pressedAny(List<LogicalKeyboardKey> keys) {
    for (final key in keys) {
      if (pressed(key)) {
        return true;
      }
    }
    return false;
  }

  bool pressedAll(List<LogicalKeyboardKey> keys) {
    for (final key in keys) {
      if (pressed(key) == false) {
        return false;
      }
    }
    return true;
  }

  bool justReleased(LogicalKeyboardKey key) {
    if (_keyStates.any((keyState) => keyState.key == key) == false) {
      return false;
    }
    final keyState = _keyStates.firstWhere((keyState) => keyState.key == key);
    return keyState.isJustReleased;
  }

  bool justReleasedAny(List<LogicalKeyboardKey> keys) {
    for (final key in keys) {
      if (justReleased(key)) {
        return true;
      }
    }
    return false;
  }

  bool justReleasedAll(List<LogicalKeyboardKey> keys) {
    for (final key in keys) {
      if (justReleased(key) == false) {
        return false;
      }
    }
    return true;
  }

  void clearJustPressed(LogicalKeyboardKey key) {
    _keyStates.removeWhere(
        (keyState) => keyState.key == key && keyState.isJustPressed);
  }

  void clearJustReleased(LogicalKeyboardKey key) {
    _keyStates.removeWhere(
        (keyState) => keyState.key == key && keyState.isJustReleased);
  }

  bool isModified(
      {bool shift = false, bool control = false, bool alt = false}) {
    return (shift == false || pressed(LogicalKeyboardKey.shiftLeft)) &&
        (control == false || pressed(LogicalKeyboardKey.controlLeft)) &&
        (alt == false || pressed(LogicalKeyboardKey.altLeft));
  }

  // Pointer API
  // - TapDown
  Iterable<Pointer> pointers() {
    return _pointers;
  }

  Iterable<Pointer> justTapDownPointers() {
    final tapDowns = _tapDowns;
    return _pointers.where((pointer) =>
        pointer.isDown &&
        tapDowns.any((tapDown) => tapDown.pointerId == pointer.device));
  }

  bool pointerJustDown(int id) {
    return justTapDownPointers().any((pointer) => pointer.id == id);
  }

  void clearJustDownPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _tapDowns.removeWhere((tapDown) => tapDown.pointerId == pointer.device);
  }

  // - LongTapDown
  Iterable<Pointer> justLongTapDownPointers() {
    final longTapDowns = _longTapDowns;
    return _pointers.where((pointer) =>
        pointer.isLongDown &&
        longTapDowns
            .any((longTapDown) => longTapDown.pointerId == pointer.device));
  }

  bool pointerJustLongDown(int id) {
    return justLongTapDownPointers().any((pointer) => pointer.id == id);
  }

  void clearJustLongDownPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _longTapDowns
        .removeWhere((longTapDown) => longTapDown.pointerId == pointer.device);
  }

  // - TapUp
  Iterable<Pointer> justTapUpPointers() {
    final tapUps = _tapUps;
    return _pointers.where((pointer) =>
        pointer.isUp &&
        tapUps.any((tapUp) => tapUp.pointerId == pointer.device));
  }

  bool pointerJustUp(int id) {
    return justTapUpPointers().any((pointer) => pointer.id == id);
  }

  void clearJustUpPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _tapUps.removeWhere((tapUp) => tapUp.pointerId == pointer.device);
  }

  // - TapCancel
  Iterable<Pointer> justTapCancelPointers() {
    final tapCancels = _tapCancels;
    return _pointers.where((pointer) =>
        pointer.isUp &&
        tapCancels.any((tapCancel) => tapCancel.pointerId == pointer.device));
  }

  bool pointerJustCancel(int id) {
    return justTapCancelPointers().any((pointer) => pointer.id == id);
  }

  void clearJustCancelPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _tapCancels
        .removeWhere((tapCancel) => tapCancel.pointerId == pointer.device);
  }

  // - Hover
  Iterable<Pointer> justHoverPointers() {
    final hovers = _hoverEvents;
    return _pointers.where((pointer) =>
        pointer.isHovering &&
        hovers.any((hover) => hover.raw.device == pointer.device));
  }

  bool pointerJustHover(int id) {
    return justHoverPointers().any((pointer) => pointer.id == id);
  }

  void clearJustHoverPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _hoverEvents.removeWhere((hover) => hover.raw.device == pointer.device);
  }

  // - DragStart
  Iterable<Pointer> justDragStartPointers() {
    final dragStarts = _dragStarts;
    return _pointers.where((pointer) =>
        (pointer.isDragStart || pointer.wasDragStart) &&
        dragStarts.any((dragStart) => dragStart.pointerId == pointer.device));
  }

  bool pointerJustDragStart(int id) {
    return justDragStartPointers().any((pointer) => pointer.id == id);
  }

  void clearJustDragStartPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _dragStarts
        .removeWhere((dragStart) => dragStart.pointerId == pointer.device);
  }

  // - DragUpdate
  Iterable<Pointer> justDragUpdatePointers() {
    final dragUpdates = _dragUpdates;
    return _pointers.where((pointer) =>
        pointer.isDragUpdate &&
        dragUpdates
            .any((dragUpdate) => dragUpdate.pointerId == pointer.device));
  }

  bool pointerJustDragUpdate(int id) {
    return justDragUpdatePointers().any((pointer) => pointer.id == id);
  }

  void clearJustDragUpdatePointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _dragUpdates
        .removeWhere((dragUpdate) => dragUpdate.pointerId == pointer.device);
  }

  // - DragEnd
  Iterable<Pointer> justDragEndPointers() {
    final dragEnds = _dragEnds;
    return _pointers.where((pointer) =>
        pointer.isDragEnd &&
        dragEnds.any((dragEnd) => dragEnd.pointerId == pointer.device));
  }

  bool pointerJustDragEnd(int id) {
    return justDragEndPointers().any((pointer) => pointer.id == id);
  }

  void clearJustDragEndPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _dragEnds.removeWhere((dragEnd) => dragEnd.pointerId == pointer.device);
  }

  // High-level Pointer API
  Iterable<Pointer> justPressedPointers() {
    return justTapDownPointers();
  }

  bool pointerJustPressed(int id) {
    return pointerJustDown(id);
  }

  Iterable<Pointer> pressedPointers() {
    return _pointers.where((pointer) => pointer.isPressed);
  }

  bool pointerPressed(int id) {
    return pressedPointers().any((pointer) => pointer.id == id);
  }

  Iterable<Pointer> justReleasedPointers() {
    return justTapUpPointers().toList() + justDragEndPointers().toList();
  }

  bool pointerJustReleased(int id) {
    return pointerJustUp(id) || pointerJustDragEnd(id);
  }
}
