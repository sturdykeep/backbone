import 'package:backbone/filter.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:flame/extensions.dart';

class HoverableTrait extends ATrait {
  final void Function(Pointer pointer)? onHoverEnter;
  final void Function(Pointer pointer)? onHoverExit;
  final void Function(Pointer pointer)? onHoverMove;

  Set<Pointer> pointers = {};

  HoverableTrait({this.onHoverEnter, this.onHoverExit, this.onHoverMove});
}

void hoverableSystem(Realm realm) {
  final query = realm.query(Has([HoverableTrait, TransformTrait]));
  final queryLength = query.length;
  final input = realm.getResource<Input>();
  for (var i = 0; i < queryLength; i++) {
    final node = query.elementAt(i);
    final hoverable = node.get<HoverableTrait>();
    final transform = node.get<TransformTrait>();

    // Check hovers
    final hovers = input.justHoverPointers();
    for (var hover in hovers) {
      if (transform.rect.containsPoint(hover.position)) {
        if (hoverable.pointers.contains(hover) == false) {
          hoverable.pointers.add(hover);
          if (hoverable.onHoverEnter != null) {
            hoverable.onHoverEnter!(hover);
          }
        } else {
          if (hoverable.onHoverMove != null) {
            hoverable.onHoverMove!(hover);
          }
        }
      } else {
        if (hoverable.pointers.contains(hover)) {
          hoverable.pointers.remove(hover);
          if (hoverable.onHoverExit != null) {
            hoverable.onHoverExit!(hover);
          }
        }
      }
    }

    // Check entered pointers that are no longer hovering
    final exitedPointers = hoverable.pointers
        .where((pointer) => pointer.isHovering == false)
        .toList();
    for (var exitedPointer in exitedPointers) {
      hoverable.pointers.remove(exitedPointer);
      if (hoverable.onHoverExit != null) {
        hoverable.onHoverExit!(exitedPointer);
      }
    }
  }
}
