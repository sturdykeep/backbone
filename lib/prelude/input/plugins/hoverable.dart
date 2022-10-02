import 'package:backbone/filter.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';

class HoverableTrait extends ATrait {
  final void Function(Pointer pointer)? onHoverEnter;
  final void Function(Pointer pointer)? onHoverExit;
  final void Function(Pointer pointer)? onHoverMove;

  Set<Pointer> pointers = {};

  HoverableTrait({this.onHoverEnter, this.onHoverExit, this.onHoverMove});
}

void hoverableSystem(Realm realm) {
  final query = realm.query(Has([HoverableTrait]));
  final queryLength = query.length;
  final input = realm.getResource<Input>();
  final hoverEnters = input.justHoverEnterPointers();
  final hovers = input.justHoverPointers();
  final hoverLeaves = input.justHoverLeavePointers();
  final pendingHovers = input.pendingHoverPointers();
  for (var i = 0; i < queryLength; i++) {
    final node = query.elementAt(i);
    final hoverable = node.get<HoverableTrait>();

    // Check hover enters
    for (var hoverEnter in hoverEnters) {
      if (node.containsPoint(hoverEnter.worldPosition(realm.gameRef))) {
        hoverable.pointers.add(hoverEnter);
        hoverable.onHoverEnter?.call(hoverEnter);
      }
    }

    // Check hover moves which aren't in the pointer list
    for (var hover in hovers) {
      if (node.containsPoint(hover.worldPosition(realm.gameRef)) &&
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
      if (node.containsPoint(pointer.worldPosition(realm.gameRef)) &&
          (pointer.isPointerAdded || pointer.isHovering)) {
        hoverable.onHoverMove?.call(pointer);
      } else {
        hoverable.pointers.remove(pointer);
        hoverable.onHoverExit?.call(pointer);
      }
    }

    // Check pending hovers for pointers not yet in the list
    for (var pendingHover in pendingHovers) {
      if (node.containsPoint(pendingHover.worldPosition(realm.gameRef)) &&
          hoverable.pointers.contains(pendingHover) == false) {
        hoverable.pointers.add(pendingHover);
        hoverable.onHoverEnter?.call(pendingHover);
      }
    }
  }
}
