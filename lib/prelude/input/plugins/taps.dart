import 'package:backbone/filter.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:flame/extensions.dart';

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
  final query = realm.query(Has([TappableTrait, TransformTrait]));
  final queryLength = query.length;
  final input = realm.getResource<Input>();
  for (var i = 0; i < queryLength; i++) {
    final node = query.elementAt(i);
    final tappable = node.get<TappableTrait>();
    final transform = node.get<TransformTrait>();

    // Check tap starts
    final tapStarts = input.justTapDownPointers();
    for (var tapStart in tapStarts) {
      if (tappable.onTapDown != null) {
        if (transform.rect.containsPoint(tapStart.position)) {
          tappable.onTapDown!(tapStart);
        }
      }
    }

    // Check long tap starts
    final longTapStarts = input.justLongTapDownPointers();
    for (var longTapStart in longTapStarts) {
      if (tappable.onLongTapDown != null) {
        if (transform.rect.containsPoint(longTapStart.position)) {
          tappable.onLongTapDown!(longTapStart);
        }
      }
    }

    // Check tap ends
    final tapEnds = input.justTapUpPointers();
    for (var tapEnd in tapEnds) {
      if (tappable.onTapUp != null) {
        if (transform.rect.containsPoint(tapEnd.position)) {
          tappable.onTapUp!(tapEnd);
        }
      }
    }

    // Check tap cancels
    final tapCancels = input.justTapCancelPointers();
    for (var tapCancel in tapCancels) {
      if (tappable.onTapCancel != null) {
        if (transform.rect.containsPoint(tapCancel.position)) {
          tappable.onTapCancel!(tapCancel);
        }
      }
    }

    // Check just pressed
    final justPressed = input.justPressedPointers();
    for (var pressed in justPressed) {
      if (tappable.onJustPressed != null) {
        if (transform.rect.containsPoint(pressed.position)) {
          tappable.onJustPressed!(pressed);
        }
      }
    }

    // Check pressed
    final pressed = input.pressedPointers();
    for (var press in pressed) {
      if (tappable.onPressed != null) {
        if (transform.rect.containsPoint(press.position)) {
          tappable.onPressed!(press);
        }
      }
    }

    // Check just released
    final justReleased = input.justReleasedPointers();
    for (var released in justReleased) {
      if (tappable.onJustReleased != null) {
        if (transform.rect.containsPoint(released.position)) {
          tappable.onJustReleased!(released);
        }
      }
    }
  }
}
