import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/gestures.dart';

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
    if (state is PointerStateAdded) {
      return (state as PointerStateAdded).raw.position.toVector2();
    } else if (state is PointerStateHover) {
      return (state as PointerStateHover).raw.position.toVector2();
    } else if (state is PointerStateRemoved) {
      return (state as PointerStateRemoved).raw.position.toVector2();
    } else if (state is PointerStateDown) {
      return (state as PointerStateDown).raw.canvasPosition;
    } else if (state is PointerStateLongDown) {
      return (state as PointerStateLongDown).raw.canvasPosition;
    } else if (state is PointerStateDragStart) {
      return (state as PointerStateDragStart).raw.canvasPosition;
    } else if (state is PointerStateUp) {
      return (state as PointerStateUp).raw.canvasPosition;
    } else if (state is PointerStateCancelled) {
      return historyGet<PointerStateDown>().raw.canvasPosition;
    } else if (state is PointerStateDragUpdate) {
      return (state as PointerStateDragUpdate).raw.canvasPosition;
    } else if (state is PointerStateDragEnd) {
      if (history.any((state) => state is PointerStateDragUpdate)) {
        return (history.lastWhere((state) => state is PointerStateDragUpdate)
                as PointerStateDragUpdate)
            .raw
            .canvasPosition;
      } else {
        return startPosition;
      }
    } else {
      return startPosition;
    }
  }

  /// Internal representation of a concrete device (Hover) or its interaction (Taps, Drags).
  int get device {
    if (state is PointerStateAdded) {
      return (state as PointerStateAdded).raw.device;
    } else if (state is PointerStateRemoved) {
      return (state as PointerStateRemoved).raw.device;
    } else if (state is PointerStateHover) {
      return (state as PointerStateHover).raw.device;
    } else if (state is PointerStateDown) {
      return (state as PointerStateDown).raw.pointerId;
    } else if (state is PointerStateLongDown) {
      return (state as PointerStateLongDown).raw.pointerId;
    } else if (state is PointerStateDragStart) {
      return (state as PointerStateDragStart).raw.pointerId;
    } else if (state is PointerStateDragUpdate) {
      return (state as PointerStateDragUpdate).raw.pointerId;
    } else if (state is PointerStateDragEnd) {
      return (state as PointerStateDragEnd).raw.pointerId;
    } else if (state is PointerStateUp) {
      return (state as PointerStateUp).raw.pointerId;
    } else if (state is PointerStateCancelled) {
      return (state as PointerStateCancelled).raw.pointerId;
    } else {
      return -1;
    }
  }

  bool get handled {
    if (state is PointerStateAdded) {
      return (state as PointerStateAdded).handled;
    } else if (state is PointerStateRemoved) {
      return (state as PointerStateRemoved).handled;
    } else if (state is PointerStateHover) {
      return (state as PointerStateHover).handled;
    } else if (state is PointerStateDown) {
      return (state as PointerStateDown).raw.handled;
    } else if (state is PointerStateLongDown) {
      return (state as PointerStateLongDown).raw.handled;
    } else if (state is PointerStateDragStart) {
      return (state as PointerStateDragStart).raw.handled;
    } else if (state is PointerStateDragUpdate) {
      return (state as PointerStateDragUpdate).raw.handled;
    } else if (state is PointerStateDragEnd) {
      return (state as PointerStateDragEnd).raw.handled;
    } else if (state is PointerStateUp) {
      return (state as PointerStateUp).raw.handled;
    } else if (state is PointerStateCancelled) {
      return (state as PointerStateCancelled).raw.handled;
    } else {
      return false;
    }
  }

  set handled(bool value) {
    if (state is PointerStateAdded) {
      (state as PointerStateAdded).handled = value;
    } else if (state is PointerStateRemoved) {
      (state as PointerStateRemoved).handled = value;
    } else if (state is PointerStateHover) {
      (state as PointerStateHover).handled = value;
    } else if (state is PointerStateDown) {
      (state as PointerStateDown).raw.handled = value;
    } else if (state is PointerStateLongDown) {
      (state as PointerStateLongDown).raw.handled = value;
    } else if (state is PointerStateDragStart) {
      (state as PointerStateDragStart).raw.handled = value;
    } else if (state is PointerStateDragUpdate) {
      (state as PointerStateDragUpdate).raw.handled = value;
    } else if (state is PointerStateDragEnd) {
      (state as PointerStateDragEnd).raw.handled = value;
    } else if (state is PointerStateUp) {
      (state as PointerStateUp).raw.handled = value;
    } else if (state is PointerStateCancelled) {
      (state as PointerStateCancelled).raw.handled = value;
    }
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

  // High-level state getters
  bool get isPressed => isDown || isLongDown || isDragStart || isDragUpdate;
  bool get wasPressed =>
      wasDown || wasLongDown || wasDragStart || wasDragUpdate;
  bool get isReleased => isUp || isCancelled || isDragEnd;
  bool get wasReleased =>
      wasUp || (wasCancelled && wasDragStart == false) || wasDragEnd;
}

/// Represents the current state of the pointer device.
class PointerState {}

class PointerStateDown extends PointerState {
  final TapDownEvent raw;

  PointerStateDown(this.raw);
}

class PointerStateLongDown extends PointerState {
  final TapDownEvent raw;

  PointerStateLongDown(this.raw);
}

class PointerStateUp extends PointerState {
  final TapUpEvent raw;

  PointerStateUp(this.raw);
}

class PointerStateCancelled extends PointerState {
  final TapCancelEvent raw;

  PointerStateCancelled(this.raw);
}

class PointerStateDragStart extends PointerState {
  final DragStartEvent raw;

  PointerStateDragStart(this.raw);
}

class PointerStateDragUpdate extends PointerState {
  final DragUpdateEvent raw;

  PointerStateDragUpdate(this.raw);
}

class PointerStateDragEnd extends PointerState {
  final DragEndEvent raw;

  PointerStateDragEnd(this.raw);
}

class PointerStateAdded extends PointerState {
  final PointerAddedEvent raw;
  bool handled = false;

  PointerStateAdded(this.raw);
}

class PointerStateHover extends PointerState {
  final PointerHoverEvent raw;
  bool handled = false;

  PointerStateHover(this.raw);
}

class PointerStateRemoved extends PointerState {
  final PointerRemovedEvent raw;
  bool handled = false;

  PointerStateRemoved(this.raw);
}
