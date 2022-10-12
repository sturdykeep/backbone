import 'package:backbone/filter.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';

class TappableTrait extends ATrait {
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

void tappableSystem(Realm realm) {
  final query = realm.query(Has([TappableTrait]));
  final queryLength = query.length;
  final input = realm.getResource<Input>();
  final tapStarts = input.justTapDownPointers();
  final foundTapStarts = [];
  final longTapStarts = input.justLongTapDownPointers();
  final foundLongTapStarts = [];
  final tapEnds = input.justTapUpPointers();
  final foundTapEnds = [];
  final tapCancels = input.justTapCancelPointers();
  final foundTapCancels = [];
  final justPressed = input.justPressedPointers();
  final foundJustPressed = [];
  final pressed = input.pressedPointers();
  final foundPressed = [];
  final justReleased = input.justReleasedPointers();
  final foundJustReleased = [];

  // Search for nodes matching the events
  for (var i = 0; i < queryLength; i++) {
    final node = query.elementAt(i);
    final tappable = node.get<TappableTrait>();

    // Check tap starts
    for (var tapStart in tapStarts) {
      if (tappable.onTapDown != null) {
        if (node.containsPoint(tapStart.worldPosition(realm.gameRef))) {
          foundTapStarts.add({
            'node': node,
            'tappable': tappable,
            'pointer': tapStart,
          });
        }
      }
    }

    // Check long tap starts
    for (var longTapStart in longTapStarts) {
      if (tappable.onLongTapDown != null) {
        if (node.containsPoint(longTapStart.worldPosition(realm.gameRef))) {
          foundLongTapStarts.add({
            'node': node,
            'tappable': tappable,
            'pointer': longTapStart,
          });
        }
      }
    }

    // Check tap ends
    for (var tapEnd in tapEnds) {
      if (tappable.onTapUp != null) {
        if (node.containsPoint(tapEnd.worldPosition(realm.gameRef))) {
          foundTapEnds.add({
            'node': node,
            'tappable': tappable,
            'pointer': tapEnd,
          });
        }
      }
    }

    // Check tap cancels
    for (var tapCancel in tapCancels) {
      if (tappable.onTapCancel != null) {
        if (node.containsPoint(tapCancel.worldPosition(realm.gameRef))) {
          foundTapCancels.add({
            'node': node,
            'tappable': tappable,
            'pointer': tapCancel,
          });
        }
      }
    }

    // Check just pressed
    for (var pressed in justPressed) {
      if (tappable.onJustPressed != null) {
        if (node.containsPoint(pressed.worldPosition(realm.gameRef))) {
          foundJustPressed.add({
            'node': node,
            'tappable': tappable,
            'pointer': pressed,
          });
        }
      }
    }

    // Check pressed
    for (var press in pressed) {
      if (tappable.onPressed != null) {
        if (node.containsPoint(press.worldPosition(realm.gameRef))) {
          foundPressed.add({
            'node': node,
            'tappable': tappable,
            'pointer': press,
          });
        }
      }
    }

    // Check just released
    for (var released in justReleased) {
      if (tappable.onJustReleased != null) {
        if (node.containsPoint(released.worldPosition(realm.gameRef))) {
          foundJustReleased.add({
            'node': node,
            'tappable': tappable,
            'pointer': released,
          });
        }
      }
    }
  }

  // Call the callbacks based on the node's priority
  final foundTapStartsLength = foundTapStarts.length;
  final foundTapStartsSorted = (foundTapStarts.toList()
        ..sort((a, b) => a["node"].compareToOnPriority(b["node"])))
      .reversed;
  for (var i = 0; i < foundTapStartsLength; i++) {
    final found = foundTapStartsSorted.elementAt(i);
    found["tappable"].onTapDown!(found["pointer"]);
  }

  final foundLongTapStartsLength = foundLongTapStarts.length;
  final foundLongTapStartsSorted = (foundLongTapStarts.toList()
        ..sort((a, b) => a["node"].compareToOnPriority(b["node"])))
      .reversed;
  for (var i = 0; i < foundLongTapStartsLength; i++) {
    final found = foundLongTapStartsSorted.elementAt(i);
    found["tappable"].onLongTapDown!(found["pointer"]);
  }

  final foundTapEndsLength = foundTapEnds.length;
  final foundTapEndsSorted = (foundTapEnds.toList()
        ..sort((a, b) => a["node"].compareToOnPriority(b["node"])))
      .reversed;
  for (var i = 0; i < foundTapEndsLength; i++) {
    final found = foundTapEndsSorted.elementAt(i);
    found["tappable"].onTapUp!(found["pointer"]);
  }

  final foundTapCancelsLength = foundTapCancels.length;
  final foundTapCancelsSorted = (foundTapCancels.toList()
        ..sort((a, b) => a["node"].compareToOnPriority(b["node"])))
      .reversed;
  for (var i = 0; i < foundTapCancelsLength; i++) {
    final found = foundTapCancelsSorted.elementAt(i);
    found["tappable"].onTapCancel!(found["pointer"]);
  }

  final foundJustPressedLength = foundJustPressed.length;
  final foundJustPressedSorted = (foundJustPressed.toList()
        ..sort((a, b) => a["node"].compareToOnPriority(b["node"])))
      .reversed;
  for (var i = 0; i < foundJustPressedLength; i++) {
    final found = foundJustPressedSorted.elementAt(i);
    found["tappable"].onJustPressed!(found["pointer"]);
  }

  final foundPressedLength = foundPressed.length;
  final foundPressedSorted = (foundPressed.toList()
        ..sort((a, b) => a["node"].compareToOnPriority(b["node"])))
      .reversed;
  for (var i = 0; i < foundPressedLength; i++) {
    final found = foundPressedSorted.elementAt(i);
    found["tappable"].onPressed!(found["pointer"]);
  }

  final foundJustReleasedLength = foundJustReleased.length;
  final foundJustReleasedSorted = (foundJustReleased.toList()
        ..sort((a, b) => a["node"].compareToOnPriority(b["node"])))
      .reversed;
  for (var i = 0; i < foundJustReleasedLength; i++) {
    final found = foundJustReleasedSorted.elementAt(i);
    found["tappable"].onJustReleased!(found["pointer"]);
  }
}
