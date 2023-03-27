import 'package:backbone/filter.dart';
import 'package:backbone/node.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/plugins/drag.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:flame/game.dart';

class TappableTrait<T extends FlameGame> extends ATrait<T> {
  // Basic
  final void Function(Pointer pointer)? onTapDown;
  final void Function(Pointer pointer)? onLongTapDown;
  final void Function(Pointer pointer)? onTapUp;
  final void Function(Pointer pointer)? onTapCancel;

  // High-level
  final void Function(Pointer pointer)? onJustPressed;
  final void Function(Pointer pointer)? onPressed;
  final void Function(Pointer pointer)? onJustReleased;

  TappableTrait(
      {this.onTapDown,
      this.onLongTapDown,
      this.onTapUp,
      this.onTapCancel,
      this.onJustPressed,
      this.onPressed,
      this.onJustReleased});
}

class TappableSystemResult<T extends FlameGame> {
  // Hits
  final List<CapturedTappableEvent<T>> tapStarts = [];
  final List<CapturedTappableEvent<T>> longTapStarts = [];
  final List<CapturedTappableEvent<T>> tapEnds = [];
  final List<CapturedTappableEvent<T>> tapCancels = [];
  final List<CapturedTappableEvent<T>> justPressed = [];
  final List<CapturedTappableEvent<T>> pressed = [];
  final List<CapturedTappableEvent<T>> justReleased = [];

  // Misses
  final List<Pointer> tapStartMisses = [];
  final List<Pointer> longTapStartMisses = [];
  final List<Pointer> tapEndMisses = [];
  final List<Pointer> tapCancelMisses = [];
  final List<Pointer> justPressedMisses = [];
  final List<Pointer> pressedMisses = [];
  final List<Pointer> justReleasedMisses = [];
}

class CapturedTappableEvent<T extends FlameGame> {
  final Pointer pointer;
  final ANode<T> node;
  final TappableTrait<T> trait;

  CapturedTappableEvent(this.pointer, this.node, this.trait);
}

TappableSystemResult tappableSystem<T extends FlameGame>(Realm<T> realm) {
  // Dependencies to maintain order
  realm.checkOrRunSystem(dragReceiverSystem);

  final query = realm.query(Has([TappableTrait<T>]));
  final result = TappableSystemResult<T>();

  final input = realm.getResource<Input>();
  final tapStarts = input.justTapDownPointers();
  final foundTapStarts = <CapturedTappableEvent<T>>[];
  final longTapStarts = input.justLongTapDownPointers();
  final foundLongTapStarts = <CapturedTappableEvent<T>>[];
  final tapEnds = input.justTapUpPointers();
  final foundTapEnds = <CapturedTappableEvent<T>>[];
  final tapCancels = input.justTapCancelPointers();
  final foundTapCancels = <CapturedTappableEvent<T>>[];
  final justPressed = input.justPressedPointers();
  final foundJustPressed = <CapturedTappableEvent<T>>[];
  final pressed = input.pressedPointers();
  final foundPressed = <CapturedTappableEvent<T>>[];
  final justReleased = input.justReleasedPointers();
  final foundJustReleased = <CapturedTappableEvent<T>>[];

  // Search for nodes matching the events
  for (final node in query) {
    final tappable = node.get<TappableTrait<T>>();

    // Check tap starts
    for (var tapStart in tapStarts) {
      bool found = false;
      if (node.containsPoint(tapStart.worldPosition(realm.gameRef))) {
        found = true;
        final event = CapturedTappableEvent<T>(tapStart, node, tappable);
        foundTapStarts.add(event);
      }
      if (found == false) {
        result.tapStartMisses.add(tapStart);
      }
    }

    // Check long tap starts
    for (var longTapStart in longTapStarts) {
      bool found = false;
      if (node.containsPoint(longTapStart.worldPosition(realm.gameRef))) {
        found = true;
        final event = CapturedTappableEvent(longTapStart, node, tappable);
        foundLongTapStarts.add(event);
      }
      if (found == false) {
        result.longTapStartMisses.add(longTapStart);
      }
    }

    // Check tap ends
    for (var tapEnd in tapEnds) {
      bool found = false;
      if (node.containsPoint(tapEnd.worldPosition(realm.gameRef))) {
        found = true;
        final event = CapturedTappableEvent(tapEnd, node, tappable);
        foundTapEnds.add(event);
      }
      if (found == false) {
        result.tapEndMisses.add(tapEnd);
      }
    }

    // Check tap cancels
    for (var tapCancel in tapCancels) {
      bool found = false;
      if (node.containsPoint(tapCancel.worldPosition(realm.gameRef))) {
        found = true;
        final event = CapturedTappableEvent(tapCancel, node, tappable);
        foundTapCancels.add(event);
      }
      if (found == false) {
        result.tapCancelMisses.add(tapCancel);
      }
    }

    // Check just pressed
    for (var pressed in justPressed) {
      bool found = false;
      if (node.containsPoint(pressed.worldPosition(realm.gameRef))) {
        found = true;
        final event = CapturedTappableEvent(pressed, node, tappable);
        foundJustPressed.add(event);
      }
      if (found == false) {
        result.justPressedMisses.add(pressed);
      }
    }

    // Check pressed
    for (var press in pressed) {
      bool found = false;
      if (node.containsPoint(press.worldPosition(realm.gameRef))) {
        found = true;
        final event = CapturedTappableEvent(press, node, tappable);
        foundPressed.add(event);
      }
      if (found == false) {
        result.pressedMisses.add(press);
      }
    }

    // Check just released
    for (var released in justReleased) {
      bool found = false;
      if (node.containsPoint(released.worldPosition(realm.gameRef))) {
        found = true;
        final event = CapturedTappableEvent(released, node, tappable);
        foundJustReleased.add(event);
      }
      if (found == false) {
        result.justReleasedMisses.add(released);
      }
    }
  }

  // Call the callbacks based on the node's priority
  final foundTapStartsSorted = (foundTapStarts.toList()
        ..sort((a, b) => a.node.compareToOnPriority(b.node)))
      .reversed;
  for (final found in foundTapStartsSorted) {
    found.trait.onTapDown?.call(found.pointer);
    result.tapStarts.add(found);
  }

  final foundLongTapStartsSorted = (foundLongTapStarts.toList()
        ..sort((a, b) => a.node.compareToOnPriority(b.node)))
      .reversed;
  for (final found in foundLongTapStartsSorted) {
    found.trait.onLongTapDown?.call(found.pointer);
    result.longTapStarts.add(found);
  }

  final foundTapEndsSorted = (foundTapEnds.toList()
        ..sort((a, b) => a.node.compareToOnPriority(b.node)))
      .reversed;
  for (final found in foundTapEndsSorted) {
    found.trait.onTapUp?.call(found.pointer);
    result.tapEnds.add(found);
  }

  final foundTapCancelsSorted = (foundTapCancels.toList()
        ..sort((a, b) => a.node.compareToOnPriority(b.node)))
      .reversed;
  for (final found in foundTapCancelsSorted) {
    found.trait.onTapCancel?.call(found.pointer);
    result.tapCancels.add(found);
  }

  final foundJustPressedSorted = (foundJustPressed.toList()
        ..sort((a, b) => a.node.compareToOnPriority(b.node)))
      .reversed;
  for (final found in foundJustPressedSorted) {
    found.trait.onJustPressed?.call(found.pointer);
    result.justPressed.add(found);
  }

  final foundPressedSorted = (foundPressed.toList()
        ..sort((a, b) => a.node.compareToOnPriority(b.node)))
      .reversed;
  for (final found in foundPressedSorted) {
    found.trait.onPressed?.call(found.pointer);
    result.pressed.add(found);
  }

  final foundJustReleasedSorted = (foundJustReleased.toList()
        ..sort((a, b) => a.node.compareToOnPriority(b.node)))
      .reversed;
  for (final found in foundJustReleasedSorted) {
    found.trait.onJustReleased?.call(found.pointer);
    result.justReleased.add(found);
  }

  // Remove pointers which hit a node
  // from the misses list
  for (final found in result.tapStarts) {
    result.tapStartMisses.removeWhere((p) => p == found.pointer);
  }
  for (final found in result.longTapStarts) {
    result.longTapStartMisses.removeWhere((p) => p == found.pointer);
  }
  for (final found in result.tapEnds) {
    result.tapEndMisses.removeWhere((p) => p == found.pointer);
  }
  for (final found in result.tapCancels) {
    result.tapCancelMisses.removeWhere((p) => p == found.pointer);
  }
  for (final found in result.justPressed) {
    result.justPressedMisses.removeWhere((p) => p == found.pointer);
  }
  for (final found in result.pressed) {
    result.pressedMisses.removeWhere((p) => p == found.pointer);
  }
  for (final found in result.justReleased) {
    result.justReleasedMisses.removeWhere((p) => p == found.pointer);
  }

  return result;
}
