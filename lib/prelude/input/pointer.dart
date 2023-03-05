// ignore_for_file: implementation_imports

import 'package:backbone/realm_mixin.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';

/// Wraps a pointer device doing something on the screen.
/// Includes convenience methods for accessing data like position, state, etc.
class Pointer {
  PointerState state;
  // Grab from current state, or last state that has an underlaying event
  int get id =>
      state.pointerId ??
      history.lastWhere((s) => s.pointerId != null).pointerId!;
  Vector2 get startPosition =>
      history.isNotEmpty ? history.first.position! : state.position!;
  PointerDeviceKind get kind =>
      state.kind ?? history.lastWhere((s) => s.kind != null).kind!;
  int get deviceId =>
      state.deviceId ?? history.lastWhere((s) => s.deviceId != null).deviceId!;
  final List<PointerState> history = [];
  dynamic payload;

  Pointer(this.state);

  // Helper methods and getters
  PointerState pushState(PointerState state) {
    final oldState = this.state;
    this.state = state;
    history.add(oldState);
    return oldState;
  }

  S? replaceStateIfIs<S extends PointerState>(S state) {
    if (this.state is S) {
      final oldState = this.state;
      this.state = state;
      return oldState as S;
    }
    return null;
  }

  bool historyHas<S extends PointerState>() {
    return history.any((s) => s is S);
  }

  S historyGet<S extends PointerState>() {
    return history.firstWhere((s) => s is S) as S;
  }

  /// Most up to date position of the pointer.
  Vector2 get position {
    if (state is PointerStateDragEnd) {
      if (history.any((state) => state is PointerStateDragUpdate)) {
        return (history.lastWhere((state) => state is PointerStateDragUpdate)
                as PointerStateDragUpdate)
            .position!;
      } else {
        return startPosition;
      }
    } else if (state is PointerStateTimeout) {
      if (history.any((state) => state is PointerStateHover)) {
        return (history.lastWhere((state) => state is PointerStateHover)
                as PointerStateHover)
            .position!;
      } else {
        return startPosition;
      }
    } else if (state is PointerStateCancelled) {
      return history[history.length - 1].position!;
    } else {
      return state.position ?? startPosition;
    }
  }

  Vector2 worldPosition(FlameGame game, {PointerState? fromState}) {
    final positionToTransform = fromState?.position ?? position;
    final afterViewport =
        game.camera.viewport.unprojectVector(positionToTransform);
    return game.camera.screenToWorld(afterViewport);
  }

  bool get handled {
    return state.handled;
  }

  set handled(bool value) {
    state.handled = value;
  }

  // State getters
  bool get isPointerAdded => state is PointerStateAdded;
  bool get wasPointerAdded => historyHas<PointerStateAdded>();
  bool get isPointerRemoved => state is PointerStateRemoved;
  bool get wasPointerRemoved => historyHas<PointerStateRemoved>();
  bool get isHovering => state is PointerStateHover;
  bool get wasHovering => historyHas<PointerStateHover>() || isHovering;
  bool get isDown => state is PointerStateDown;
  bool get wasDown => historyHas<PointerStateDown>() || isDown;
  bool get isLongDown => state is PointerStateLongDown;
  bool get wasLongDown => historyHas<PointerStateLongDown>() || isLongDown;
  bool get isDragStart => state is PointerStateDragStart;
  bool get wasDragStart => historyHas<PointerStateDragStart>() || isDragStart;
  bool get isDragUpdate => state is PointerStateDragUpdate;
  bool get wasDragUpdate =>
      historyHas<PointerStateDragUpdate>() || isDragUpdate;
  bool get isDragEnd => state is PointerStateDragEnd;
  bool get wasDragEnd => historyHas<PointerStateDragEnd>() || isDragEnd;
  bool get isUp => state is PointerStateUp;
  bool get wasUp => historyHas<PointerStateUp>() || isUp;
  bool get isCancelled => state is PointerStateCancelled;
  bool get wasCancelled => historyHas<PointerStateCancelled>() || isCancelled;
  bool get isTimeout => state is PointerStateTimeout;
  bool get wasTimeout => historyHas<PointerStateTimeout>() || isTimeout;

  // High-level state getters
  bool get isPressed => isDown || isLongDown || isDragStart || isDragUpdate;
  bool get wasPressed =>
      wasDown || wasLongDown || wasDragStart || wasDragUpdate;
  bool get isReleased => isUp || isCancelled || isDragEnd;
  bool get wasReleased =>
      wasUp || (wasCancelled && wasDragStart == false) || wasDragEnd;
}

/// Represents the current state of the pointer device.
class PointerState {
  final PointerEvent? rawPointerEvent;
  final DateTime timestamp = DateTime.now();

  Vector2? get position => rawPointerEvent?.position.toVector2();
  int? get pointerId => rawPointerEvent?.pointer;
  int? get deviceId => rawPointerEvent?.device;
  PointerDeviceKind? get kind => rawPointerEvent?.kind;

  // Handled
  bool handled = false;

  PointerState({this.rawPointerEvent});

  String get debugName => runtimeType.toString().replaceAll('PointerState', '');
}

class PointerStateDown extends PointerState {
  PointerStateDown(PointerDownEvent raw) : super(rawPointerEvent: raw);
  PointerDownEvent get raw => rawPointerEvent as PointerDownEvent;
}

class PointerStateLongDown extends PointerState {
  PointerStateLongDown(PointerDownEvent raw) : super(rawPointerEvent: raw);
  PointerDownEvent get raw => rawPointerEvent as PointerDownEvent;
}

class PointerStateUp extends PointerState {
  PointerStateUp(PointerUpEvent raw) : super(rawPointerEvent: raw);
  PointerUpEvent get raw => rawPointerEvent as PointerUpEvent;
}

class PointerStateCancelled extends PointerState {
  PointerStateCancelled(PointerCancelEvent raw) : super(rawPointerEvent: raw);
  PointerCancelEvent get raw => rawPointerEvent as PointerCancelEvent;
}

class PointerStateDragStart extends PointerState {
  PointerStateDragStart(PointerMoveEvent raw) : super(rawPointerEvent: raw);
  PointerMoveEvent get raw => rawPointerEvent as PointerMoveEvent;
}

class PointerStateDragUpdate extends PointerState {
  PointerStateDragUpdate(PointerMoveEvent raw) : super(rawPointerEvent: raw);
  PointerMoveEvent get raw => rawPointerEvent as PointerMoveEvent;
}

class PointerStateDragEnd extends PointerState {
  PointerStateDragEnd(PointerUpEvent raw) : super(rawPointerEvent: raw);
  PointerUpEvent get raw => rawPointerEvent as PointerUpEvent;
}

class PointerStateAdded extends PointerState {
  PointerStateAdded(PointerAddedEvent raw) : super(rawPointerEvent: raw);
  PointerAddedEvent get raw => rawPointerEvent as PointerAddedEvent;
}

class PointerStateHover extends PointerState {
  DateTime lastHoverTime = DateTime.now();
  PointerStateHover(PointerHoverEvent raw) : super(rawPointerEvent: raw);
  PointerHoverEvent get raw => rawPointerEvent as PointerHoverEvent;
}

class PointerStateRemoved extends PointerState {
  PointerStateRemoved(PointerRemovedEvent raw) : super(rawPointerEvent: raw);
  PointerRemovedEvent get raw => rawPointerEvent as PointerRemovedEvent;
}

class PointerStateTimeout extends PointerState {
  PointerStateTimeout();
}
