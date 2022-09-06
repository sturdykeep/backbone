import 'package:flame/experimental.dart' as experimental;
import 'package:flame/input.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// Resource which contains all the input data for the current frame.
class Input {
  Set<LogicalKeyboardKey> keysPressed = {};
  PointerHoverInfo? pointerHover;
  Vector2 pointerPosition = Vector2.zero();

  // Taps
  List<experimental.TapDownEvent> taps = [];
  List<experimental.TapDownEvent> longTaps = [];
  List<experimental.TapUpEvent> tapUps = [];
  List<experimental.TapCancelEvent> tapCancels = [];

  // Drag
  List<experimental.DragStartEvent> dragStarts = [];
  List<experimental.DragUpdateEvent> dragUpdates = [];
  List<experimental.DragEndEvent> dragEnds = [];

  // Representations
  Map<int, TapInteraction> tapInteractions = {};
  Map<int, DragInteraction> dragInteractions = {};

  /// Get the taps and long taps which started this frame
  List<TapInteraction> newTaps() {
    final result = <TapInteraction>[];
    for (final tap in taps) {
      if (tapInteractions.containsKey(tap.pointerId)) {
        result.add(tapInteractions[tap.pointerId]!);
      }
    }
    for (final longTap in longTaps) {
      if (tapInteractions.containsKey(longTap.pointerId)) {
        result.add(tapInteractions[longTap.pointerId]!);
      }
    }
    return result;
  }

  /// Get the taps and long taps which ended this frame
  List<TapInteraction> newTapUps() {
    final result = <TapInteraction>[];
    for (final tapUp in tapUps) {
      if (tapInteractions.containsKey(tapUp.pointerId)) {
        result.add(tapInteractions[tapUp.pointerId]!);
      }
    }
    return result;
  }

  /// Get the taps and long taps which were cancelled this frame
  List<TapInteraction> newTapCancels() {
    final result = <TapInteraction>[];
    for (final tapCancel in tapCancels) {
      if (tapInteractions.containsKey(tapCancel.pointerId)) {
        result.add(tapInteractions[tapCancel.pointerId]!);
      }
    }
    return result;
  }

  /// Get the drags which started this frame
  List<DragInteraction> newDragStarts() {
    final result = <DragInteraction>[];
    for (final dragStart in dragStarts) {
      if (dragInteractions.containsKey(dragStart.pointerId)) {
        result.add(dragInteractions[dragStart.pointerId]!);
      }
    }
    return result;
  }

  /// Get the drags which updated this frame
  List<DragInteraction> newDragUpdates() {
    final result = <DragInteraction>[];
    for (final dragUpdate in dragUpdates) {
      if (dragInteractions.containsKey(dragUpdate.pointerId)) {
        result.add(dragInteractions[dragUpdate.pointerId]!);
      }
    }
    return result;
  }

  /// Get the drags which ended this frame
  List<DragInteraction> newDragEnds() {
    final result = <DragInteraction>[];
    for (final dragEnd in dragEnds) {
      if (dragInteractions.containsKey(dragEnd.pointerId)) {
        result.add(dragInteractions[dragEnd.pointerId]!);
      }
    }
    return result;
  }

  void clear() {
    keysPressed = {};
    taps = [];
    longTaps = [];
    tapUps = [];
    tapCancels = [];
    dragStarts = [];
    dragUpdates = [];
    dragEnds = [];
  }

  void process(double dt) {
    // Set last frame position for drags
    for (final interaction in dragInteractions.values) {
      interaction.positionAtLastFrame = interaction.position;
    }

    // Use the events from this frame to update the pointer interactions
    // -- normal taps
    for (final tap in taps) {
      assert(tapInteractions.containsKey(tap.pointerId) == false,
          'Pointer ID ${tap.pointerId} already exists');

      tapInteractions[tap.pointerId] = TapInteraction(
        tapDown: tap,
        long: false,
      );
    }
    // -- long taps
    for (final longTap in longTaps) {
      assert(tapInteractions.containsKey(longTap.pointerId) == false,
          'Pointer ID ${longTap.pointerId} already exists');

      tapInteractions[longTap.pointerId] = TapInteraction(
        tapDown: longTap,
        long: true,
      );
    }
    // -- tap ups
    for (final tapUp in tapUps) {
      assert(tapInteractions.containsKey(tapUp.pointerId),
          'Pointer ID ${tapUp.pointerId} does not exist');

      final interaction = tapInteractions[tapUp.pointerId]!;
      interaction.tapUp = tapUp;
    }
    // -- tap cancels
    for (final tapCancel in tapCancels) {
      assert(tapInteractions.containsKey(tapCancel.pointerId),
          'Pointer ID ${tapCancel.pointerId} does not exist');

      final interaction = tapInteractions[tapCancel.pointerId]!;
      interaction.tapCancel = tapCancel;
    }
    // -- drag starts
    for (final dragStart in dragStarts) {
      assert(dragInteractions.containsKey(dragStart.pointerId) == false,
          'Pointer ID ${dragStart.pointerId} already exists');

      dragInteractions[dragStart.pointerId] = DragInteraction(
        dragStart: dragStart,
      );
    }
    // -- drag updates
    for (final dragUpdate in dragUpdates) {
      assert(dragInteractions.containsKey(dragUpdate.pointerId),
          'Pointer ID ${dragUpdate.pointerId} does not exist');

      final interaction = dragInteractions[dragUpdate.pointerId]!;
      interaction.dragUpdates.add(dragUpdate);
    }
    // -- drag ends
    for (final dragEnd in dragEnds) {
      assert(dragInteractions.containsKey(dragEnd.pointerId),
          'Pointer ID ${dragEnd.pointerId} does not exist');

      final interaction = dragInteractions[dragEnd.pointerId]!;
      interaction.dragEnd = dragEnd;
    }
  }
}

class TapInteraction {
  final bool long;
  final experimental.TapDownEvent tapDown;
  experimental.TapUpEvent? tapUp;
  experimental.TapCancelEvent? tapCancel;

  TapInteraction({required this.tapDown, required this.long});

  // Shortcuts
  Vector2 get position => tapDown.canvasPosition;
  Vector2? get endPosition => tapUp?.canvasPosition;
  int get pointerId => tapDown.pointerId;
  PointerDeviceKind get deviceKind => tapDown.deviceKind;
  bool get finished => tapUp != null || tapCancel != null;
  bool get cancelled => tapCancel != null;
}

class DragInteraction {
  final experimental.DragStartEvent dragStart;
  List<experimental.DragUpdateEvent> dragUpdates = [];
  experimental.DragEndEvent? dragEnd;
  late Vector2 positionAtLastFrame;

  DragInteraction({required this.dragStart}) {
    positionAtLastFrame = dragStart.canvasPosition;
  }

  // Shortcuts
  Vector2 get startPosition => dragStart.canvasPosition;
  Vector2 get position =>
      dragUpdates.isNotEmpty ? dragUpdates.last.canvasPosition : startPosition;
  Vector2? get endPosition => dragEnd != null ? position : null;
  int get pointerId => dragStart.pointerId;
  PointerDeviceKind get deviceKind => dragStart.deviceKind;
  bool get finished => dragEnd != null;
  Vector2 get frameDelta => position - positionAtLastFrame;
}
