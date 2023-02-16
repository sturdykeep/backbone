import 'package:backbone/builders.dart';
import 'package:backbone/prelude/input/long.dart';
import 'package:backbone/prelude/input/plugins/drag.dart';
import 'package:backbone/prelude/input/key.dart';
import 'package:backbone/prelude/input/plugins/hoverable.dart';
import 'package:backbone/prelude/input/plugins/selectable.dart';
import 'package:backbone/prelude/input/plugins/taps.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:collection/collection.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// References
// https://docs.rs/bevy/latest/bevy/input/struct.Input.html
// https://bevy-cheatbook.github.io/input.html

void inputPlugin(RealmBuilder builder) {
  builder.withSystem(longDownSystem);
  builder.withSystem(keyboardSystem);

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

  // Taps
  builder
    ..withTrait(TappableTrait)
    ..withSystem(tappableSystem);

  // Selection
  builder
    ..withResource(Selection, Selection())
    ..withTrait(SelectableTrait)
    ..withSystem(ensureSelectableNodesAreTappable)
    ..withSystem(selectableSystem);
}

/// Resource which contains all the input data for the current frame.
class Input {
  // Raw interaction data
  final _tapDowns = <PointerStateDown>[];
  final _longTapDowns = <PointerStateLongDown>[];
  final _tapUps = <PointerStateUp>[];
  final _tapCancels = <PointerStateCancelled>[];
  final _dragStarts = <PointerStateDragStart>[];
  final _dragUpdates = <PointerStateDragUpdate>[];
  final _dragEnds = <PointerStateDragEnd>[];
  final _hoverEvents = <PointerStateHover>[];
  final _pointerAddedEvents = <PointerStateAdded>[];
  final _pointerRemovedEvents = <PointerStateRemoved>[];

  final Duration longDownDuration = const Duration(milliseconds: 500);

  /// Enable or disable debug prints
  bool debugMode = false;
  // Processed data
  final _keyStates = <BackboneKey>[];
  final _pointers = <Pointer>[];
  final _pointersGraveyard = <Pointer>[];
  final _pendingHovers = <Pointer>[];

  void _debugPrint(String message) {
    if (debugMode == false) return;
    debugPrint(message);
  }

  bool _isCloseBy(Vector2 a, Vector2 b) {
    return (a.x - b.x).abs() <= 10.0 && (a.y - b.y).abs() <= 10.0;
  }

  // Input hooks
  void onPointerHover(PointerHoverEvent event) {
    // Update an existing hover or update a hover enter
    final pointerHoverStart = _pointers.firstWhereOrNull(
        (p) => p.state is PointerStateAdded && p.deviceId == event.device);
    if (pointerHoverStart != null) {
      pointerHoverStart.pushState(PointerStateHover(event));

      _debugPrint(
          "${pointerHoverStart.history.last.debugName}:${pointerHoverStart.id} -> Hover (${pointerHoverStart.position})");
    } else {
      final pointerHover = _pointers.firstWhereOrNull(
          (p) => p.state is PointerStateHover && p.id == event.pointer);
      final state = PointerStateHover(event);
      _hoverEvents.add(state);
      if (pointerHover != null) {
        pointerHover.replaceStateIfIs(state);
      } else {
        // Create a new hover
        final pointer = Pointer(state);
        _pointers.add(pointer);
        _pendingHovers.add(pointer);
        _debugPrint(
            "New ${pointer.state.debugName}:${pointer.id} ${pointer.position}");
      }
    }
  }

  void onPointerAdded(PointerAddedEvent event) {
    // Create a new pointer
    final state = PointerStateAdded(event);
    _pointerAddedEvents.add(state);
    final pointer = Pointer(state);
    _pointers.add(pointer);
    _pendingHovers.add(pointer);
    _debugPrint(
        "New ${pointer.state.debugName}:${pointer.id} (${pointer.position})");
  }

  void onPointerRemoved(PointerRemovedEvent event) {
    // Update an existing hover or hover enter pointer
    final leavingPointer = _pointers.firstWhere((pointer) =>
        pointer.id == event.pointer &&
        (pointer.state is PointerStateHover ||
            pointer.state is PointerStateAdded));
    final state = PointerStateRemoved(event);
    _pointerRemovedEvents.add(state);
    leavingPointer.pushState(state);
    _pendingHovers.remove(leavingPointer);
    _debugPrint(
        "${leavingPointer.history.last.debugName}:${leavingPointer.id} -> ${leavingPointer.state.debugName} (${event.position.toVector2()})");
  }

  void onPointerDown(PointerDownEvent event) {
    // Update or create a pointer
    // First search for hovering pointer with the same position
    final hoveringPointer = _pointers.firstWhereOrNull(
      (pointer) =>
          pointer.isHovering &&
          _isCloseBy(pointer.position, event.position.toVector2()) &&
          pointer.kind == event.kind,
    );
    final state = PointerStateDown(event);
    _tapDowns.add(state);
    if (hoveringPointer != null) {
      hoveringPointer.pushState(state);
      _pendingHovers.remove(hoveringPointer);
      _debugPrint(
          "${hoveringPointer.history.last.debugName}:${hoveringPointer.id} (${(hoveringPointer.history.last as PointerStateHover).raw.position}) -> ${hoveringPointer.state.debugName} (${hoveringPointer.position})");
    } else {
      // Create a new pointer
      final pointer = Pointer(state);
      _pointers.add(pointer);
      _debugPrint(
          "New ${pointer.state.debugName}:${pointer.id} (${pointer.position})");
    }
  }

  void onPointerUp(PointerUpEvent event) {
    // Update a down or longdown pointer, or
    // finish a drag
    final pointer = _pointers.firstWhereOrNull(
      (pointer) =>
          (pointer.state is PointerStateDown && pointer.id == event.pointer) ||
          (pointer.state is PointerStateLongDown &&
              pointer.id == event.pointer) ||
          (pointer.state is PointerStateDragStart &&
              pointer.id == event.pointer) ||
          (pointer.state is PointerStateDragUpdate &&
              pointer.id == event.pointer),
    );
    if (pointer != null) {
      if (pointer.state is PointerStateDragStart ||
          pointer.state is PointerStateDragUpdate) {
        final state = PointerStateDragEnd(event);
        _dragEnds.add(state);
        pointer.pushState(state);
        _debugPrint(
            "${pointer.history.last.debugName}:${pointer.id} -> ${pointer.state.debugName} (${event.position.toVector2()})");
      } else {
        final state = PointerStateUp(event);
        _tapUps.add(state);
        pointer.pushState(state);
        _debugPrint(
            "${pointer.history.last.debugName}:${pointer.id} -> ${pointer.state.debugName} (${event.position.toVector2()})");
      }
    } else {
      assert(pointer != null,
          "Up event received for a pointer that is not already registered as down, long down or drag");
    }
  }

  void onPointerMove(PointerMoveEvent event) {
    // Starts a drag if the pointer is down or long down
    // or updates a drag if the pointer is already dragging
    final pointer = _pointers.firstWhereOrNull(
      (pointer) =>
          (pointer.state is PointerStateDown && pointer.id == event.pointer) ||
          (pointer.state is PointerStateLongDown &&
              pointer.id == event.pointer),
    );
    final dragPointer = _pointers.firstWhereOrNull(
      (pointer) =>
          (pointer.state is PointerStateDragStart &&
              pointer.id == event.pointer) ||
          (pointer.state is PointerStateDragUpdate &&
              pointer.id == event.pointer),
    );
    if (pointer != null) {
      final state = PointerStateDragStart(event);
      _dragStarts.add(state);
      pointer.pushState(state);
      _debugPrint(
          "${pointer.history.last.debugName}:${pointer.id} -> ${pointer.state.debugName} (${event.position})");
    } else if (dragPointer != null) {
      final state = PointerStateDragUpdate(event);
      if (dragPointer.state is PointerStateDragStart) {
        _dragUpdates.add(state);
        dragPointer.pushState(state);
        _debugPrint(
            "${dragPointer.history.last.debugName}:${dragPointer.id} -> ${dragPointer.state.debugName} (${event.position})");
      } else {
        _dragUpdates.add(state);
        dragPointer.replaceStateIfIs(state);
      }
    } else {
      assert(pointer != null || dragPointer != null,
          "Move event received for a pointer that is not already registered as down or long down");
    }
  }

  bool onKeyEvent(
    KeyEvent event,
  ) {
    // Check `event` to create or update the key state
    final logicalKey = event.logicalKey;
    final containsEventKey = _keyStates.any((key) => key.key == logicalKey);
    if (containsEventKey == false) {
      _keyStates.add(BackboneKey(logicalKey));
    }
    final existingKey = _keyStates.firstWhere((key) => key.key == logicalKey);

    // Based on the existing state of the key, change it to `justPressed`, `pressed` or `justReleased`
    if (event is KeyDownEvent) {
      if (existingKey.state == BackboneKeyState.dead ||
          existingKey.state == BackboneKeyState.justReleased) {
        existingKey.updateState(BackboneKeyState.justPressed);
        _debugPrint(
            "Key (${existingKey.key.debugName}) -> ${BackboneKeyState.justPressed} from ${event.runtimeType}");
      }
    } else if (event is KeyUpEvent) {
      if (existingKey.state == BackboneKeyState.pressed ||
          existingKey.state == BackboneKeyState.justPressed) {
        existingKey.updateState(BackboneKeyState.justReleased);
        _debugPrint(
            "Key (${existingKey.key.debugName}) -> ${BackboneKeyState.justReleased} from ${event.runtimeType}");
      }
    }
    return true;
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

    // Move all cancelled, up and drag-end pointers to the graveyard
    /*_pointers.removeWhere((pointer) {
      if (pointer.state is PointerStateCancelled ||
          pointer.state is PointerStateUp ||
          pointer.state is PointerStateDragEnd ||
          pointer.state is PointerStateRemoved ||
          pointer.state is PointerStateTimeout) {
        _pointersGraveyard.add(pointer);
        _debugPrint(
            "Moved ${pointer.state.runtimeType}:${pointer.id} to graveyard");
        return true;
      }
      return false;
    });
    
    // Check all hover pointers to see if they need to time out
    for (var pointer in _pointers) {
      if (pointer.state is PointerStateHover) {
        final hoverState = pointer.state as PointerStateHover;
        if (DateTime.now().difference(hoverState.lastHoverTime).inSeconds > 5 &&
            pointer.kind != PointerDeviceKind.mouse) {
          pointer.pushState(PointerStateTimeout());
          _debugPrint("Hover:${pointer.id} -> Timeout");
        }
      }
    }
    */
  }

  // Keyboard API
  List<BackboneKey> keys() {
    return _keyStates;
  }

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
  Iterable<Pointer> pointers() {
    return _pointers;
  }

  Iterable<Pointer> graveyardPointers() {
    return _pointersGraveyard;
  }

  Iterable<Pointer> pendingHoverPointers() {
    return _pendingHovers;
  }

  // - TapDown
  Iterable<Pointer> justTapDownPointers() {
    final tapDowns = _tapDowns;
    return _pointers.where((pointer) =>
        pointer.isDown &&
        tapDowns.any((tapDown) => tapDown.pointerId == pointer.id));
  }

  bool pointerJustDown(int id) {
    return justTapDownPointers().any((pointer) => pointer.id == id);
  }

  void clearJustDownPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _tapDowns.removeWhere((tapDown) => tapDown.pointerId == pointer.id);
  }

  // - LongTapDown
  Iterable<Pointer> justLongTapDownPointers() {
    final longTapDowns = _longTapDowns;
    return _pointers.where((pointer) =>
        pointer.isLongDown &&
        longTapDowns.any((longTapDown) => longTapDown.pointerId == pointer.id));
  }

  bool pointerJustLongDown(int id) {
    return justLongTapDownPointers().any((pointer) => pointer.id == id);
  }

  void clearJustLongDownPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _longTapDowns
        .removeWhere((longTapDown) => longTapDown.pointerId == pointer.id);
  }

  // - TapUp
  Iterable<Pointer> justTapUpPointers() {
    final tapUps = _tapUps;
    return _pointers.where((pointer) =>
        pointer.isUp && tapUps.any((tapUp) => tapUp.pointerId == pointer.id));
  }

  bool pointerJustUp(int id) {
    return justTapUpPointers().any((pointer) => pointer.id == id);
  }

  void clearJustUpPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _tapUps.removeWhere((tapUp) => tapUp.pointerId == pointer.id);
  }

  // - TapCancel
  Iterable<Pointer> justTapCancelPointers() {
    final tapCancels = _tapCancels;
    return _pointers.where((pointer) =>
        pointer.isUp &&
        tapCancels.any((tapCancel) => tapCancel.pointerId == pointer.id));
  }

  bool pointerJustCancel(int id) {
    return justTapCancelPointers().any((pointer) => pointer.id == id);
  }

  void clearJustCancelPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _tapCancels.removeWhere((tapCancel) => tapCancel.pointerId == pointer.id);
  }

  // - HoverEnter
  Iterable<Pointer> justHoverEnterPointers() {
    final hoverEnters = _pointerAddedEvents;
    return _pointers.where((pointer) =>
        pointer.isPointerAdded &&
        hoverEnters
            .any((hoverEnter) => hoverEnter.deviceId == pointer.deviceId));
  }

  bool pointerJustHoverEnter(int id) {
    return justHoverEnterPointers().any((pointer) => pointer.id == id);
  }

  void clearJustHoverEnterPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _pointerAddedEvents
        .removeWhere((hoverEnter) => hoverEnter.deviceId == pointer.deviceId);
  }

  // - Hover
  Iterable<Pointer> justHoverPointers() {
    final hovers = _hoverEvents;
    return _pointers.where((pointer) =>
        pointer.isHovering &&
        hovers.any((hover) => hover.deviceId == pointer.deviceId));
  }

  bool pointerJustHover(int id) {
    return justHoverPointers().any((pointer) => pointer.id == id);
  }

  void clearJustHoverPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _hoverEvents.removeWhere((hover) => hover.deviceId == pointer.deviceId);
  }

  // - HoverLeave
  Iterable<Pointer> justHoverLeavePointers() {
    final hoverLeaves = _pointerRemovedEvents;
    return _pointers.where((pointer) =>
        pointer.isPointerRemoved &&
        hoverLeaves
            .any((hoverLeave) => hoverLeave.deviceId == pointer.deviceId));
  }

  bool pointerJustHoverLeave(int id) {
    return justHoverLeavePointers().any((pointer) => pointer.id == id);
  }

  void clearJustHoverLeavePointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _pointerRemovedEvents
        .removeWhere((hoverLeave) => hoverLeave.deviceId == pointer.deviceId);
  }

  // - DragStart
  Iterable<Pointer> justDragStartPointers() {
    final dragStarts = _dragStarts;
    return _pointers.where((pointer) =>
        (pointer.isDragStart || pointer.wasDragStart) &&
        dragStarts.any((dragStart) => dragStart.pointerId == pointer.id));
  }

  bool pointerJustDragStart(int id) {
    return justDragStartPointers().any((pointer) => pointer.id == id);
  }

  void clearJustDragStartPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _dragStarts.removeWhere((dragStart) => dragStart.pointerId == pointer.id);
  }

  // - DragUpdate
  Iterable<Pointer> justDragUpdatePointers() {
    final dragUpdates = _dragUpdates;
    return _pointers.where((pointer) =>
        pointer.isDragUpdate &&
        dragUpdates.any((dragUpdate) => dragUpdate.pointerId == pointer.id));
  }

  bool pointerJustDragUpdate(int id) {
    return justDragUpdatePointers().any((pointer) => pointer.id == id);
  }

  void clearJustDragUpdatePointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _dragUpdates
        .removeWhere((dragUpdate) => dragUpdate.pointerId == pointer.id);
  }

  // - DragEnd
  Iterable<Pointer> justDragEndPointers() {
    final dragEnds = _dragEnds;
    return _pointers.where((pointer) =>
        pointer.isDragEnd &&
        dragEnds.any((dragEnd) => dragEnd.pointerId == pointer.id));
  }

  bool pointerJustDragEnd(int id) {
    return justDragEndPointers().any((pointer) => pointer.id == id);
  }

  void clearJustDragEndPointer(int id) {
    final pointer = _pointers.firstWhere((pointer) => pointer.id == id);
    _dragEnds.removeWhere((dragEnd) => dragEnd.pointerId == pointer.id);
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
