// ignore_for_file: implementation_imports

import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flame/src/events/messages/position_event.dart';
import 'package:flame/src/events/messages/event.dart';

/// Wraps a pointer device doing something on the screen.
/// Includes convenience methods for accessing data like position, state, etc.
class Pointer {
  final int id;
  final Vector2 startPosition;
  final PointerDeviceKind kind;
  PointerState state;
  final List<PointerState> history = [];
  dynamic payload;

  Pointer(this.id, this.startPosition, this.kind, this.state);

  // Factory constructors from Flame events
  factory Pointer.fromTapDownEvent(int id, TapDownEvent raw) {
    return Pointer(
      id,
      raw.canvasPosition,
      raw.deviceKind,
      PointerStateDown(raw),
    );
  }
  factory Pointer.fromAddedEvent(int id, PointerAddedEvent raw) {
    return Pointer(
      id,
      raw.position.toVector2(),
      raw.kind,
      PointerStateAdded(raw),
    );
  }
  factory Pointer.fromHoverEvent(int id, PointerHoverEvent raw) {
    return Pointer(
      id,
      raw.position.toVector2(),
      raw.kind,
      PointerStateHover(raw),
    );
  }

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
            .position;
      } else {
        return startPosition;
      }
    } else if (state is PointerStateTimeout) {
      if (history.any((state) => state is PointerStateHover)) {
        return (history.lastWhere((state) => state is PointerStateHover)
                as PointerStateHover)
            .position;
      } else {
        return startPosition;
      }
    } else if (state is PointerStateCancelled) {
      return history[history.length - 1].position;
    } else {
      return state.position;
    }
  }

  Vector2 worldPosition(FlameGame game, {PointerState? fromState}) {
    final positionToTransform = fromState?.position ?? position;
    final afterViewport = game.camera.viewport.unprojectVector(position);
    return game.camera.screenToWorld(afterViewport);
  }

  /// Internal representation of a Flame or Flutter pointers.
  int get pointerId {
    if (state is PointerStateTimeout) {
      // Search for the last hover or pointer add event
      if (history.any((state) => state is PointerStateHover)) {
        return (history.lastWhere((state) => state is PointerStateHover)
                as PointerStateHover)
            .pointerId;
      } else if (history.any((state) => state is PointerStateAdded)) {
        return (history.lastWhere((state) => state is PointerStateAdded)
                as PointerStateAdded)
            .pointerId;
      } else {
        return id;
      }
    } else {
      return state.pointerId;
    }
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
  final Event? rawEvent;

  PositionEvent? get rawPositionEvent =>
      rawEvent != null && rawEvent is PositionEvent
          ? rawEvent as PositionEvent
          : null;
  Vector2 get position =>
      rawPointerEvent?.position.toVector2() ??
      rawPositionEvent?.canvasPosition ??
      Vector2.zero();
  int _pointerId = -1;
  int get pointerId => rawPointerEvent?.pointer ?? _pointerId;
  int get device => rawPointerEvent?.device ?? -1;

  // Handled
  bool _handled = false;
  bool get handled => rawEvent?.handled ?? _handled;
  set handled(bool value) {
    if (rawEvent != null) {
      rawEvent!.handled = value;
    } else {
      _handled = value;
    }
  }

  PointerState({this.rawPointerEvent, this.rawEvent, int? pointerId}) {
    if (pointerId != null) {
      _pointerId = pointerId;
    }
  }
}

class PointerStateDown extends PointerState {
  PointerStateDown(TapDownEvent raw)
      : super(rawEvent: raw, pointerId: raw.pointerId);
  TapDownEvent get raw => rawEvent as TapDownEvent;
}

class PointerStateLongDown extends PointerState {
  PointerStateLongDown(TapDownEvent raw)
      : super(rawEvent: raw, pointerId: raw.pointerId);
  TapDownEvent get raw => rawEvent as TapDownEvent;
}

class PointerStateUp extends PointerState {
  PointerStateUp(TapUpEvent raw)
      : super(rawEvent: raw, pointerId: raw.pointerId);
  TapUpEvent get raw => rawEvent as TapUpEvent;
}

class PointerStateCancelled extends PointerState {
  PointerStateCancelled(TapCancelEvent raw)
      : super(rawEvent: raw, pointerId: raw.pointerId);
  TapCancelEvent get raw => rawEvent as TapCancelEvent;
}

class PointerStateDragStart extends PointerState {
  PointerStateDragStart(DragStartEvent raw)
      : super(rawEvent: raw, pointerId: raw.pointerId);
  DragStartEvent get raw => rawEvent as DragStartEvent;
}

class PointerStateDragUpdate extends PointerState {
  PointerStateDragUpdate(DragUpdateEvent raw)
      : super(rawEvent: raw, pointerId: raw.pointerId);
  DragUpdateEvent get raw => rawEvent as DragUpdateEvent;
}

class PointerStateDragEnd extends PointerState {
  PointerStateDragEnd(DragEndEvent raw)
      : super(rawEvent: raw, pointerId: raw.pointerId);
  DragEndEvent get raw => rawEvent as DragEndEvent;
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
