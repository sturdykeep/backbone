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
  final hoverEnters = input.justHoverEnterPointers();
  final hovers = input.justHoverPointers();
  final hoverLeaves = input.justHoverLeavePointers();
  final pendingHovers = input.pendingHoverPointers();
  for (var i = 0; i < queryLength; i++) {
    final node = query.elementAt(i);
    final hoverable = node.get<HoverableTrait>();
    final transform = node.get<TransformTrait>();

    // Check hover enters
    for (var hoverEnter in hoverEnters) {
      if (transform.rect.containsPoint(hoverEnter.position)) {
        hoverable.pointers.add(hoverEnter);
        hoverable.onHoverEnter?.call(hoverEnter);
      }
    }

    // Check hover moves which aren't in the pointer list
    for (var hover in hovers) {
      if (transform.rect.containsPoint(hover.position) &&
          hoverable.pointers.contains(hover) == false) {
        hoverable.pointers.add(hover);
        hoverable.onHoverEnter?.call(hover);
      }
    }

    // Check hover leaves
    for (var hoverLeave in hoverLeaves) {
      if (hoverable.pointers.contains(hoverLeave)) {
        hoverable.pointers.remove(hoverLeave);
        hoverable.onHoverExit?.call(hoverLeave);
      }
    }

    // Check the entered pointer list
    // 1. Check if the pointer is still in the rect and has hover move state
    // 2. Check if the pointer not being in the hover mode anymore
    final pointers = hoverable.pointers.toList();
    for (var pointer in pointers) {
      if (transform.rect.containsPoint(pointer.position) &&
          (pointer.isPointerAdded || pointer.isHovering)) {
        hoverable.onHoverMove?.call(pointer);
      } else {
        hoverable.pointers.remove(pointer);
        hoverable.onHoverExit?.call(pointer);
      }
    }

    // Check pending hovers for pointers not yet in the list
    for (var pendingHover in pendingHovers) {
      if (transform.rect.containsPoint(pendingHover.position) &&
          hoverable.pointers.contains(pendingHover) == false) {
        hoverable.pointers.add(pendingHover);
        hoverable.onHoverEnter?.call(pendingHover);
      }
    }
  }
}
